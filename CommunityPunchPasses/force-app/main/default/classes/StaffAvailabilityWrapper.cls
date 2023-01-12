/*************************************************
 * @description This wrapper contains a date, staff id, name, and a list of availability slots,
 * intended for the community punch pass component to display available times based on a selected
 * staff member/instructor.
 * Each availability slot contains a start and end datetime property. A selected slot would define 
 * the start and end time of the booked appointment.
 *************************************************/

public class StaffAvailabilityWrapper {
    /**
     * The date of this availability
     */
    @AuraEnabled
    public Date availabilityDate;

    /**
     * The record id of the staff member
     * TREX1__Staff__c object
     */
    @AuraEnabled
    public String staffId;

    /**
     * The full name of the available staff member
     */
    @AuraEnabled
    public String staffName;

    /**
     * A list of available times for the given date
     */
    @AuraEnabled
    public AvailabilitySlot[] availabilitySlots;

    /**
     * A single slot of availability with a start and end time
     */
    public class AvailabilitySlot {
        // Start time
        @AuraEnabled
        public Datetime startTime;

        // End time
        @AuraEnabled
        public Datetime endTime;
    }

}