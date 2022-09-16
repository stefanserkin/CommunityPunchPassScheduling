@isTest
private class CommunityPunchPassesHelper_Test {
    
    @isTest
    static void testGetListOfCategoriesFromString() {
        String strInput = 'Pilates,Personal Training,Baseball Private Lessons';
        List<String> lstStrings = CommunityPunchPassesHelper.getListOfCategoriesFromString(strInput);
        System.assert(lstStrings.contains('Pilates'), 'List should contain Pilates');
        System.assert(lstStrings.contains('Personal Training'), 'List should contain Personal Training');
        System.assert(lstStrings.contains('Baseball Private Lessons'), 'List should contain Baseball Private Lessons');
    }
    
    @isTest
    static void testGetListOfCategoriesFromNull() {
        String strInput;
        List<String> lstStrings = CommunityPunchPassesHelper.getListOfCategoriesFromString(strInput);
        System.assert(lstStrings.isEmpty(), 'List should be empty');
    }
    
}