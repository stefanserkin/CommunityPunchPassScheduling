public inherited sharing class CommunityPunchPassesHelper {

    public static List<String> getListOfCategoriesFromString(
        String strMembershipCategoryNames
    ) {
        List<String> lstFormattedCategoryNames = new List<String>();
        List<String> lstMembershipCategoryNames =
            strMembershipCategoryNames != null ?
            strMembershipCategoryNames.split(',') :
            new List<String>();
        for (String catName : lstMembershipCategoryNames) {
            catName = catName.trim();
            lstFormattedCategoryNames.add(catName);
        }
        return lstFormattedCategoryNames;
    }

    public static StaffAvailabilityWrapper getWrapperFromStaff(
        TREX1__Staff__c staff
    ) {
        // Create wrapper to return
        StaffAvailabilityWrapper staffWrapper = new StaffAvailabilityWrapper();
        staffWrapper.staffId = staff.Id;
        staffWrapper.staffName = staff.Name;
        // Create new list of inner class
        staffWrapper.availabilitySlots = new List<StaffAvailabilityWrapper.AvailabilitySlot>();

        Map<Date, List<Appointment__c>> mapDateToAppts;
        mapDateToAppts = new Map<Date, List<Appointment__c>>();
        if (!staff.Appointments__r.isEmpty()) {
            mapDateToAppts = getMapOfDailyAppts(staff);
        }

        for (Staff_Availability_Schedule__c sas : staff.Staff_Availability_Schedules__r) {

            // Establish min/max for the daily schedule
            Datetime dtScheduleStart = Datetime.newInstance(
                sas.Date__c, sas.Start_Time__c
            );
            Datetime dtScheduleEnd = Datetime.newInstance(
                sas.Date__c, sas.End_Time__c
            );

            // Use map of daily appointments to check for full availability
            List<Appointment__c> lstDailyAppts = mapDateToAppts.get(sas.Date__c);

            // If no appts, return full day of availability
            if (lstDailyAppts == null || lstDailyAppts.isEmpty()) {
                StaffAvailabilityWrapper.AvailabilitySlot slot;
                slot = new StaffAvailabilityWrapper.AvailabilitySlot();
                slot.startTime = dtScheduleStart;
                slot.endTime = dtScheduleEnd;
                staffWrapper.availabilitySlots.add( slot );
                continue;
            }

            // Initialize previous appt end time with start of day availability
            Datetime dtPreviousApptEndTime = dtScheduleStart;

            for (Appointment__c appt : lstDailyAppts) {

                StaffAvailabilityWrapper.AvailabilitySlot slot;
                slot = new StaffAvailabilityWrapper.AvailabilitySlot();

                if (dtPreviousApptEndTime < appt.Start_DateTime__c) {
                    slot.startTime = dtPreviousApptEndTime;
                    slot.endTime = appt.Start_DateTime__c;
                    staffWrapper.availabilitySlots.add( slot );
                }

                dtPreviousApptEndTime = appt.End_DateTime__c;
            }

            // Check for available time from last appointment through end of day
            if (dtPreviousApptEndTime < dtScheduleEnd) {
                StaffAvailabilityWrapper.AvailabilitySlot slot;
                slot = new StaffAvailabilityWrapper.AvailabilitySlot();
                slot.startTime = dtPreviousApptEndTime;
                slot.endTime = dtScheduleEnd;
                staffWrapper.availabilitySlots.add( slot );
            }

        }

        // Return wrapper
        return staffWrapper;
    }

    public static Map<Date, List<Appointment__c>> getMapOfDailyAppts(
        TREX1__Staff__c staff
    ) {
        Map<Date, List<Appointment__c>> mapDateToAppts;
        mapDateToAppts = new Map<Date, List<Appointment__c>>();

        Date previousApptDate;

        List<Appointment__c> lstDailyAppts = new List<Appointment__c>();

        for (Integer i = 0; i < staff.Appointments__r.size(); i++) {

            Appointment__c appt = staff.Appointments__r[i];
            if (
                previousApptDate == null || 
                previousApptDate == Date.valueOf(appt.Start_DateTime__c)
            ) {
                lstDailyAppts.add(appt);
            } else {
                mapDateToAppts.put(previousApptDate, lstDailyAppts);
                lstDailyAppts.clear();
                lstDailyAppts.add(appt);
            }

            previousApptDate = Date.valueOf(appt.Start_DateTime__c);

            // If the last in the list, add list to map
            if (i == staff.Appointments__r.size() - 1) {
                mapDateToAppts.put(previousApptDate, lstDailyAppts);
            }
        }
        return mapDateToAppts;
    }
    
}
