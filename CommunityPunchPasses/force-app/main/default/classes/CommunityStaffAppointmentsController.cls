public without sharing class CommunityStaffAppointmentsController {

    @testVisible 
    private static final String STATUS_CANCELLED = 'Cancelled';
    
    @AuraEnabled(cacheable=true)
    public static List<AppointmentWrapper> getStaffAppointments(
        String userId
    ) {
        List<AppointmentWrapper> lstWrappers = new List<AppointmentWrapper>();
        List<TREX1__Staff__c> lstStaff = [
            SELECT Id, Name, 
                   (SELECT Id, Name, Contact__c, Contact__r.Name, Status__c, Attended__c, 
                           Start_DateTime__c, End_DateTime__c, Cancellation_Date__c, 
                           Bypass_Auto_Decrement__c, Membership_Category__r.Name,
                           Membership_Type__c, Membership_Type__r.Name, 
                           Transaction_Contact__c, Transaction_Contact__r.Name, 
                           Transaction_Contact__r.Email, Transaction_Contact__r.Phone
                      FROM Appointments__r
                     ORDER BY Start_DateTime__c ASC
                     LIMIT 10000) 
              FROM TREX1__Staff__c 
             WHERE Contact__c IN (SELECT ContactId 
                                    FROM User 
                                   WHERE Id = :userId)
        ];
        for (TREX1__Staff__c staff : lstStaff) {
            for (Appointment__c app : staff.Appointments__r) {
                AppointmentWrapper wrapper = new AppointmentWrapper(app);
                lstWrappers.add(wrapper);
            }
        }
        return lstWrappers;
    }

    @AuraEnabled
    public static List<String> checkInAppointments(
        List<String> lstAppointmentIds
    ){
        List<String> lstFailedCheckinIds = new List<String>();
        List<Appointment__c> lstAppointmentsToUpdate = [
            SELECT Id, Attended__c, Membership__r.TREX1__Remaining_Value__c, Bypass_Auto_Decrement__c
              FROM Appointment__c
             WHERE Id IN :lstAppointmentIds
        ];

        for (Appointment__c appt : lstAppointmentsToUpdate) {
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

        }

        try {
            update lstAppointmentsToUpdate;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return lstFailedCheckinIds;
        
    }

    @AuraEnabled
    public static void cancelAppointments(
        List<String> lstAppointmentIds
    ) {
        List<Appointment__c> lstAppsToCancel = new List<Appointment__c>();
        for (String appId : lstAppointmentIds) {
            Appointment__c app = new Appointment__c();
            app.Id = appId;
            app.Status__c = STATUS_CANCELLED;
            app.Cancellation_Date__c = Date.today();
            lstAppsToCancel.add(app);
        }
        try {
            update lstAppsToCancel;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class AppointmentWrapper {
        @AuraEnabled
        public String id {get;set;}
        @AuraEnabled
        public String status {get;set;}
        @AuraEnabled
        public Datetime startTime {get;set;}
        @AuraEnabled
        public String athlete {get;set;}
        @AuraEnabled
        public String primaryPhone {get;set;}
        @AuraEnabled
        public String primaryEmail {get;set;}
        @AuraEnabled
        public Boolean isAttended {get;set;}
        @AuraEnabled
        public String membershipCategory {get;set;}
        @AuraEnabled
        public String membershipType {get;set;}

        public AppointmentWrapper(Appointment__c app) {
            id = app.Id;
            status = app.Status__c;
            startTime = app.Start_DateTime__c;
            athlete = app.Contact__r.Name;
            primaryPhone = app.Transaction_Contact__r.Phone;
            primaryEmail = app.Transaction_Contact__r.Email;
            isAttended = app.Attended__c;
            membershipCategory = app.Membership_Category__r.Name;
            membershipType = app.Membership_Type__r.Name;
        }
    }

}