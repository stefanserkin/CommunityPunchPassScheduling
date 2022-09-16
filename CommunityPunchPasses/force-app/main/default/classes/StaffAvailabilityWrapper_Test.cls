@isTest
private class StaffAvailabilityWrapper_Test {
    
    private static final Id STAFF_ID = TestUtility.getFakeId(TREX1__Staff__c.SObjectType);
    private static final String STAFF_NAME = 'Rey Ordonez';
    
    @isTest
    static void testWrapperInstantiation() {
        // Create wrapper with staff details to return
        StaffAvailabilityWrapper staffWrapper = new StaffAvailabilityWrapper();
        staffWrapper.staffId = STAFF_ID;
        staffWrapper.staffName = STAFF_NAME;
        staffWrapper.availabilityDate = Date.today().addDays(1);
        
        // Create new list of inner class
        staffWrapper.availabilitySlots = new List<StaffAvailabilityWrapper.AvailabilitySlot>();
        
        // Add slot
        StaffAvailabilityWrapper.AvailabilitySlot slot;
        slot = new StaffAvailabilityWrapper.AvailabilitySlot();
        slot.startTime = DateTime.newInstance(staffWrapper.availabilityDate, Time.newInstance(9, 0, 0, 0));
        slot.endTime = DateTime.newInstance(staffWrapper.availabilityDate, Time.newInstance(10, 0, 0, 0));
        
        staffWrapper.availabilitySlots.add( slot );
        
        System.assertEquals(
            1, 
            staffWrapper.availabilitySlots.size(), 
            'Should have received one slot'
        );
        
    }
    
}