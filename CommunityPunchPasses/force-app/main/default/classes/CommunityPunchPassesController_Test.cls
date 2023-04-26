@isTest
private class CommunityPunchPassesController_Test {

    private static Id hhRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();
    private static Id punchPassRecTypeId = Schema.SObjectType.TREX1__Membership__c.getRecordTypeInfosByDeveloperName().get('Punch_Pass_Membership').getRecordTypeId();
    private static Id standardTransactionRecTypeId = Schema.SObjectType.TREX1__Transaction__c.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();
    
    private static final String STATUS_ACTIVE = 'Active';
    private static final String STATUS_COMPLETE = 'Complete';
    private static final Integer ACTIVE_PUNCH_PASS_STORED_VALUE = 6;
    private static final Integer COMPLETED_PUNCH_PASS_STORED_VALUE = 1;
    private static final Integer NUMBER_OF_CONTACTS = 5;
    private static final Integer NUMBER_OF_COMPLETED_MEMBERSHIPS = 1;
    private static final String VALID_MEMBERSHIP_CATEGORY = 'Pilates';
    private static final String RECEIPT_NAME = 'Receipt-039483628948267346';
    private static final String URL_FIELD_NAME = 'LastModifiedDate';

    @TestSetup
    static void makeData() {

        Account acc = new Account(Name = 'Test Account', RecordTypeId = hhRecordTypeId);
        insert acc;

        List<Contact> lstContacts = new List<Contact>();
        for (Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            lstContacts.add(
                new Contact(
                    AccountId = acc.Id,
                    FirstName = 'Test' + String.valueOf(i),
                    LastName = 'Testeroo',
                    Email = 'test@testerton.com',
                    Birthdate = Date.today().addYears(-(i * 5)).addMonths(i)
                )
            );
        }
        insert lstContacts;

        TREX1__Transaction__c trans = new TREX1__Transaction__c();
        trans.RecordTypeId = standardTransactionRecTypeId;
        trans.TREX1__Account__c = acc.Id;
        trans.TREX1__Contact__c = lstContacts.get(0).Id;
        trans.TREX1__Public_Visibility__c = true;
        trans.TREX1__Status__c = 'Close';
        insert trans;

        Attachment attach = new Attachment();   	
    	attach.Name = RECEIPT_NAME;
    	Blob bodyBlob = Blob.valueOf('Receipt Attachment Body');
    	attach.body = bodyBlob;
        attach.parentId = trans.id;
        insert attach;

        List<TREX1__Membership_Category__c> lstCategories = TestDataFactory.createMembershipCategories(1);
        insert lstCategories;

        List<TREX1__Location__c> lstLocations = TestDataFactory.createLocations(1);
        insert lstLocations;

        List<TREX1__Membership_Type__c> lstTypes = TestDataFactory.createMembershipTypes(
            lstCategories, lstLocations.get(0), 1
        );
        insert lstTypes;

        List<TREX1__Membership__c> lstMemberships = new List<TREX1__Membership__c>();
        // Completed membership
        lstMemberships.add(
            new TREX1__Membership__c(
                TREX1__Contact__c = lstContacts.get(0).Id, 
                TREX1__Account__c = acc.Id, 
                RecordTypeId = punchPassRecTypeId, 
                TREX1__Status__c = STATUS_COMPLETE, 
                TREX1__memb_Category__c = lstCategories[0].Id, 
                TREX1__Category_Name__c = VALID_MEMBERSHIP_CATEGORY, 
                TREX1__memb_Type__c = lstTypes[0].Id, 
                TREX1__Start_Date__c = Date.today().addDays(-1), 
                TREX1__Stored_Value__c = 1, 
                TREX1__Purchasing_Transaction__c = trans.Id
            )
        );
        // Active memberships
        for (Contact ct : lstContacts) {
            lstMemberships.add(
                new TREX1__Membership__c(
                    TREX1__Contact__c = ct.Id, 
                    TREX1__Account__c = acc.Id, 
                    RecordTypeId = punchPassRecTypeId, 
                    TREX1__Status__c = STATUS_ACTIVE, 
                    TREX1__memb_Category__c = lstCategories[0].Id, 
                    TREX1__Category_Name__c = VALID_MEMBERSHIP_CATEGORY, 
                    TREX1__memb_Type__c = lstTypes[0].Id, 
                    TREX1__Start_Date__c = Date.today().addDays(-1), 
                    TREX1__Stored_Value__c = 6
                )
            );
        }
        insert lstMemberships;
        
        // Decrement completed punch pass so remaining equals zero
        TREX1__Pass_Decrement__c pd = new TREX1__Pass_Decrement__c();
        pd.TREX1__Date__c = Datetime.now();
        pd.TREX1__Membership_Punch_Pass_Decrement__c = lstMemberships.get(0).Id;
        pd.TREX1__Value__c = 1;
        insert pd;
    }

