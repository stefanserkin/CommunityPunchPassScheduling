public with sharing class StaffAvailabilityWrapperService {

    private static final integer APPOINTMENT_INTERVAL_IN_MINUTES = 30;
    private static Datetime roundedCurrentTime;

    /**********************************
     * Returns wrapper with staff id, name, and availability slots
     * @param TREX1__Staff__c staff record
     * @param Decimal length of individual appointments in minutes
     * @return StaffAvailabilityWrapper custom wrapper with availability slots
     ***********************************/

    public static List<StaffAvailabilityWrapper> getWrappersFromStaff(
        TREX1__Staff__c staff, 
        Integer appointmentLength
    ) {
        Map<Date, StaffAvailabilityWrapper> mapDateToWrapper = new Map<Date, StaffAvailabilityWrapper>();

        // Set min boundary for earliest booking based on current time
        setRoundedCurrentTime();

        Map<Date, List<Appointment__c>> mapDateToAppts;
        mapDateToAppts = new Map<Date, List<Appointment__c>>();
        if (!staff.Appointments__r.isEmpty()) {
            mapDateToAppts = getMapOfDailyAppts(
                staff
            );
        }

        addSlotsToWrapper(
            mapDateToWrapper, 
            staff.Staff_Availability_Schedules__r, 
            mapDateToAppts, 
            staff, 
            appointmentLength
        );
        
        return mapDateToWrapper.values();
    }


    /**********************************
     * Returns map of appointments by date, used to sort conflicts with availability
     * @param TREX1__Staff__c staff record
     * @return Map<Date,List<Appointment__c>> map of appointments by date
     ***********************************/

    private static Map<Date, List<Appointment__c>> getMapOfDailyAppts(
        TREX1__Staff__c staff
    ) {
        Map<Date, List<Appointment__c>> mapDateToAppts;
        mapDateToAppts = new Map<Date, List<Appointment__c>>();

        Date previousApptDate;

        List<Appointment__c> lstDailyAppts = new List<Appointment__c>();

        for (Appointment__c appt : staff.Appointments__r) {
            Date startDate = Date.valueOf(appt.Start_DateTime__c );
            if ( mapDateToAppts.containsKey( startDate )) {
                mapDateToAppts.get(startDate).add(appt);
            } else {
                mapDateToAppts.put(
                    startDate, 
                    new List<Appointment__c>{ appt }
                );
            }
        }

        return mapDateToAppts;
    }


    /**********************************
     * Loops through availability schedules and adds available
     *   slots to wrapper
     * @param StaffAvailabilityWrapper wrapper object
     * @param List<Staff_Availability_Schedule__c> list of availability schedules for this staff member
     * @param Map<Date,List<Appointment__c>> map of booked appts for this date
     * @param Decimal length of individual appointments in minutes
     * @return StaffAvailabilityWrapper custom wrapper with availability slots
     ***********************************/

    private static void addSlotsToWrapper(
        Map<Date, StaffAvailabilityWrapper> mapDateToWrapper, 
        List<Staff_Availability_Schedule__c> lstSchedules, 
        Map<Date, List<Appointment__c>> mapDateToAppts, 
        TREX1__Staff__c staff, 
        Integer appointmentLength
    ) {

        for (Staff_Availability_Schedule__c sas : lstSchedules) {

            if (!mapDateToWrapper.containsKey(sas.Date_Only__c)) {
                // Create wrapper with staff details to return
                StaffAvailabilityWrapper staffWrapper = new StaffAvailabilityWrapper();
                staffWrapper.staffId = staff.Id;
                staffWrapper.staffName = staff.Name;
                staffWrapper.availabilityDate = sas.Date_Only__c;

                // Create new list of inner class
                staffWrapper.availabilitySlots = new List<StaffAvailabilityWrapper.AvailabilitySlot>();

                // Add to map
                mapDateToWrapper.put(
                    staffWrapper.availabilityDate, 
                    staffWrapper
                );
            }

            // Establish min/max for the daily schedule
            Datetime dtScheduleStart = sas.Start_DateTime__c;
            System.debug('dtScheduleStart: ' + dtScheduleStart);
            System.debug('roundedCurrentTime: ' + roundedCurrentTime);
            dtScheduleStart = dtScheduleStart <= roundedCurrentTime ?
                roundedCurrentTime :
                dtScheduleStart
            ;
            System.debug('dtScheduleStart: ' + dtScheduleStart);
            Datetime dtScheduleEnd = sas.End_DateTime__c;
            
            // No need to evaluate if current time is later than end date of today's avaiability
            if (dtScheduleStart > dtScheduleEnd) {
                continue;
            }

            // Use map of daily appointments to check for full availability
            List<Appointment__c> lstDailyAppts = new List<Appointment__c>();
            if (mapDateToAppts.containsKey(sas.Date_Only__c)) {
                lstDailyAppts = mapDateToAppts.get(sas.Date_Only__c);
            }

            // Initialize next start time with start of day availability
            Datetime dtNextStartTime = dtScheduleStart;
            Datetime dtNextEndTime  = dtScheduleStart.addMinutes(appointmentLength);
            
            // If there are appointments, add each appointment-length slot of availability
            for (Appointment__c appt : lstDailyAppts) {
                while (
                    dtNextEndTime <= appt.Start_DateTime__c && 
                    dtNextEndTime <= dtScheduleEnd
                ) {
                    mapDateToWrapper.get(sas.Date_Only__c).availabilitySlots.add( 
                        getSlotFromRange(
                            dtNextStartTime, 
                            dtNextEndTime
                        )
                    );
                    dtNextStartTime = dtNextStartTime.addMinutes( APPOINTMENT_INTERVAL_IN_MINUTES );
                    dtNextEndTime = dtNextStartTime.addMinutes( appointmentLength );
                }
                dtNextStartTime = appt.End_DateTime__c;
                dtNextEndTime = dtNextStartTime.addMinutes( appointmentLength );
            }

            // Get availability slots for rest of day
            while (dtNextEndTime <= dtScheduleEnd) {
                mapDateToWrapper.get(sas.Date_Only__c).availabilitySlots.add( 
                    getSlotFromRange(
                        dtNextStartTime, 
                        dtNextEndTime
                    )
                );
                dtNextStartTime = dtNextStartTime.addMinutes( APPOINTMENT_INTERVAL_IN_MINUTES );
                dtNextEndTime = dtNextStartTime.addMinutes( appointmentLength );
            }

        }
    }


    /**********************************
     * Get slot object from start and end times
     * @param Datetime start time
     * @param Datetime end time
     * @return StaffAvailabilityWrapper.AvailabilitySlot individual availability slot 
     ***********************************/

    private static StaffAvailabilityWrapper.AvailabilitySlot getSlotFromRange(
        Datetime dtStartTime,
        Datetime dtEndTime
    ) {
        StaffAvailabilityWrapper.AvailabilitySlot slot;
        slot = new StaffAvailabilityWrapper.AvailabilitySlot();
        slot.startTime = dtStartTime;
        slot.endTime = dtEndTime;
        return slot;
    }


    /**********************************
     * Set static variable to next half hour (0 or 30 minutes)
     ***********************************/

    private static void setRoundedCurrentTime() {
        Integer minute = System.now().minute() < 30 ? 30 : 0;
        Integer hour = System.now().minute() < 30 ? System.now().hour() : System.now().hour() + 1;
        roundedCurrentTime = Datetime.newInstance(
            System.now().year(), 
            System.now().month(), 
            System.now().day(), 
            hour, 
            minute, 
            0
        );
    }

}