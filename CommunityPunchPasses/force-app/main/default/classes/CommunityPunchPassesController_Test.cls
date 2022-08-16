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

        List<TREX1__Membership__c> lstMemberships = new List<TREX1__Membership__c>();
        // Completed membership
        lstMemberships.add(
            new TREX1__Membership__c(
                TREX1__Contact__c = lstContacts.get(0).Id, 
                TREX1__Account__c = acc.Id, 
                RecordTypeId = punchPassRecTypeId, 
                TREX1__Status__c = STATUS_COMPLETE,
                TREX1__Category_Name__c = VALID_MEMBERSHIP_CATEGORY,
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
                    TREX1__Category_Name__c = VALID_MEMBERSHIP_CATEGORY,
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
    static void testQueryForActivePunchPasses() {
        
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Contact> lstCtsWithActiveMems = new List<Contact>();
        lstCtsWithActiveMems = CommunityPunchPassesController.getActivePunchPassesByContact(
            acc.Id,
            VALID_MEMBERSHIP_CATEGORY,
            URL_FIELD_NAME
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
            'Complete', 
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
            null,
            URL_FIELD_NAME
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

}