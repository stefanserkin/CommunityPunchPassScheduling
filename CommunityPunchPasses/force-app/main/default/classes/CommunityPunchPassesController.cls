public without sharing class CommunityPunchPassesController {

    @testVisible private static final String PUNCH_PASS_RECORDTYPE_NAME = 'Punch_Pass_Membership';
    @testVisible private static final String MEMBERSHIP_STATUS_COMPLETE = 'Complete';
    @testVisible private static final String NO_DECREMENT_HISTORY_MESSAGE = 'No Usage History';
    @testVisible private static final String DATETIME_FORMAT = 'MMMMM dd, yyyy h:mm a';

    private static String userTimeZone = String.valueOf(UserInfo.getTimeZone());

    /**********************************
     * Get list of staff with availability wrappers, based on the location and 
     *   appointment length of a membership type
     * @param String membership type id
     * @param String location id
     * @param Integer length of appointment in minutes
     * @return List<StaffAvailabilityWrapper> list of staff with availability slots
     ***********************************/

    @AuraEnabled(cacheable=true)
    public static List<StaffAvailabilityWrapper> getAssignedStaffAvailability(
        String membershipTypeId, 
        String locationId, 
        Integer appointmentLength
    ) {
        // Create list of wrappers
        List<StaffAvailabilityWrapper> lstWrappers = new List<StaffAvailabilityWrapper>();

        // Query for staff with upcoming availability and appts
        List<TREX1__Staff__c> lstStaff = getAssignedStaff(
            membershipTypeId, 
            locationId
        );

        // Remove appointments from available times and
        // return wrapper of staff with availability
        for (TREX1__Staff__c staff : lstStaff) {
            StaffAvailabilityWrapper saw = new StaffAvailabilityWrapper();
            saw = StaffAvailabilityWrapperService.getWrapperFromStaff(
                staff, 
                appointmentLength
            );
            lstWrappers.add(saw);
        }

        return lstWrappers;

    }

    /**********************************
     * Query for assigned staff with upcoming availability and appointments
     * @param String membership type id
     * @param String location id
     * @return List<TREX1__Staff__c> list of staff with availabiilty and appointments
     ***********************************/

    @AuraEnabled(cacheable=true)
    public static List<TREX1__Staff__c> getAssignedStaff(
        String membershipTypeId, 
        String locationId
    ) {
        Datetime dtNow = System.now();
        List<TREX1__Staff__c> lstStaff = [
            SELECT Id, Name, 
                   (SELECT Id, Name, Date__c, Location__c, 
                           Start_Time__c, End_Time__c, Date_Only__c, 
                           Start_DateTime__c, End_DateTime__c
                      FROM Staff_Availability_Schedules__r
                     WHERE Start_DateTime__c >= :dtNow
                       AND Location__c = :locationId
                     ORDER BY Start_DateTime__c ASC),
                   (SELECT Id, Name, Start_DateTime__c, End_DateTime__c 
                      FROM Appointments__r
                     WHERE Start_DateTime__c >= :dtNow
                       AND Status__c NOT IN ('Draft','Cancelled')
                     ORDER BY Start_DateTime__c ASC)
              FROM TREX1__Staff__c 
             WHERE Id IN (SELECT Staff__c 
                            FROM Assigned_Staff__c 
                           WHERE Membership_Type__c = :membershipTypeId)
        ];
        return lstStaff;
    }

    /**********************************
     * Query for pass decrements related to a given membership id
     *   Returned as strings to pre-format results
     * @param String membership id
     * @return String[] list of formatted dates and times of decrements
     ***********************************/

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

    /**********************************
     * Query for appointments related to a given membership id
     *   Returned as strings to pre-format results
     * @param TREX1__Membership__c membership id
     * @return List<Appointment__c> list of appointments
     ***********************************/

    @AuraEnabled(cacheable=true)
    public static List<Appointment__c> getAppointmentsFromMembership(
        TREX1__Membership__c membership
    ) {
        return [
            SELECT Id, Name, Start_DateTime__c, End_DateTime__c, 
                   Status__c, Attended__c, Staff__c, Staff__r.Name
              FROM Appointment__c
             WHERE Membership__c = :membership.Id
               AND Status__c != 'Draft'
             ORDER BY Start_DateTime__c DESC
             LIMIT 10000
        ];
    }


    /**********************************
     * Query for receipt attachment id for a given transaction id
     *   Returns only id to be merged into a content display url
     * @param String transaction id
     * @return String receipt attachment id
     ***********************************/

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

    /**********************************
     * Query for all contacts in the household with active punch pass memberships
     *   Originally constructed dynamically to prevent exceptions if no target url field is defined
     *   in the community component's design time attributes. No longer necessary.
     * @param String account id
     * @param String membership category names - comma-separated
     * @return Contact[] list of contacts with active punch pass memberships
     ***********************************/

    @AuraEnabled(cacheable=true)
    public static List<Contact> getActivePunchPassesByContact(
        String accountId,
        String strMembershipCategoryNames
    ) {
        List<Contact> lstContacts = new List<Contact>();
        List<String> lstMembershipCategoryNames = CommunityPunchPassesHelper.getListOfCategoriesFromString(
            strMembershipCategoryNames
        );
        String strQuery = 'SELECT Id, FirstName, LastName, ';
        strQuery += '(SELECT Id, Name, TREX1__Contact__c, TREX1__Contact__r.Name, TREX1__Contact__r.FirstName, TREX1__memb_Type__c, TREX1__memb_Type__r.Name, TREX1__Type__c, TREX1__memb_Type__r.TREX1__Location__c, TREX1__memb_Type__r.Appointment_Length__c, TREX1__Category_Name__c, TREX1__Status__c, TREX1__Account__r.Name, TREX1__Start_Date__c, TREX1__End_Date__c, TREX1__Purchasing_Transaction__c, TREX1__Remaining_Value__c, TREX1__Stored_Value__c, TREX1__Total_Value__c, Effectively_Used_Credits__c, Bookable_Credits__c, CreatedDate';
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

    /**********************************
     * Query for all contacts in the household with completed punch pass memberships
     *   No need for dynamic query, since completed membership can't be scheduled
     * @param String account id
     * @param String membership category names - comma-separated
     * @return Contact[] list of contacts with completed punch pass memberships
     ***********************************/

    @AuraEnabled(cacheable=true)
    public static List<Contact> getCompletedPunchPassesByContact(
        String accountId,
        String strMembershipCategoryNames
    ) {
        List<String> lstMembershipCategoryNames = CommunityPunchPassesHelper.getListOfCategoriesFromString(
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

}