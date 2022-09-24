public with sharing class TA_Appointment_QueriesBI {

    private static TA_Appointment_QueriesBI instance;
    private static final String STATUS_SCHEDULED = 'Scheduled';

    private TA_Appointment_QueriesBI() {}

    public static TA_Appointment_QueriesBI getInstance() {
        if (TA_Appointment_QueriesBI.instance == null) {
            TA_Appointment_QueriesBI.instance = new TA_Appointment_QueriesBI();
        }
        return TA_Appointment_QueriesBI.instance;
    }

    public Map<Id, List<Appointment__c>> mapStaffIdToScheduledAppointments { get; private set; }

    /*****************************************************
     * Called by metadata trigger handler
     * Manage from sObject Trigger Settings mdt: Appointment
     ******************************************************/

    public class Service implements TriggerAction.BeforeInsert {
        public void beforeInsert(List<Appointment__c> newList) {
            TA_Appointment_QueriesBI.getInstance().mapStaffIdToScheduledAppointments = getMapOfStaffAppointments(
                newList
            );
        }

        private Map<Id, List<Appointment__c>> getMapOfStaffAppointments(
            List<Appointment__c> newList
        ) {
            Map<Id, List<Appointment__c>> mapStaffIdToScheduledAppointments = new Map<Id, List<Appointment__c>>();

            Set<Id> setStaffIds = new Set<Id>();
            for (Appointment__c appt : newList) {
                setStaffIds.add( appt.Staff__c );
            }

            Map<Id, TREX1__Staff__c> mapStaffWithAppointments;
            mapStaffWithAppointments = new Map<Id, TREX1__Staff__c>([
                SELECT Id, Name, 
                       (SELECT Id, Start_DateTime__c, End_DateTime__c, 
                               Contact__c, Contact__r.FirstName, Contact__r.LastName
                          FROM Appointments__r 
                         WHERE Status__c = :STATUS_SCHEDULED)
                  FROM TREX1__Staff__c
                 WHERE Id IN :setStaffIds
                 LIMIT 2000
            ]);

            for (Appointment__c newAppt : newList) {
                mapStaffIdToScheduledAppointments.put(
                    mapStaffWithAppointments.get(newAppt.Staff__c).Id, 
                    mapStaffWithAppointments.get(newAppt.Staff__c).Appointments__r
                );
            }

            return mapStaffIdToScheduledAppointments;

        }
    }

}
