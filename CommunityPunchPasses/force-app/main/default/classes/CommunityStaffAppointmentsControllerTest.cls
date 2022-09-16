@isTest
private class CommunityStaffAppointmentsControllerTest {
    
    private static final String STAFF_EMAIL = 'rey@mets.com';

    @testSetup
    static void makeData() {
        List<Account> lstAccounts = TestDataFactory.createHouseholdAccounts(1);
        insert lstAccounts;
        
        List<Contact> lstContacts = TestDataFactory.createContacts(lstAccounts, 1);
        insert lstContacts;
        
        TREX1__Transaction__c trans = TestDataFactory.createTransaction(lstContacts[0]);
        
        List<TREX1__Membership_Category__c> lstCategories = TestDataFactory.createMembershipCategories(1);
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
            lstStaff[0], 
            Date.today(), 
            Time.newInstance(9, 0, 0, 0), 
            Time.newInstance(15, 0, 0, 0), 
            lstTypes[0].TREX1__Location__c, 
            5
        );
        insert lstSchedules;

        // Create user for staff contact
        List<User> lstStaffUsers = TestDataFactory.createExternalUsers(lstStaffContacts);
        lstStaffUsers.get(0).Email = STAFF_EMAIL;
        insert lstStaffUsers;
        
        List<Appointment__c> lstAppointments = new List<Appointment__c>();

        // Create past appointment
        Appointment__c appt = new Appointment__c();
        appt.Contact__c = punchPass.TREX1__Contact__c;
        appt.Staff__c = lstStaff.get(0).Id;
        appt.Membership__c = punchPass.Id;
        appt.Membership_Category__c = punchPass.TREX1__memb_Category__c;
        appt.Membership_Type__c = punchPass.TREX1__memb_Type__c;
        appt.Status__c = 'Complete';
        appt.Start_DateTime__c = DateTime.newInstance(Date.today().addDays(-1), Time.newInstance(11, 0, 0, 0));
        appt.End_DateTime__c = appt.Start_DateTime__c.addHours(1);
        lstAppointments.add(appt);

        // Create upcoming appointment
        Appointment__c upcomingAppt = new Appointment__c();
        upcomingAppt.Contact__c = punchPass.TREX1__Contact__c;
        upcomingAppt.Staff__c = lstStaff.get(0).Id;
        upcomingAppt.Membership__c = punchPass.Id;
        upcomingAppt.Membership_Category__c = punchPass.TREX1__memb_Category__c;
        upcomingAppt.Membership_Type__c = punchPass.TREX1__memb_Type__c;
        upcomingAppt.Status__c = 'Scheduled';
        upcomingAppt.Start_DateTime__c = DateTime.newInstance(Date.today().addDays(1), Time.newInstance(11, 0, 0, 0));
        upcomingAppt.End_DateTime__c = appt.Start_DateTime__c.addHours(1);
        lstAppointments.add(upcomingAppt);

