/*************************************************
 * @description This wrapper contains a staff id, staff name, and a list of availability slots,
 * intended for the community punch pass component to display available times based on a selected
 * staff member/instructor.
 * Each availability slot contains a start and end datetime property. A selected slot would define 
 * the start and end time of the booked appointment.
 *************************************************/

public class StaffAvailabilityWrapper {
    @AuraEnabled
    public String staffId;
    @AuraEnabled
    public String staffName;
    @AuraEnabled
    public AvailabilitySlot[] availabilitySlots;

    public class AvailabilitySlot {
        @AuraEnabled
        public Datetime startTime;
        @AuraEnabled
        public Datetime endTime;
    }
}