public with sharing class StaffAvailabilityWrapperService {

    private static Integer appointmentIntervalInMinutes;
    private static Integer appointmentLength;
    private static Integer minimumDaysBetweenAppointments;
    private static Integer maxMonthlyAppointments;
    private static Integer requiredHoursNotice;
    private static Datetime roundedCurrentTime;
    private static Set<String> maxedOutMonths;
    
    @testVisible private static TREX1__Membership__c punchPass;
    @testVisible private static List<Appointment__c> lstExistingAppointments;

    /**********************************
     * Returns wrapper with staff id, name, and availability slots
     * @param TREX1__Staff__c staff record
     * @param Decimal length of individual appointments in minutes
     * @return StaffAvailabilityWrapper custom wrapper with availability slots
     ***********************************/

    public static List<StaffAvailabilityWrapper> getWrappersFromStaff(
        TREX1__Staff__c staff, 
        TREX1__Membership__c passedPunchPass
    ) {
        Map<Date, StaffAvailabilityWrapper> mapDateToWrapper = new Map<Date, StaffAvailabilityWrapper>();

        punchPass = passedPunchPass;
        
        // Initialize static variables with configuration settings 
        initializeAppointmentConfig();
        
        Map<Date, List<Appointment__c>> mapDateToAppts = new Map<Date, List<Appointment__c>>();
        if (!staff.Appointments__r.isEmpty()) {
            mapDateToAppts = getMapOfDailyAppts(
                staff
            );
        }

        addSlotsToWrapper(
            mapDateToWrapper, 
            mapDateToAppts, 
            staff
        );
        
        return mapDateToWrapper.values();
    }

    /**********************************
     * Initialize static variables with configuration settings 
     *   from membership category and membership type
     * 
     * Appointment_Time_Slot_Interval__c - Lapsed minutes between availability slots
     * Appointment_Length__c - Length of appointment in minutes
     * Minimum_Days_Between_Appointments__c - Amount of days required between appointments. 
     *   Only show slots at least this many days from existing appointments for this
     *   membership category
     * Maximum_Monthly_Appointments__c - Do not display any slots for calendar months where the contact
     *   has reached the maximum monthly appointments for this category
     * Maximum_Monthly_Appointments__c - Do not allow appointments for maxed out months
     * Required_Hours_Notice__c - Minimum hours-notice needed to schedule an appointment
     ***********************************/

    private static void initializeAppointmentConfig() {
        appointmentIntervalInMinutes = 
            punchPass.TREX1__memb_Category__r.Appointment_Time_Slot_Interval__c != null ? 
            Integer.valueOf( punchPass.TREX1__memb_Category__r.Appointment_Time_Slot_Interval__c ) :
            30;
        
        appointmentLength = 
            punchPass.TREX1__memb_Type__r.Appointment_Length__c != null ?
            Integer.valueOf( punchPass.TREX1__memb_Type__r.Appointment_Length__c ) :
            30;
        
        minimumDaysBetweenAppointments = 
            punchPass.TREX1__memb_Category__r.Minimum_Days_Between_Appointments__c != null ? 
            Integer.valueOf( punchPass.TREX1__memb_Category__r.Minimum_Days_Between_Appointments__c ) :
            0;

        if (punchPass.TREX1__memb_Category__r.Maximum_Monthly_Appointments__c != null) {
            maxMonthlyAppointments = Integer.valueOf( punchPass.TREX1__memb_Category__r.Maximum_Monthly_Appointments__c );
            setMaxedOutMonths();
        }

        requiredHoursNotice = 
            punchPass.TREX1__memb_Category__r.Required_Hours_Notice__c != null ?
            Integer.valueOf( punchPass.TREX1__memb_Category__r.Required_Hours_Notice__c ) :
            0;
        setEarliestAppointmentTime();
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
            if (mapDateToAppts.containsKey(startDate)) {
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
     * @param Map<Date,List<Appointment__c>> map of booked appts for this date
     * @param TREX1__Staff__c staff member
     * @return StaffAvailabilityWrapper custom wrapper with availability slots
     ***********************************/

    private static void addSlotsToWrapper(
        Map<Date, StaffAvailabilityWrapper> mapDateToWrapper, 
        Map<Date, List<Appointment__c>> mapDateToAppts, 
        TREX1__Staff__c staff
    ) {
        List<Staff_Availability_Schedule__c> lstSchedules = staff.Staff_Availability_Schedules__r;

        for (Staff_Availability_Schedule__c sas : lstSchedules) {

            // Guard against maximum appointments in month
            if (maxedOutMonths != null && maxedOutMonths.contains( getMonthKey(sas.Start_DateTime__c) )) {
                continue;
            }

            // Enforce minimum days between appointments policy
            if (minimumDaysBetweenAppointments > 0) {
                if( !validateMinimumNumberOfDaysPolicy(sas) ) {
                    continue;
                }
            }

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

            // Establish min/max for the schedule
            Datetime dtScheduleStart = sas.Start_DateTime__c;
            dtScheduleStart = dtScheduleStart < roundedCurrentTime ?
                roundedCurrentTime :
                dtScheduleStart
            ;
            Datetime dtScheduleEnd = sas.End_DateTime__c;
            
            // No need to evaluate if current time is later than end date of today's availability
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
            Datetime dtNextEndTime  = dtScheduleStart.addMinutes( appointmentLength );
            
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

                    dtNextStartTime = dtNextStartTime.addMinutes( appointmentIntervalInMinutes );
                    dtNextEndTime = dtNextStartTime.addMinutes( appointmentLength );
                }
                if (dtNextStartTime < appt.End_DateTime__c) {
                    dtNextStartTime = appt.End_DateTime__c;
                    dtNextEndTime = dtNextStartTime.addMinutes( appointmentLength );
                }
                // No need to evaluate appointments after availability schedule ends
                if (dtNextStartTime >= dtScheduleEnd) {
                    break;
                }
            }

            // Get availability slots for rest of availability schedule
            while (dtNextEndTime <= dtScheduleEnd) {
                mapDateToWrapper.get(sas.Date_Only__c).availabilitySlots.add( 
                    getSlotFromRange(
                        dtNextStartTime, 
                        dtNextEndTime
                    )
                );
                dtNextStartTime = dtNextStartTime.addMinutes( appointmentIntervalInMinutes );
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
     * Verify that schedule is not within minimum number of days of existing appointment
     * @param Staff_Availability_Schedule__c
     * @return Boolean true value represents a valid schedule
     **********************************/

    private static Boolean validateMinimumNumberOfDaysPolicy(
        Staff_Availability_Schedule__c sas
    ) {
        Boolean isValid = true;
        // This method replaces the lines above - caches list of appointments to be used in other validations
        List<Appointment__c> lstAppointments = getExistingAppointments();

        Date minBoundary = sas.Date_Only__c.addDays(-minimumDaysBetweenAppointments);
        Date maxBoundary = sas.Date_Only__c.addDays(minimumDaysBetweenAppointments);
        for (Appointment__c appt : lstExistingAppointments) {
            Date apptDate = Date.newInstance(
                appt.Start_DateTime__c.year(), 
                appt.Start_DateTime__c.month(), 
                appt.Start_DateTime__c.day()
            );
            if (apptDate >= minBoundary && apptDate <= maxBoundary) {
                isValid = false;
            }
        }
        return isValid;
    }

    /**********************************
     * Store invalid month keys in a set to guard against max appointments in a month
     **********************************/

    private static void setMaxedOutMonths() {
        maxedOutMonths = new Set<String>();
        List<Appointment__c> lstAppointments = getExistingAppointments();
        Map<String, Integer> mapMonthToNumAppointments = new Map<String, Integer>();
        String monthKey = '';
        for (Appointment__c appt : lstAppointments) {
            monthKey = getMonthKey(appt.Start_DateTime__c);
            if (!mapMonthToNumAppointments.containsKey(monthKey)) {
                mapMonthToNumAppointments.put(monthKey, 0);
            }
            mapMonthToNumAppointments.put(monthKey, mapMonthToNumAppointments.get(monthKey) + 1);
            if (mapMonthToNumAppointments.get(monthKey) >= maxMonthlyAppointments) {
                maxedOutMonths.add(monthKey);
            }
        }
    }

    /**********************************
     * Creates a key for set of maxed out months (maxedOutMonths)
     * @param dtValue Date time value to create key for
     * @return String Month key
     **********************************/

    @testVisible
    private static String getMonthKey(
        DateTime dtValue
    ) {
        return String.valueOf(dtValue.month()) + String.valueOf(dtValue.year());
    }
    
    /**********************************
     * Cache and return collection of complete and scheduled appointments for this
     *   membership category and contact
     * @return Appointment__c[] list of appointments
     **********************************/

    private static List<Appointment__c> getExistingAppointments() {
        if (lstExistingAppointments == null) {
            lstExistingAppointments = CommunityPunchPassesController.getAppointmentsByContactAndCategory(
                punchPass.TREX1__Contact__c, 
                punchPass.TREX1__memb_Category__c
            );
        }
        return lstExistingAppointments;
    }

    /**********************************
     * Set static variable to earliest availability time boundary, 
     *   based on rounded current time plus required hours' notice
     ***********************************/

    private static void setEarliestAppointmentTime() {
        Integer minute = System.now().minute() < 30 ? 30 : 0;
        Integer hour = System.now().minute() < 30 ? System.now().hour() : System.now().hour() + 1;
        roundedCurrentTime = Datetime.newInstance(
            System.now().year(), 
            System.now().month(), 
            System.now().day(), 
            hour, 
            minute, 
            0
        ).addHours(requiredHoursNotice);
    }

}