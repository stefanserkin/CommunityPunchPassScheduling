public without sharing class CommunityStaffAppointmentsController {
    
    @AuraEnabled(cacheable=true)
    public static List<TREX1__Staff__c> getUpcomingStaffAppointments(
        String userId
    ) {
        Datetime dtNow = System.now();
        return [
            SELECT Id, 
                   (SELECT Id, 
                           Name, 
                           Status__c, 
                           Attended__c, 
                           Start_DateTime__c, 
                           End_DateTime__c, 
                           Membership__r.TREX1__Type__c
                      FROM Appointments__r
                     WHERE Start_DateTime__c >= :dtNow
                     ORDER BY Start_DateTime__c ASC
                     LIMIT 10000) 
              FROM TREX1__Staff__c 
             WHERE Contact__c IN (SELECT ContactId 
                                    FROM User 
                                   WHERE Id = :userId)
        ];
    }

}
