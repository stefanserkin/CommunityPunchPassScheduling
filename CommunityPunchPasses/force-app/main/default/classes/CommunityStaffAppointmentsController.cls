public without sharing class CommunityStaffAppointmentsController {

    @testVisible 
    private static final String STATUS_CANCELLED = 'Cancelled';
    
    @AuraEnabled(cacheable=true)
    public static List<Appointment__c> getStaffAppointments(
        String userId
    ) {
        List<TREX1__Staff__c> lstStaff = [
            SELECT Id, Name, 
                   (SELECT Id, Name, Contact__c, Contact__r.Name, Status__c, Attended__c, 
                           Start_DateTime__c, End_DateTime__c, Cancellation_Date__c,
                           Bypass_Auto_Decrement__c, Membership__r.TREX1__Type__c, 
                           Membership__r.TREX1__Remaining_Value__c
                      FROM Appointments__r
                     ORDER BY Start_DateTime__c ASC
                     LIMIT 10000) 
              FROM TREX1__Staff__c 
             WHERE Contact__c IN (SELECT ContactId 
                                    FROM User 
                                   WHERE Id = :userId)
        ];
        return lstStaff[0].Appointments__r != null ? lstStaff[0].Appointments__r : new List<Appointment__c>();
    }

    @AuraEnabled
    public static List<String> checkInAppointments(
        List<Appointment__c> lstAppointments
    ){
        List<String> lstFailedCheckinIds = new List<String>();
        List<Appointment__c> lstAppointmentsToUpdate = new List<Appointment__c>();

        for (Appointment__c appt : lstAppointments) {
            // No action to take on already attended appointments
            if (appt.Attended__c) {
                lstFailedCheckinIds.add(appt.Id);
                continue;
            }
            // Guard against empty memberships - decrement will fail
            if (appt.Membership__r.TREX1__Remaining_Value__c <= 0) {
                appt.Bypass_Auto_Decrement__c = true;
                lstFailedCheckinIds.add(appt.Id);
            }

            appt.Attended__c = true;
            lstAppointmentsToUpdate.add(appt);

        }

        try {
            update lstAppointmentsToUpdate;
        } catch(Exception e) {
            System.debug('error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }

        return lstFailedCheckinIds;
        
    }

    @AuraEnabled
    public static void cancelAppointments(
        List<Appointment__c> lstAppointments
    ) {
        for (Appointment__c appt : lstAppointments) {
            appt.Status__c = STATUS_CANCELLED;
            appt.Cancellation_Date__c = Date.today();
        }
        try {
            update lstAppointments;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}