        insert lstAppointments;

    }

    @isTest
    static void testGetStaffAppointments() {
        User staffUser = [SELECT Id FROM User WHERE Email = :STAFF_EMAIL LIMIT 1];
        Test.startTest();
        List<Appointment__c> lstAppointments = CommunityStaffAppointmentsController.getStaffAppointments(
            staffUser.Id
        );
        Test.stopTest();
        System.assertEquals(2, lstAppointments.size(), 'Should have received two appointments');
    }

    @isTest
    static void testCheckInAppointments() {
        User staffUser = [SELECT Id FROM User WHERE Email = :STAFF_EMAIL LIMIT 1];
        List<Appointment__c> lstAppointments = new List<Appointment__c>();
        lstAppointments = CommunityStaffAppointmentsController.getStaffAppointments(
            staffUser.Id
        );
        List<Appointment__c> lstPastAppointments = new List<Appointment__c>();
        for (Appointment__c appt : lstAppointments) {
            if (appt.Start_DateTime__c < DateTime.now()) {
                lstPastAppointments.add(appt);
            }
        }
        List<String> lstFailures = new List<String>();
        
        Test.startTest();
        lstFailures = CommunityStaffAppointmentsController.checkInAppointments(lstPastAppointments);
        Test.stopTest();
        
        System.assert(lstFailures.isEmpty(), 'Failed to update an eligible appointment');
        
        List<Appointment__c> lstRefreshedAppointments = [
            SELECT Id, Attended__c, Membership__c FROM Appointment__c WHERE Id IN :lstPastAppointments
        ];

        System.assertEquals(
            true, 
            lstRefreshedAppointments.get(0).Attended__c, 
            'Attended should be set to true'
        );
        
    }

    @isTest
    static void testCancelAppointments() {
        User staffUser = [SELECT Id FROM User WHERE Email = :STAFF_EMAIL LIMIT 1];
        List<Appointment__c> lstAppointments = new List<Appointment__c>();
        lstAppointments = CommunityStaffAppointmentsController.getStaffAppointments(
            staffUser.Id
        );
        List<Appointment__c> lstUpcomingAppointments = new List<Appointment__c>();
        for (Appointment__c appt : lstAppointments) {
            if (appt.Start_DateTime__c > DateTime.now()) {
                lstUpcomingAppointments.add(appt);
            }
        }
        Test.startTest();
        CommunityStaffAppointmentsController.cancelAppointments(lstUpcomingAppointments);
        Test.stopTest();

        List<Appointment__c> lstRefreshedAppointments = [
            SELECT Id, Status__c FROM Appointment__c WHERE Id IN :lstUpcomingAppointments
        ];

        String expectedStatus = CommunityStaffAppointmentsController.STATUS_CANCELLED;

        System.assertEquals(
            expectedStatus, 
            lstRefreshedAppointments.get(0).Status__c, 
            'Status should be cancelled'
        );
    }
    
    @isTest
    static void testCheckInAttendedAppointments() {
        // Get staff
        User staffUser = [SELECT Id FROM User WHERE Email = :STAFF_EMAIL LIMIT 1];
        // Get all appointments
        List<Appointment__c> lstAppointments = new List<Appointment__c>();
        lstAppointments = CommunityStaffAppointmentsController.getStaffAppointments(
            staffUser.Id
        );
        // Filter to past appointments
        List<Appointment__c> lstPastAppointments = new List<Appointment__c>();
        for (Appointment__c appt : lstAppointments) {
            if (appt.Start_DateTime__c < DateTime.now()) {
                lstPastAppointments.add(appt);
            }
        }
        // Check in appointment
		List<String> lstFirstFailures = new List<String>();
        lstFirstFailures = CommunityStaffAppointmentsController.checkInAppointments(
            lstPastAppointments
        );      
        
        // Attempt to check in appointment a second time
        List<String> lstSecondFailures = new List<String>();
        Test.startTest();
        lstSecondFailures = CommunityStaffAppointmentsController.checkInAppointments(
            lstPastAppointments
        );
        Test.stopTest();
        
        // First round should be successful. Second round should have failures
        System.assert(lstFirstFailures.isEmpty(), 'Failed to update the appointment');
        System.assert(!lstSecondFailures.isEmpty(), 'Should have received a failure on the second attempt');
    }
    
    @isTest
    static void testCheckInEmptyMembership() {
        // Get staff
        User staffUser = [SELECT Id FROM User WHERE Email = :STAFF_EMAIL LIMIT 1];
        // Get all appointments
        List<Appointment__c> lstAppointments = new List<Appointment__c>();
        lstAppointments = CommunityStaffAppointmentsController.getStaffAppointments(
            staffUser.Id
        );
        // Filter to past appointments
        List<Appointment__c> lstPastAppointments = new List<Appointment__c>();
        for (Appointment__c appt : lstAppointments) {
            if (appt.Start_DateTime__c < DateTime.now()) {
                lstPastAppointments.add(appt);
            }
        }
        
        TREX1__Membership__c punchPass = [SELECT Id, TREX1__Remaining_Value__c FROM TREX1__Membership__c WHERE Id = :lstPastAppointments.get(0).Membership__c LIMIT 1];
        
        // Decrement punch pass until remaining equals zero
        List<TREX1__Pass_Decrement__c> lstDecrements = new List<TREX1__Pass_Decrement__c>();
        for (Integer i = 0; i < punchPass.TREX1__Remaining_Value__c; i++) {
            TREX1__Pass_Decrement__c pd = new TREX1__Pass_Decrement__c();
            pd.TREX1__Date__c = Datetime.now().addDays(-1);
            pd.TREX1__Membership_Punch_Pass_Decrement__c = punchPass.Id;
            pd.TREX1__Value__c = 1;
            lstDecrements.add(pd);
        }
        insert lstDecrements;
        
        List<Appointment__c> lstRefreshedAppointments = [
            SELECT Id, Attended__c, Bypass_Auto_Decrement__c, Membership__c, Membership__r.TREX1__Remaining_Value__c 
              FROM Appointment__c
             WHERE Id IN :lstPastAppointments
        ];

        // Attempt to check in appointment
        List<String> lstFailures = new List<String>();
        Test.startTest();
        lstFailures = CommunityStaffAppointmentsController.checkInAppointments(
            lstRefreshedAppointments
        );
        Test.stopTest();

        System.assert(!lstFailures.isEmpty(), 'Should have found a failed check in');
        
    }

}