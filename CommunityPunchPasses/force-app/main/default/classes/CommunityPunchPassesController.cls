public without sharing class CommunityPunchPassesController {

    @testVisible private static final String PUNCH_PASS_RECORDTYPE_NAME = 'Punch_Pass_Membership';
    @testVisible private static final String MEMBERSHIP_STATUS_COMPLETE = 'Complete';
    @testVisible private static final String NO_DECREMENT_HISTORY_MESSAGE = 'No Usage History';
    @testVisible private static final String DATETIME_FORMAT = 'MMMMM dd, yyyy h:mm a';

    private static String userTimeZone = String.valueOf(UserInfo.getTimeZone());

    @AuraEnabled(cacheable=true)
    public static List<TREX1__Staff__c> getAssignedStaff(
        String membershipTypeId
    ) {
        List<TREX1__Staff__c> lstStaff = [
            SELECT Id, Name, 
                   (SELECT Id, Name, Date__c, 
                           Start_Time__c, End_Time__c, 
                           Start_Time_2__c, End_Time_2__c 
                      FROM Staff_Availability_Schedules__r),
                   (SELECT Id, Name, Start_DateTime__c, End_DateTime__c 
                      FROM Scheduled_Appointments__r
                     WHERE Start_DateTime__c >= TODAY
                       AND Status__c NOT IN ('Draft','Cancelled'))
              FROM TREX1__Staff__c 
             WHERE Id IN (SELECT Staff__c 
                            FROM Assigned_Staff__c 
                           WHERE Membership_Type__c = :membershipTypeId)
        ];
        return lstStaff;
    }

    @AuraEnabled
    public static List<String> getPassDecrements(
        String membershipId
    ) {
        List<String> lstResults = new List<String>();
        List<TREX1__Pass_Decrement__c> lstDecrements = [
            SELECT Id, TREX1__Date__c, TREX1__Value__c
              FROM TREX1__Pass_Decrement__c
             WHERE TREX1__Membership_Punch_Pass_Decrement__c = :membershipId
              WITH SECURITY_ENFORCED
             ORDER BY TREX1__Date__c ASC
             LIMIT 10000
        ];
        if (!lstDecrements.isEmpty()) {
            for (TREX1__Pass_Decrement__c dec : lstDecrements) {
                String result = String.valueOf(dec.TREX1__Value__c) + ' used on ';
                result += dec.TREX1__Date__c.format(
                    DATETIME_FORMAT, 
                    userTimeZone
                );
                lstResults.add(result);
            }
        } else if (lstDecrements.isEmpty()) {
            lstResults.add(
                NO_DECREMENT_HISTORY_MESSAGE
            );
        }
        return lstResults;
    }

    @AuraEnabled
    public static string getTransactionReceiptId(
        String transactionId
    ) {
        Attachment receipt = [
            SELECT Id 
              FROM Attachment 
             WHERE ParentId = :transactionId 
               AND Name LIKE 'Receipt%' 
              WITH SECURITY_ENFORCED 
             LIMIT 1
        ];
        return receipt.Id;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> getActivePunchPassesByContact(
        String accountId,
        String strMembershipCategoryNames,
        String strRowTargetUrlField
    ) {
        List<Contact> lstContacts = new List<Contact>();
        List<String> lstMembershipCategoryNames = getListOfCategoriesFromString(
            strMembershipCategoryNames
        );
        String strQuery = 'SELECT Id, FirstName, LastName, ';
        strQuery += '(SELECT Id, Name, TREX1__Contact__c, TREX1__Contact__r.Name, TREX1__Contact__r.FirstName, TREX1__memb_Type__c, TREX1__memb_Type__r.Name, TREX1__Type__c, TREX1__Category_Name__c, TREX1__Status__c, TREX1__Account__r.Name, TREX1__Start_Date__c, TREX1__End_Date__c, TREX1__Purchasing_Transaction__c, TREX1__Remaining_Value__c, TREX1__Stored_Value__c, TREX1__Total_Value__c, CreatedDate';
        if (!String.isBlank(strRowTargetUrlField)) {
            strQuery += ', ' + String.escapeSingleQuotes(strRowTargetUrlField) + ' ';
        }
        strQuery += ' FROM TREX1__Memberships__r WHERE RecordType.DeveloperName = :PUNCH_PASS_RECORDTYPE_NAME' + 
            ' AND TREX1__Category_Name__c IN :lstMembershipCategoryNames' + 
            ' AND TREX1__Remaining_Value__c > 0 AND TREX1__Status__c != :MEMBERSHIP_STATUS_COMPLETE' + 
            ' AND (TREX1__End_Date__c >= TODAY OR TREX1__End_Date__c = NULL) ORDER BY TREX1__End_Date__c ASC NULLS LAST)' + 
            ' FROM Contact WHERE AccountId = :accountId' + 
            ' AND Id IN (SELECT TREX1__Contact__c FROM TREX1__Membership__c WHERE RecordType.DeveloperName = :PUNCH_PASS_RECORDTYPE_NAME' + 
            ' AND TREX1__Category_Name__c IN :lstMembershipCategoryNames' + 
            ' AND TREX1__Remaining_Value__c > 0 AND TREX1__Status__c != :MEMBERSHIP_STATUS_COMPLETE)' + 
            ' WITH SECURITY_ENFORCED ORDER BY FirstName ASC LIMIT 10000';
        lstContacts = Database.query(String.escapeSingleQuotes(strQuery));

        return lstContacts;

    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> getCompletedPunchPassesByContact(
        String accountId,
        String strMembershipCategoryNames
    ) {
        List<String> lstMembershipCategoryNames = getListOfCategoriesFromString(
            strMembershipCategoryNames
        );

        return [
            SELECT Id, FirstName, LastName, 
                   (SELECT Id, Name, TREX1__Contact__c, TREX1__Contact__r.Name, TREX1__Contact__r.FirstName,
                           TREX1__memb_Type__r.Name, TREX1__Type__c, TREX1__Category_Name__c, TREX1__Status__c,
                           TREX1__Account__r.Name, TREX1__Start_Date__c, TREX1__End_Date__c, TREX1__Purchasing_Transaction__c,
                           TREX1__Remaining_Value__c, TREX1__Stored_Value__c, TREX1__Total_Value__c, CreatedDate
                      FROM TREX1__Memberships__r
                     WHERE RecordType.DeveloperName = :PUNCH_PASS_RECORDTYPE_NAME
                       AND TREX1__Category_Name__c IN :lstMembershipCategoryNames
                       AND ((TREX1__Stored_Value__c > 0 
                           AND TREX1__Remaining_Value__c = 0)
                        OR TREX1__Status__c = :MEMBERSHIP_STATUS_COMPLETE)
                     ORDER BY TREX1__End_Date__c ASC NULLS LAST)
              FROM Contact
             WHERE AccountId = :accountId
               AND Id IN (SELECT TREX1__Contact__c
                            FROM TREX1__Membership__c
                           WHERE RecordType.DeveloperName = :PUNCH_PASS_RECORDTYPE_NAME
                             AND TREX1__Category_Name__c IN :lstMembershipCategoryNames
                             AND ((TREX1__Stored_Value__c > 0 
                                 AND TREX1__Remaining_Value__c = 0)
                              OR TREX1__Status__c = :MEMBERSHIP_STATUS_COMPLETE))
              WITH SECURITY_ENFORCED
             ORDER BY FirstName ASC
             LIMIT 10000
        ];
    }

    private static List<String> getListOfCategoriesFromString(
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


}