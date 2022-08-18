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
