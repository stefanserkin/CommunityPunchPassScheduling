@isTest
private class StaffAvailabilityWrapperService_Test {
    
    @testSetup
    static void makeData() {
        List<Account> lstAccounts = TestDataFactory.createHouseholdAccounts(1);
        insert lstAccounts;
        
        List<Contact> lstContacts = TestDataFactory.createContacts(lstAccounts, 1);
        insert lstContacts;
        
        TREX1__Transaction__c trans = TestDataFactory.createTransaction(lstContacts[0]);
        
        List<TREX1__Membership_Category__c> lstCategories = TestDataFactory.createPunchPassMembershipCategories(1);
        insert lstCategories;

        List<TREX1__Location__c> lstLocations = TestDataFactory.createLocations(1);
        insert lstLocations;

        List<TREX1__Membership_Type__c> lstTypes = TestDataFactory.createMembershipTypes(
            lstCategories, lstLocations.get(0), 1
        );
        insert lstTypes;
        
        TREX1__Membership__c punchPass = TestDataFactory.createActivePunchPassesFromType(
            lstContacts[0], 
            lstContacts[0].AccountId, 
            trans.Id, 
            lstTypes[0].Id
        );
        insert punchPass;
        
        List<Contact> lstStaffContacts = TestDataFactory.createContacts(1);
        insert lstStaffContacts;
        
        List<TREX1__Staff__c> lstStaff = TestDataFactory.createStaffFromContacts(
            lstStaffContacts
        );
        insert lstStaff;
        
        insert new Assigned_Staff__c(
            Staff__c = lstStaff[0].Id, 
            Membership_Type__c = lstTypes[0].Id
        );
        
        List<Staff_Availability_Schedule__c> lstSchedules = TestDataFactory.createAvailabilityForConsecutiveDays(
            lstStaff[0], // Staff
            Date.today(), // Date
            Time.newInstance(9, 0, 0, 0), // Start time
            Time.newInstance(17, 0, 0, 0), // End time
            lstTypes[0].TREX1__Location__c, // Location
            5 // Number of days
        );
        insert lstSchedules;
        
        // Insert appointment
        Appointment__c appt = new Appointment__c();
        appt.Contact__c = punchPass.TREX1__Contact__c;
        appt.Staff__c = lstStaff.get(0).Id;
        appt.Membership__c = punchPass.Id;
        appt.Membership_Category__c = punchPass.TREX1__memb_Category__c;
        appt.Membership_Type__c = punchPass.TREX1__memb_Type__c;
        appt.Status__c = 'Scheduled';
        appt.Start_DateTime__c = DateTime.newInstance(Date.today().addDays(1), Time.newInstance(11, 0, 0, 0));
        appt.End_DateTime__c = appt.Start_DateTime__c.addHours(1);
        insert appt;
    }
    
    @isTest
    static void testGetWrappersFromStaff() {
        TREX1__Membership_Type__c memType = [SELECT Id, Name, TREX1__Location__c, Appointment_Length__c FROM TREX1__Membership_Type__c LIMIT 1];
        
        List<TREX1__Staff__c> lstStaff = CommunityPunchPassesController.getAssignedStaff(
            memType.Id, 
            memType.TREX1__Location__c
        );

        Id punchPassId = [SELECT Id FROM TREX1__Membership__c LIMIT 1].Id;
        TREX1__Membership__c punchPass = CommunityPunchPassesController.getPunchPassById(
            punchPassId
        );
        
        Test.startTest();
        List<StaffAvailabilityWrapper> lstWrappers = StaffAvailabilityWrapperService.getWrappersFromStaff(
            lstStaff.get(0), 
            punchPass
        );
        Test.stopTest();

        Appointment__c appt = punchPass.Appointments__r.get(0);
        Date apptDate = Date.newInstance(
            appt.Start_DateTime__c.year(), 
            appt.Start_DateTime__c.month(), 
            appt.Start_DateTime__c.day()
        );

        // Check to see if there is any availability that overlaps with a scheduled appointment
        Boolean hasInvalidSlot = false;
        for (StaffAvailabilityWrapper sas : lstWrappers) {
            if (sas.availabilityDate == apptDate) {
                for (StaffAvailabilityWrapper.AvailabilitySlot slot : sas.availabilitySlots) {
                    if (
                        slot.startTime < appt.End_DateTime__c && 
                        slot.endTime > appt.Start_DateTime__c
                    ) {
                        hasInvalidSlot = true;
                    }
                }
            }
        }
        
        System.assert(
            !lstWrappers.isEmpty(), 
            'List of wrappers should not be empty'
        );

        System.assert(
            !hasInvalidSlot, 
            'Received availability during a scheduled appointment'
        );
    }

    
    @isTest
    static void testGetWrappersWithoutRestrictions() {
        TREX1__Membership_Type__c memType = [SELECT Id, Name, TREX1__Location__c, Appointment_Length__c, TREX1__Category__c FROM TREX1__Membership_Type__c LIMIT 1];
        
        memType.Appointment_Length__c = null;
        update memType;
        
        TREX1__Membership_Category__c memCat = new TREX1__Membership_Category__c(
            Id = memType.TREX1__Category__c, 
            Minimum_Days_Between_Appointments__c = null, 
            Maximum_Monthly_Appointments__c = null, 
            Appointment_Time_Slot_Interval__c = null, 
            Required_Hours_Notice__c = null
        );
        update memCat;
        
        List<TREX1__Staff__c> lstStaff = CommunityPunchPassesController.getAssignedStaff(
            memType.Id, 
            memType.TREX1__Location__c
        );

        Id punchPassId = [SELECT Id FROM TREX1__Membership__c LIMIT 1].Id;
        TREX1__Membership__c punchPass = CommunityPunchPassesController.getPunchPassById(
            punchPassId
        );
        
        Test.startTest();
        List<StaffAvailabilityWrapper> lstWrappers = StaffAvailabilityWrapperService.getWrappersFromStaff(
            lstStaff.get(0), 
            punchPass
        );
        Test.stopTest();

        Appointment__c appt = punchPass.Appointments__r.get(0);
        Date apptDate = Date.newInstance(
            appt.Start_DateTime__c.year(), 
            appt.Start_DateTime__c.month(), 
            appt.Start_DateTime__c.day()
        );

        // Check to see if there is any availability that overlaps with a scheduled appointment
        Boolean hasInvalidSlot = false;
        for (StaffAvailabilityWrapper sas : lstWrappers) {
            if (sas.availabilityDate == apptDate) {
                for (StaffAvailabilityWrapper.AvailabilitySlot slot : sas.availabilitySlots) {
                    if (
                        slot.startTime < appt.End_DateTime__c && 
                        slot.endTime > appt.Start_DateTime__c
                    ) {
                        hasInvalidSlot = true;
                    }
                }
            }
        }
        
        System.assert(
            !lstWrappers.isEmpty(), 
            'List of wrappers should not be empty'
        );

        System.assert(
            !hasInvalidSlot, 
            'Received availability during a scheduled appointment'
        );
    }
    
    
    @isTest
    static void testGetMonthKey() {
        DateTime dt = DateTime.now();
        String monthKey = StaffAvailabilityWrapperService.getMonthKey(dt);
        String expectedMonthKey = String.valueOf(dt.month()) + String.valueOf(dt.year());
		System.assertEquals(expectedMonthKey, monthKey, 'Received an unexpected month key. Expected ' + expectedMonthKey);        
    }
    
}