    @isTest
    static void testQueryForDecrements() {
        List<String> lstDecrementStrings = new List<String>();
        List<TREX1__Membership__c> lstPunchPasses = [
            SELECT Id, (SELECT Id FROM TREX1__Pass_Decrements__r)
              FROM TREX1__Membership__c 
             WHERE RecordTypeId = :punchPassRecTypeId
               AND TREX1__Total_Value__c > 0
        ];
        Test.startTest();
        lstDecrementStrings = CommunityPunchPassesController.getPassDecrements(
            lstPunchPasses.get(0).Id
        );
        Test.stopTest();
        System.assertEquals(
            lstPunchPasses.get(0).TREX1__Pass_Decrements__r.size(),
            lstDecrementStrings.size(),
            'Amount of decrement strings returned should equal the amount of decrements'
        );
    }

    @isTest
    static void testQueryForNoExistingDecrements() {
        List<String> lstDecrementStrings = new List<String>();
        List<TREX1__Membership__c> lstPunchPasses = [
            SELECT Id, (SELECT Id FROM TREX1__Pass_Decrements__r)
              FROM TREX1__Membership__c 
             WHERE RecordTypeId = :punchPassRecTypeId
               AND TREX1__Total_Value__c = 0
        ];
        Test.startTest();
        lstDecrementStrings = CommunityPunchPassesController.getPassDecrements(
            lstPunchPasses.get(0).Id
        );
        Test.stopTest();
        String expectedMessage = CommunityPunchPassesController.NO_DECREMENT_HISTORY_MESSAGE;
        System.assertEquals(
            expectedMessage,
            lstDecrementStrings.get(0),
            'Should have received the no decrement history message'
        );
    }

    @isTest
    static void testQueryForTransactionReceipt() {
        TREX1__Transaction__c trans = [SELECT Id FROM TREX1__Transaction__c LIMIT 1];
        Test.startTest();
        Id receiptId = CommunityPunchPassesController.getTransactionReceiptId(trans.Id);
        Test.stopTest();
        List<Attachment> lstAttachments = [SELECT Id, Name FROM Attachment WHERE ParentId = :trans.Id AND Name LIKE 'Receipt%'];
    	System.assertEquals(
            lstAttachments.get(0).Id,
            receiptId,
            'Receipt id returned by controller should match the receipt on the transaction'
        );
    }
    
    @isTest
    static void testGetPunchPassById() {
        
        TREX1__Membership__c punchPass = [SELECT Id FROM TREX1__Membership__c LIMIT 1];

        Test.startTest();
        TREX1__Membership__c punchPassFromController = CommunityPunchPassesController.getPunchPassById(punchPass.Id);
        Test.stopTest();

        System.assert(
            punchPassFromController != null,
            'Should have returned the punch pass membership'
        );

    }
    
    @isTest
    static void testQueryForActivePunchPasses() {
        
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Contact> lstCtsWithActiveMems = new List<Contact>();
        lstCtsWithActiveMems = CommunityPunchPassesController.getActivePunchPassesByContact(
            acc.Id,
            VALID_MEMBERSHIP_CATEGORY
        );
        Test.stopTest();

        System.assertEquals(
            NUMBER_OF_CONTACTS, 
            lstCtsWithActiveMems.size(), 
            'Should have received five memberships'
        );
        
        System.assertEquals(
            STATUS_ACTIVE, 
            lstCtsWithActiveMems.get(0).TREX1__Memberships__r.get(0).TREX1__Status__c, 
            'Membership status should be active'
        );

    }

