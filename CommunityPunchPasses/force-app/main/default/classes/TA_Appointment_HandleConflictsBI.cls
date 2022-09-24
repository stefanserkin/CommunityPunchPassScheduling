public with sharing class TA_Appointment_HandleConflictsBI implements TriggerAction.BeforeInsert {
    
    // Static variable of staff in trigger with all scheduled appointments
    private static Map<Id, List<Appointment__c>> mapStaffIdToScheduledAppointments;

    /**********************************************************
     * Called by metadata trigger handler
     * Manage from sObject Trigger Settings mdt: Appointment
     * Simply marks the record as a conflict, leaving the admin free
     * to enforce with a validation rule or allow conflicts
     ***********************************************************/

    public void beforeInsert(List<Appointment__c> newList) {
        mapStaffIdToScheduledAppointments = TA_Appointment_QueriesBI.getInstance().mapStaffIdToScheduledAppointments;

        for (Appointment__c newAppt : newList) {
            List<Appointment__c> lstPotentialConflicts = mapStaffIdToScheduledAppointments.get(
                newAppt.Staff__c
            );
            for (Appointment__c potentialConflict : lstPotentialConflicts) {
                if (
                    potentialConflict.Start_DateTime__c < newAppt.End_DateTime__c && 
                    potentialConflict.End_DateTime__c > newAppt.Start_DateTime__c
                ) {
                    newAppt.Is_Conflict__c = true;
                }
            }
        }

    }
    
}
