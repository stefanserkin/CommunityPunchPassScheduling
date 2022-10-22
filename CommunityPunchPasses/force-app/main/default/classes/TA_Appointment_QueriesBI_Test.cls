@isTest
private class TA_Appointment_QueriesBI_Test {

    @testSetup
    static void makeData() {

        List<TREX1__Membership_Category__c> lstCategories = TestDataFactory.createMembershipCategories(1);
        insert lstCategories;

        List<TREX1__Location__c> lstLocations = TestDataFactory.createLocations(1);
        insert lstLocations;

        List<TREX1__Membership_Type__c> lstTypes = TestDataFactory.createMembershipTypes(
            lstCategories, lstLocations.get(0), 1
        );
        insert lstTypes;

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
            lstStaff[0], 
            Date.today(), 
            Time.newInstance(9, 0, 0, 0), 
            Time.newInstance(15, 0, 0, 0), 
            lstTypes[0].TREX1__Location__c, 
            5
        );
        insert lstSchedules;

    }

    @isTest
    static void testQueriesBeforeInsertForStaff() {

        TREX1__Membership_Type__c memType = [SELECT Id, Name, TREX1__Category__c, TREX1__Location__c, Appointment_Length__c FROM TREX1__Membership_Type__c LIMIT 1];
        
        List<TREX1__Staff__c> lstStaff = CommunityPunchPassesController.getAssignedStaff(
            memType.Id, 
            memType.TREX1__Location__c
        );

        List<Account> lstAccounts = TestDataFactory.createHouseholdAccounts(1);
        insert lstAccounts;
        
        List<Contact> lstContacts = TestDataFactory.createContacts(lstAccounts, 1);
        insert lstContacts;
        
        TREX1__Transaction__c trans = TestDataFactory.createTransaction(lstContacts[0]);
        
        TREX1__Membership__c punchPass = TestDataFactory.createActivePunchPassesFromType(
            lstContacts[0], 
            lstContacts[0].AccountId, 
            trans.Id, 
            memType.Id
        );
        insert punchPass;
        
        // Insert first appointment
        Appointment__c appt = new Appointment__c();
        appt.Contact__c = punchPass.TREX1__Contact__c;
        appt.Staff__c = lstStaff.get(0).Id;
        appt.Membership__c = punchPass.Id;
        appt.Membership_Category__c = memType.TREX1__Category__c;
        appt.Membership_Type__c = memType.Id;
        appt.Status__c = 'Scheduled';
        appt.Start_DateTime__c = DateTime.newInstance(Date.today().addDays(1), Time.newInstance(11, 0, 0, 0));
        appt.End_DateTime__c = appt.Start_DateTime__c.addHours(1);
        appt.Bypass_Staff_Auto_Emails__c = true;
        appt.Bypass_Customer_Auto_Emails__c = true;
        insert appt;

        // Create second appointment for insert
        Appointment__c newAppt = appt.clone(false, false, false, false);
        newAppt.Start_DateTime__c = newAppt.Start_DateTime__c.addDays(1);
        newAppt.End_DateTime__c = newAppt.End_DateTime__c.addDays(1);
        newAppt.Is_Conflict__c = false;
        
        Test.startTest();
        insert newAppt;
        Test.stopTest();

        Map<Id, List<Appointment__c>> mapStaffToScheduledAppointments;
        mapStaffToScheduledAppointments = TA_Appointment_QueriesBI.getInstance().mapStaffIdToScheduledAppointments;

        System.assert(
            mapStaffToScheduledAppointments.containsKey(newAppt.Staff__c), 
            'Should have received staff with appointments'
        );

        System.assertEquals(
            appt.Id, 
            mapStaffToScheduledAppointments.get(newAppt.Staff__c).get(0).Id, 
            'Should have received original appointment'
        );

    }

}