    @isTest
    static void testQueryForCompletedPunchPasses() {
        
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Contact> lstCtsWithCompletedMems = new List<Contact>();
        lstCtsWithCompletedMems = CommunityPunchPassesController.getCompletedPunchPassesByContact(
            acc.Id,
            VALID_MEMBERSHIP_CATEGORY
        );
        Test.stopTest();
        
        System.assertEquals(
            NUMBER_OF_COMPLETED_MEMBERSHIPS, 
            lstCtsWithCompletedMems.size(), 
            'Should have one completed punch pass'
        );
        
        System.assertEquals(
            STATUS_COMPLETE, 
            lstCtsWithCompletedMems.get(0).TREX1__Memberships__r.get(0).TREX1__Status__c, 
            'Status should be complete'
        );
        
    }

    @isTest
    static void testQueryForActivePunchPassesWOCategories() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Contact> lstCtsWithActiveMems = new List<Contact>();
        lstCtsWithActiveMems = CommunityPunchPassesController.getActivePunchPassesByContact(
            acc.Id,
            null
        );
        Test.stopTest();

        System.assertEquals(
            0, 
            lstCtsWithActiveMems.size(),
            'Should have received no memberships'
        );

    }

    @isTest
    static void testQueryForCompletedPunchPassesWOCategories() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Contact> lstCtsWithActiveMems = new List<Contact>();
        lstCtsWithActiveMems = CommunityPunchPassesController.getCompletedPunchPassesByContact(
            acc.Id, 
            null
        );
        Test.stopTest();

        System.assertEquals(
            0, 
            lstCtsWithActiveMems.size(),
            'Should have received no memberships'
        );
    }

    @isTest
    static void testGetAssignedStaffAvailability() {
        // Create staff contact and staff record
        Contact ct = TestDataFactory.createContacts(1).get(0);
        insert ct;
        TREX1__Staff__c staff = TestDataFactory.createStaffFromContacts(
            new List<Contact>{ ct }
        ).get(0);
        insert staff;
        
        
        TREX1__Membership_Type__c memType = [
            SELECT Id, Appointment_Length__c, TREX1__Location__c
              FROM TREX1__Membership_Type__c
             LIMIT 1
        ];

        // Get membership
        TREX1__Membership__c membership = [
            SELECT Id, TREX1__Contact__c, TREX1__memb_Category__c, TREX1__memb_Type__c 
              FROM TREX1__Membership__c 
             WHERE TREX1__memb_Type__c = :memType.Id 
             LIMIT 1
        ];
        
        insert new Assigned_Staff__c(
            Staff__c = staff.Id, 
            Membership_Type__c = memType.Id
        );
        
        List<Staff_Availability_Schedule__c> lstSchedules = TestDataFactory.createAvailabilityForConsecutiveDays(
            staff, 
            Date.today(), 
            Time.newInstance(9, 0, 0, 0), 
            Time.newInstance(15, 0, 0, 0), 
            memType.TREX1__Location__c, 
            5
        );
        insert lstSchedules;
        
        Test.startTest();
        List<StaffAvailabilityWrapper> lstWrappers = new List<StaffAvailabilityWrapper>();
        lstWrappers = CommunityPunchPassesController.getAssignedStaffAvailability(
            membership.Id
        );
        Test.stopTest();

        System.assert(
            !lstWrappers.isEmpty(), 
            'Should have returned a list of wrappers'
        );
        
    }
    
    @isTest
    static void testGetAppointmentsFromMembership() {
        // Create staff contact and staff record
        Contact ct = TestDataFactory.createContacts(1).get(0);
        insert ct;
        TREX1__Staff__c staff = TestDataFactory.createStaffFromContacts(
            new List<Contact>{ ct }
        ).get(0);
        insert staff;
        
        TREX1__Membership_Type__c memType = [
            SELECT Id, Appointment_Length__c, TREX1__Location__c
              FROM TREX1__Membership_Type__c
             LIMIT 1
        ];
        
        insert new Assigned_Staff__c(
            Staff__c = staff.Id, 
            Membership_Type__c = memType.Id
        );
        
        // Get membership
        TREX1__Membership__c membership = [
            SELECT Id, TREX1__Contact__c, TREX1__memb_Category__c, TREX1__memb_Type__c 
              FROM TREX1__Membership__c 
             WHERE TREX1__memb_Type__c = :memType.Id 
             LIMIT 1
        ];
        
        // Insert appointment
        Appointment__c appt = new Appointment__c();
        appt.Contact__c = membership.TREX1__Contact__c;
        appt.Staff__c = staff.Id;
        appt.Membership__c = membership.Id;
        appt.Membership_Category__c = membership.TREX1__memb_Category__c;
        appt.Membership_Type__c = membership.TREX1__memb_Type__c;
        appt.Status__c = 'Scheduled';
        appt.Start_DateTime__c = DateTime.now().addHours(1);
        appt.End_DateTime__c = DateTime.now().addHours(2);
        appt.Bypass_Staff_Auto_Emails__c = true;
        appt.Bypass_Customer_Auto_Emails__c = true;
        insert appt;
        
        Test.startTest();
        List<Appointment__c> lstAppts = CommunityPunchPassesController.getAppointmentsFromMembership(
            membership
        );
        Test.stopTest();
        
        System.assertEquals(
            appt.Id, 
            lstAppts[0].Id, 
            'Should have returned the appointment for this membership'
        );
        
    }
    
    @isTest
    static void testGetAppointmentsByContactAndCategory() {
        // Get membership category id from membership type
        TREX1__Membership_Type__c memType = [
            SELECT TREX1__Category__c
              FROM TREX1__Membership_Type__c
             LIMIT 1
        ];
        
        // Get contact id from a valid membership
        TREX1__Membership__c membership = [
            SELECT TREX1__Contact__c
              FROM TREX1__Membership__c 
             WHERE TREX1__memb_Type__c = :memType.Id 
             LIMIT 1
        ];
        
        Test.startTest();
        List<Appointment__c> lstAppointments = new List<Appointment__c>(); 
        lstAppointments = CommunityPunchPassesController.getAppointmentsByContactAndCategory(
            memType.TREX1__Category__c, 
            membership.TREX1__Contact__c
        );
        Test.stopTest();
        
        List<Appointment__c> lstAppointmentsToVerify = [
            SELECT Id
              FROM Appointment__c
             WHERE Contact__c = :membership.TREX1__Contact__c
               AND Membership_Category__c = :memType.TREX1__Category__c
        ];
        
        System.assertEquals(
            lstAppointmentsToVerify.size(), 
            lstAppointments.size(), 
            'Received incorrect amount of appointments for contact and category'
        );
        
    }

    @isTest
    static void testCreateRecord() {
        String accountName = 'New York Metropolitan Baseball Club';
        Account acc = new Account(Name = accountName);
        Test.startTest();
        Account createdAccount = (Account) CommunityPunchPassesController.createRecord(acc);
        Test.stopTest();
        System.assertNotEquals(null, createdAccount.Id, 'The new account should have a record id');
        System.assertEquals(accountName, createdAccount.Name, 'Should have received created record with provided name');
    }

    @isTest
    static void testUpdateRecord() {
        String accountName = 'New York Metropolitan Baseball Club';
        String newAccountName = 'New York Mets';
        insert new Account(Name = accountName);
        Account accToUpdate = [SELECT Id, Name FROM Account WHERE Name = :accountName LIMIT 1];
        Test.startTest();
        accToUpdate.Name = newAccountName;
        CommunityPunchPassesController.updateRecord(accToUpdate);
        Test.stopTest();
        Account updatedAccount = [SELECT Id, Name FROM Account WHERE Id = :accToUpdate.Id LIMIT 1];
        System.assertEquals(newAccountName, updatedAccount.Name, 'Should have received updated record with new account name');
    }
    
    @isTest
    static void testCreateRecordWithException() {
        Boolean hasException = false;
        Contact ct = new Contact(Email='onlyanemail@noinfo.com');
        Test.startTest();
        try {
            Contact createdContact = (Contact) CommunityPunchPassesController.createRecord(ct);
        } catch (Exception e) {
            hasException = true;
        }
        Test.stopTest();
        System.assert(hasException, 'Should have received required fields exception when attempting to insert contact');
    }
    
    @isTest
    static void testUpdateRecordWithException() {
        Boolean hasException = false;
        String accountName = 'New York Metropolitan Baseball Club';
        insert new Account(Name = accountName);
        Account accToUpdate = [SELECT Id, Name FROM Account WHERE Name = :accountName LIMIT 1];
        Test.startTest();
        accToUpdate.Name = null;
        try {
            CommunityPunchPassesController.updateRecord(accToUpdate);
        } catch (Exception e) {
            hasException = true;
        }
        Test.stopTest();
        System.assert(hasException, 'Should have received required fields exception when attempting to update account with no name');
    }

    @isTest
    static void testCreateAppointment() {
        // Create staff contact and staff record
        Contact ct = TestDataFactory.createContacts(1).get(0);
        insert ct;
        TREX1__Staff__c staff = TestDataFactory.createStaffFromContacts(
            new List<Contact>{ ct }
        ).get(0);
        insert staff;
        
        TREX1__Membership_Type__c memType = [
            SELECT Id, Appointment_Length__c, TREX1__Location__c
              FROM TREX1__Membership_Type__c
             LIMIT 1
        ];
        
        insert new Assigned_Staff__c(
            Staff__c = staff.Id, 
            Membership_Type__c = memType.Id
        );
        
        // Get membership
        TREX1__Membership__c membership = [
            SELECT Id, TREX1__Contact__c, TREX1__memb_Category__c, TREX1__memb_Type__c 
              FROM TREX1__Membership__c 
             WHERE TREX1__memb_Type__c = :memType.Id 
             LIMIT 1
        ];
        
        // Create appointment sobject
        Appointment__c appt = new Appointment__c();
        appt.Contact__c = membership.TREX1__Contact__c;
        appt.Staff__c = staff.Id;
        appt.Membership__c = membership.Id;
        appt.Status__c = 'Scheduled';
        appt.Start_DateTime__c = DateTime.now().addHours(1);
        appt.End_DateTime__c = DateTime.now().addHours(2);
        appt.Bypass_Staff_Auto_Emails__c = true;
        appt.Bypass_Customer_Auto_Emails__c = true;

        Test.startTest();
        SObject obj = CommunityPunchPassesController.createRecord(appt);
        Test.stopTest();

        System.assertNotEquals(null, obj.Id, 'New appointment should have an id');
    }

    @isTest
    static void testUpdateAppointment() {
        // Create staff contact and staff record
        Contact ct = TestDataFactory.createContacts(1).get(0);
        insert ct;
        TREX1__Staff__c staff = TestDataFactory.createStaffFromContacts(
            new List<Contact>{ ct }
        ).get(0);
        insert staff;
        
        TREX1__Membership_Type__c memType = [
            SELECT Id, Appointment_Length__c, TREX1__Location__c
              FROM TREX1__Membership_Type__c
             LIMIT 1
        ];
        
        insert new Assigned_Staff__c(
            Staff__c = staff.Id, 
            Membership_Type__c = memType.Id
        );
        
        // Get membership
        TREX1__Membership__c membership = [
            SELECT Id, TREX1__Contact__c, TREX1__memb_Category__c, TREX1__memb_Type__c 
              FROM TREX1__Membership__c 
             WHERE TREX1__memb_Type__c = :memType.Id 
             LIMIT 1
        ];
        
        // Insert appointment
        Appointment__c appt = new Appointment__c();
        appt.Contact__c = membership.TREX1__Contact__c;
        appt.Staff__c = staff.Id;
        appt.Membership__c = membership.Id;
        appt.Status__c = 'Scheduled';
        appt.Start_DateTime__c = DateTime.now().addHours(1);
        appt.End_DateTime__c = DateTime.now().addHours(2);
        appt.Bypass_Staff_Auto_Emails__c = true;
        appt.Bypass_Customer_Auto_Emails__c = true;
        insert appt;

        Test.startTest();
        // Update to canceled values
        Appointment__c apptToCancel = new Appointment__c();
        apptToCancel.Id = appt.Id;
        apptToCancel.Status__c = 'Cancelled';
        apptToCancel.Cancellation_Date__c = Date.today();
        
        CommunityPunchPassesController.updateRecord(apptToCancel);
        Test.stopTest();

        Appointment__c apptRefreshed = [
            SELECT Id, Status__c, Cancellation_Date__c FROM Appointment__c WHERE Id = :appt.Id LIMIT 1
        ];

        System.assertEquals(
            'Cancelled', 
            apptRefreshed.Status__c, 
            'Appointment should have a cancelled status'
        );
        System.assertEquals(
            apptToCancel.Cancellation_Date__c, 
            apptRefreshed.Cancellation_Date__c, 
            'Appointment should have a cancellation date of today'
        );

    }

}