public inherited sharing class CommunityPunchPassesHelper {

    /**********************************
     * Get a list of of category names from a comma-separated string
     *   Provided in design-time attribute of community component
     * @param String string of comma-separated membership categories names
     * @return String[] list of membership category names
     ***********************************/

    public static List<String> getListOfCategoriesFromString(
        String strMembershipCategoryNames
    ) {
        List<String> lstFormattedCategoryNames = new List<String>();
        List<String> lstMembershipCategoryNames =
            strMembershipCategoryNames != null ?
            strMembershipCategoryNames.split(',') :
            new List<String>();
        for (String catName : lstMembershipCategoryNames) {
            catName = catName.trim();
            lstFormattedCategoryNames.add(catName);
        }
        return lstFormattedCategoryNames;
    }
    
}
