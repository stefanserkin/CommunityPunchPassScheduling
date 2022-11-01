@isTest
public class TestDataFactory {
    
    /***********************************
     * Static Variables
     ***********************************/    

    private static Id householdRecordTypeId;
    private static Id organizationRecordTypeId;
    private static Id standardRateRTId;
    private static Id incrementalRateRTId;
    private static Id rentalContractRentalRTId;
    private static Id facilityBookingRTId;
    private static Id standardTransactionRecTypeId;
    private static Id punchPassRecTypeId;
    private static Id membershipTypePunchPassRecTypeId;
    private static Id membershipCategoryPunchPassRecTypeId;
    
    /***********************************
     * Constants
     ***********************************/

    // Accounts
	private static final String ACCOUNT_BASE_NAME = 'Wright Household';
    private static final String ORGANIZATION_BASE_NAME = 'Big Corp';
    // Affiliations
    private static final String AFFILIATION_STATUS_CURRENT = 'Current';
    private static final String AFFILIATION_STATUS_FORMER = 'Former';
    // Availability Profiles
    private static final String AVAILABILITY_PROFILE_BASE_NAME = 'Test Default';
    private static final String AVAILABILITY_PROFILE_DAILY_HOURS = '12:00am-11:59pm';
    // Bookings
    private static final Integer BOOKING_SETUP_TIME_REQUIRED = 0;
    private static final Integer BOOKING_TEAR_DOWN_TIME_REQUIRED = 0;
    private static final String BOOKING_STATUS = 'Draft';
    private static final String BOOKING_RATE_DETAILS = '';
    private static final Decimal BOOKING_RATE = 0;
    private static final String BOOKING_EVENT_NAME = 'Test Rental';
    private static final String RENTAL_BOOKING_TYPE = 'Rental';
    private static final String ADMIN_BOOKING_TYPE = 'Administrative';
    private static final String CALCULATION_MODE_AUTOMATIC = 'Automatic';
    // Community Programs (pmdm)
    private static final String COMMUNITY_PROGRAM_BASE_NAME = 'Test Program';
    private static final String COMMUNITY_PROGRAM_STATUS_ACTIVE = 'Active';
    // Contacts
    private static final String CONTACT_BASE_FIRST_NAME = 'David';
    private static final String CONTACT_BASE_MIDDLE_NAME = 'Captain';
    private static final String CONTACT_BASE_LAST_NAME = 'Wright';
    private static final Date CONTACT_BASE_BIRTHDATE = Date.today().addYears(-21);
    // Facilities
    private static final String FACILITY_BASE_NAME = 'Test Facility';
    private static final String FACILITY_TYPE = 'Gym';
    // Functions
    private static final String FUNCTION_BASE_NAME = 'Test Function';
    private static final String BCO_BASE_NAME = 'Test BCO';
    // Groups
    private static final String PUBLIC_GROUP_NAME = 'Test Group Test';
    private static final String GROUP_TYPE_REGULAR = 'Regular';
    // Locations
    private static final String LOCATION_BASE_NAME = 'Flushing';
    // Memberships
    private static final String VALID_MEMBERSHIP_CATEGORY = 'Pilates';
    private static final String MEMBERSHIP_STATUS_ACTIVE = 'Active';
    private static final String MEMBERSHIP_STATUS_COMPLETE = 'Complete';
    // Membership Categories
    private static final String MEMBERSHIP_CATEGORY_BASE_NAME = 'Test Membership Category';
    // Programs
    private static final String PROGRAM_BASE_NAME = 'Test Program';
    // Rental Contracts
    private static final String RENTAL_CONTRACT_PAYMENT_OPTION = 'On Transaction Firm';
    private static final String RENTAL_CONTRACT_STATUS = 'Draft';
    // Rental Rates
    private static final String RENTAL_RATE_BASE_NAME = 'Test Rental Rate';
    private static final String INCREMENTAL_RATE_RT_NAME = RentalRateUtilities.INCREMENTAL_RECORD_TYPE_NAME;
    private static final String STANDARD_RATE_RT_NAME = RentalRateUtilities.STANDARD_RECORD_TYPE_NAME;
    // Rules
    private static final String RULE_BASE_NAME = 'Test Rule';
    // Scheduled Rules
    private static final String SCHEDULED_RULE_BASE_NAME = 'Test Scheduled Rule';
    private static final String SCHEDULED_RULE_DESCRIPTION = 'A scheduled rule for testing';
    // Services (pmdm)
    private static final String SERVICE_BASE_NAME = 'Test Service';
    private static final String SERVICE_STATUS_ACTIVE = 'Active';
    private static final String SERVICE_ATTENDANCE_FIELD_SET = 'Attendance_Service_Deliveries';
    private static final String SERVICE_BULK_DELIVERY_FIELD_SET = 'Bulk_Service_Deliveries';
    private static final String SERVICE_UNIT_OF_MEASUREMENT = 'Hours';
    // Service Schedules (pmdm)
    private static final String SERVICE_SCHEDULE_BASE_NAME = 'Test Schedule';
    private static final Integer SERVICE_SCHEDULE_DEFAULT_SERVICE_QUANTITY = 1;
    // Service Participants (pmdm)
    private static final String SERVICE_PARTICIPANT_STATUS_ENROLLED = 'Enrolled';
    // Staff
    private static final String STAFF_NAME = 'Ince Structor';
    // Transactions (TREX1)
    private static final String TRANSACTION_STATUS_CLOSE = 'Close';
    private static final String TRANSACTION_RECEIPT_NAME = 'Receipt-039483628948267346';
    // Users
    private static final String EMAIL_ENCODING_KEY = 'UTF-8';
    private static final String STANDARD_USER_USERNAME = 'standarduser' + DateTime.now().getTime() + '@agtests.com';
    private static final String STANDARD_USER_EMAIL = 'testing@testthings.com';
    private static final String STANDARD_USER_FIRSTNAME = 'Tester';
    private static final String STANDARD_USER_LASTNAME = 'Testerson';
    private static final String STANDARD_USER_ALIAS = 'tester';
    private static final String STANDARD_USER_NICKNAME = 'TestUser193948';
    private static final String STANDARD_USER_PROFILE_NAME = 'Standard User';


    /***********************************
     * Accounts
     ***********************************/

    /**
     * Create accounts with a household record type
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of records to create
     */

    public static List<Account> createHouseholdAccounts(
        Integer numberOfHouseholds
    ) {
        List<Account> lstHouseholds = new List<Account>();
        if (householdRecordTypeId == null) {
            householdRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();
        }
        for (Integer i = 0; i < numberOfHouseholds; i++) {
            lstHouseholds.add( 
                new Account(
                    Name = ACCOUNT_BASE_NAME + String.valueOf(i), 
                    RecordTypeId = householdRecordTypeId
                )
            );
        }
        return lstHouseholds;
    }

    /**
     * Create accounts with an organization record type
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of records to create
     */

    public static List<Account> createOrganizationAccounts(
        Integer numberOfOrganizations
    ) {
        List<Account> lstOrganizations = new List<Account>();
        if (organizationRecordTypeId == null) {
            organizationRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId();
        }
        for (Integer i = 0; i < numberOfOrganizations; i++) {
            lstOrganizations.add( 
                new Account(
                    Name = ORGANIZATION_BASE_NAME + String.valueOf(i), 
                    RecordTypeId = organizationRecordTypeId
                )
            );
        }
        return lstOrganizations;
    }


    /***********************************
     * Affiliations
     ***********************************/

    /**
     * Create affiliations
     * No DML - returns unsaved list of sObjects
     * @param lstOrganizations Accounts for Contacts to be affiliated with
     * @param lstContacts Contacts to create affiliations for
     */

    public static List<npe5__Affiliation__c> createAffiliations(
        List<Account> lstOrganizations,
        List<Contact> lstContacts
    ) {
        List<npe5__Affiliation__c> lstAffiliations = new List<npe5__Affiliation__c>();
        for (Account org : lstOrganizations) {
            for (Contact ct : lstContacts) {
                lstAffiliations.add( 
                    new npe5__Affiliation__c(
                        npe5__Status__c = AFFILIATION_STATUS_CURRENT,
                        npe5__Contact__c = ct.Id,
                        npe5__Organization__c = org.Id
                    )
                );
            }
        }
        return lstAffiliations;
    }


    /***********************************
     * Availability Profiles
     ***********************************/

    /**
     * Create availability profile
     * No DML - returns unsaved list of sObjects
     */

    public static TREX1__Availability_Profile__c createAvailabilityProfile() {
        return new TREX1__Availability_Profile__c(
            Name = AVAILABILITY_PROFILE_BASE_NAME,
            TREX1__Sunday_Hours__c = AVAILABILITY_PROFILE_DAILY_HOURS,
            TREX1__Monday_Hours__c = AVAILABILITY_PROFILE_DAILY_HOURS,
            TREX1__Tuesday_Hours__c = AVAILABILITY_PROFILE_DAILY_HOURS,
            TREX1__Wednesday_Hours__c = AVAILABILITY_PROFILE_DAILY_HOURS,
            TREX1__Thursday_Hours__c = AVAILABILITY_PROFILE_DAILY_HOURS,
            TREX1__Friday_Hours__c = AVAILABILITY_PROFILE_DAILY_HOURS,
            TREX1__Saturday_Hours__c = AVAILABILITY_PROFILE_DAILY_HOURS
        );
    }

     
    /***********************************
     * Booking Contract Options
     ***********************************/

    /**
     * Create booking contract options for a list of facilities and functions
     * No DML - returns unsaved list of sObjects
     * @param List<TREX1__Facility__c> List of facilities to link to functions
     * @param List<TREX1__Function__c> List of functions to link to facilities
     */

    public static List<TREX1__Booking_Contract_Option__c> createBookingContractOptions(
        List<TREX1__Facility__c> lstFacilities,
        List<TREX1__Function__c> lstFunctions
    ) {
        List<TREX1__Booking_Contract_Option__c> lstBCOs = new List<TREX1__Booking_Contract_Option__c>();
        for (TREX1__Facility__c facility : lstFacilities) {
            for (TREX1__Function__c function : lstFunctions) {
                lstBCOs.add( 
                    new TREX1__Booking_Contract_Option__c(
                        Name = BCO_BASE_NAME,
                        TREX1__Facility__c = facility.Id,
                        TREX1__Function__c = function.Id
                    )
                );
            }
        }
        return lstBCOs;
    }


    /***********************************
     * Bookings
     ***********************************/

    /**
     * Create admin bookings
     * Returns list of bookings committed to database
     * @param List<TREX1__Facility__c> List of facilities to book
     * @param Integer Number of records to create for each facility
     */

    public static List<TREX1__Booking__c> createAdminBookings(
        List<TREX1__Facility__c> lstFacilities,
        Integer numberOfBookings
    ) {
        TREX1__Function__c function = new TREX1__Function__c(
            Name = FUNCTION_BASE_NAME
        );
        insert function;

        List<TREX1__Booking_Contract_Option__c> lstBCOs = new List<TREX1__Booking_Contract_Option__c>();
        for (TREX1__Facility__c facility : lstFacilities) {
            lstBCOs.add(
                new TREX1__Booking_Contract_Option__c(
                    TREX1__Facility__c = facility.Id,
                    TREX1__Function__c = function.Id
                )
            );
        }
        insert lstBCOs;

        List<TREX1__Booking__c> lstBookings = new List<TREX1__Booking__c>();
        for (Integer i = 0; i < numberOfBookings; i++) {
            lstBookings.add(
                new TREX1__Booking__c(
                    RecordTypeId = facilityBookingRTId,
                    TREX1__Type__c = ADMIN_BOOKING_TYPE,
                    TREX1__Status__c = BOOKING_STATUS,
                    TREX1__Start_Time__c = Datetime.newInstance(Date.today() + 1, Time.newInstance(i + 7, 0, 0, 0)),
                    TREX1__End_Time__c = Datetime.newInstance(Date.today() + 1, Time.newInstance(i + 8, 0, 0, 0)),
                    TREX1__Event_Name__c = BOOKING_EVENT_NAME,
                    TREX1__Setup_Time_Required__c = BOOKING_SETUP_TIME_REQUIRED,
                    TREX1__Tear_Down_Time_Required__c = BOOKING_TEAR_DOWN_TIME_REQUIRED,
                    Booking_Rate_Calculation_Mode__c = CALCULATION_MODE_AUTOMATIC
                )
            );
        }
        return lstBookings;

    }

    /**
     * Create bookings with a type of rental
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of records to create
     */

    public static List<TREX1__Booking__c> createRentalBookings(
        Integer numberOfBookings
    ) {
        List<TREX1__Booking__c> lstBookings = new List<TREX1__Booking__c>();
        for (Integer i = 0; i < numberOfBookings; i++) {
            if (facilityBookingRTId == null) {
                facilityBookingRTId = Schema.SObjectType.TREX1__Booking__c.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
            }
            lstBookings.add( 
                new TREX1__Booking__c(
                    RecordTypeId = facilityBookingRTId,
                    TREX1__Type__c = RENTAL_BOOKING_TYPE,
                    TREX1__Status__c = BOOKING_STATUS,
                    TREX1__Start_Time__c = Datetime.newInstance(Date.today() + 1, Time.newInstance(i + 7, 0, 0, 0)),
                    TREX1__End_Time__c = Datetime.newInstance(Date.today() + 1, Time.newInstance(i + 8, 0, 0, 0)),
                    TREX1__Event_Name__c = BOOKING_EVENT_NAME,
                    TREX1__Setup_Time_Required__c = BOOKING_SETUP_TIME_REQUIRED,
                    TREX1__Tear_Down_Time_Required__c = BOOKING_TEAR_DOWN_TIME_REQUIRED,
                    Booking_Rate__c = BOOKING_RATE,
                    Booking_Rate_Details__c = BOOKING_RATE_DETAILS,
                    Booking_Rate_Calculation_Mode__c = CALCULATION_MODE_AUTOMATIC
                )
            );
        }
        return lstBookings;
    }

    /**
     * Create bookings with a type of rental
     * No DML - returns unsaved list of sObjects
     * @param List<TREX1__Facility__c> Facilities to book
     * @param List<TREX1__Function__c> Functions to create bookings for
     * @param TREX1__Rental_Contract__c Contract to assign bookings to
     * @param Integer Number of bookings to create for each combo
     */

    public static List<TREX1__Booking__c> createRentalBookings(
        List<TREX1__Facility__c> lstFacilities,
        List<TREX1__Function__c> lstFunctions,
        TREX1__Rental_Contract__c contract,
        Integer numberOfBookingsEach
    ) {
        if (facilityBookingRTId == null) {
            facilityBookingRTId = Schema.SObjectType.TREX1__Booking__c.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        }

        List<TREX1__Booking__c> lstBookings = new List<TREX1__Booking__c>();

        for (TREX1__Facility__c facility : lstFacilities) {
            for (TREX1__Function__c function : lstFunctions) {
                for (Integer i = 0; i < numberOfBookingsEach; i++) {
                    Integer n = Math.mod(i, 2) == 0 ? 7 : 8;
                    Integer y = Math.mod(i, 3) == 0 ? 1 : 5;
                    lstBookings.add( 
                        new TREX1__Booking__c(
                            RecordTypeId = facilityBookingRTId,
                            TREX1__Type__c = RENTAL_BOOKING_TYPE,
                            TREX1__Status__c = BOOKING_STATUS,
                            TREX1__Start_Time__c = Datetime.newInstance(Date.today() + i, Time.newInstance(n, 0, 0, 0)),
                            TREX1__End_Time__c = Datetime.newInstance(Date.today() + i, Time.newInstance(n + y, 0, 0, 0)),
                            TREX1__Event_Name__c = BOOKING_EVENT_NAME + String.valueOf(i),
                            TREX1__Setup_Time_Required__c = BOOKING_SETUP_TIME_REQUIRED,
                            TREX1__Tear_Down_Time_Required__c = BOOKING_TEAR_DOWN_TIME_REQUIRED,
                            Booking_Rate__c = BOOKING_RATE,
                            Booking_Rate_Details__c = BOOKING_RATE_DETAILS,
                            TREX1__Facility__c = facility.Id,
                            TREX1__Function_ID__c = function.Id,
                            TREX1__Rental_Contract__c = contract.Id,
                            Booking_Rate_Calculation_Mode__c = CALCULATION_MODE_AUTOMATIC
                        )
                    );
                }
            }
        }
        return lstBookings;
    }

    /***********************************
     * Community Programs (pmdm)
     ***********************************/

    /**
     * Create community program sObjects
     * Object renamed from PMM managed package (Program)
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of programs to create
     */

    public static List<pmdm__Program__c> createCommunityPrograms(
        Integer numberOfPrograms
    ) {
        List<pmdm__Program__c> lstCommunityPrograms = new List<pmdm__Program__c>();
        for (Integer i = 0; i < numberOfPrograms; i++) {
            lstCommunityPrograms.add(
                new pmdm__Program__c(
                    Name = COMMUNITY_PROGRAM_BASE_NAME + String.valueOf(i), 
                    pmdm__StartDate__c = Date.today().addMonths(-1), 
                    pmdm__EndDate__c = Date.today().addMonths(1), 
                    pmdm__Status__c = COMMUNITY_PROGRAM_STATUS_ACTIVE
                )
            );
        }
        return lstCommunityPrograms;
    }

    /***********************************
     * Contacts
     ***********************************/

    /**
     * Create contact sObjects without accounts
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of contacts to create for each account
     */

    public static List<Contact> createContacts(
        Integer numberOfContacts
    ) {
        return generateContactsWithDefaults(numberOfContacts);
    }

    /**
     * Create contact sObjects for a preexisting list of accounts
     * No DML - returns unsaved list of sObjects
     * @param List<Account> Parent accounts for created contacts
     * @param Integer Number of contacts to create for each account
     */

    public static List<Contact> createContacts(
        List<Account> lstParentAccounts, Integer numberOfContacts
    ) {
        List<Contact> lstContacts = new List<Contact>();
        for (Account acc : lstParentAccounts) {
            List<Contact> lstAccountContacts = generateContactsWithDefaults(numberOfContacts);
            for (Contact ct : lstAccountContacts) {
                ct.AccountId = acc.Id;
            }
            lstContacts.addAll(lstAccountContacts);
        }
        return lstContacts;
    }

    /**
     * Create a list of default contacts with FirstName, LastName, Email, and Birthdate
     *     to be used by overloaded createContacts method
     * @param numberOfContacts Number of contacts to create
     */

    private static List<Contact> generateContactsWithDefaults(
        Integer numberOfContacts
    ) {
        List<Contact> lstDefaultCts = new List<Contact>();
        for (Integer i = 0; i < numberOfContacts; i++) {
            lstDefaultCts.add(
                new Contact(
                    FirstName  = CONTACT_BASE_FIRST_NAME + String.valueOf(i),
                    MiddleName = CONTACT_BASE_MIDDLE_NAME + String.valueOf(i),
                    LastName   = CONTACT_BASE_LAST_NAME + String.valueOf(i),
                    Email      = CONTACT_BASE_FIRST_NAME + CONTACT_BASE_LAST_NAME + String.valueOf(i) + '@testingstuff.com',
                    Birthdate  = CONTACT_BASE_BIRTHDATE.addYears(-i).addMonths(i)
                )
            );
        }
        return lstDefaultCts;
    }

    
    /***********************************
     * Facilities
     ***********************************/

    /**
     * Create facilities
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of records to create
     */

    public static List<TREX1__Facility__c> createFacilities(
        Integer numberOfFacilities
    ) {
        List<TREX1__Facility__c> lstFacilities = new List<TREX1__Facility__c>();
        for (Integer i = 0; i < numberOfFacilities; i++) {
            lstFacilities.add( 
                new TREX1__Facility__c(
                    Name = FACILITY_BASE_NAME + String.valueOf(i),
                    TREX1__Max_Capacity__c = 100,
                    TREX1__Type__c = FACILITY_TYPE
                )
            );
        }
        return lstFacilities;
    }


    /***********************************
     * Functions
     ***********************************/

    /**
     * Create functions
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of records to create
     */

    public static List<TREX1__Function__c> createFunctions(
        Integer numberOfFunctions
    ) {
        List<TREX1__Function__c> lstFunctions = new List<TREX1__Function__c>();
        for (Integer i = 0; i < numberOfFunctions; i++) {
            lstFunctions.add( 
                new TREX1__Function__c(
                    Name = FUNCTION_BASE_NAME + String.valueOf(i)
                )
            );
        }
        return lstFunctions;
    }


    /***********************************
     * Groups
     ***********************************/

    /**
     * Create regular public group
     * No DML - returns a single, unsaved public group
     */

    public static Group createRegularGroup() {
        Group newGroup = new Group(
            Name = PUBLIC_GROUP_NAME, 
            Type = GROUP_TYPE_REGULAR, 
            DoesIncludeBosses = false, 
            DoesSendEmailToMembers = false
        );
        return newGroup;
    }


    /***********************************
     * Locations
     ***********************************/

    /**
     * Create locations
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of records to create
     */

    public static List<TREX1__Location__c> createLocations(
        Integer numberOfLocations
    ) {
        List<TREX1__Location__c> lstLocations = new List<TREX1__Location__c>();
        for (Integer i = 0; i < numberOfLocations; i++) {
            lstLocations.add( 
                new TREX1__Location__c(
                    Name = LOCATION_BASE_NAME + String.valueOf(i)
                )
            );
        }
        return lstLocations;
    }


    /***********************************
     * Memberships (TREX1)
     ***********************************/

    /**
     * Create membership sObjects
     * No DML - returns unsaved list of sObjects
     * @param Contact membership contact
     * @param Account household
     * @param TREX1__Transaction__c parent transaction 
     */

    public static TREX1__Membership__c createCompletedPunchPassMembership(
        Contact contact, 
        Account account, 
        TREX1__Transaction__c trans
    ) {
        if (punchPassRecTypeId == null) {
            punchPassRecTypeId = getPunchPassRecordTypeId();
        }
        return new TREX1__Membership__c(
                TREX1__Contact__c = contact.Id, 
                TREX1__Account__c = account.Id, 
                RecordTypeId = punchPassRecTypeId, 
                TREX1__Status__c = MEMBERSHIP_STATUS_COMPLETE,
                TREX1__Category_Name__c = VALID_MEMBERSHIP_CATEGORY,
                TREX1__Start_Date__c = Date.today().addDays(-1),
                TREX1__Stored_Value__c = 1,
                TREX1__Purchasing_Transaction__c = trans.Id
        );
    }

    /**
     * Create membership sObjects
     * No DML - returns unsaved list of sObjects
     * @param Contact membership contact
     * @param Account household
     * @param Id parent transaction id
     * @param Id membership type id
     */

    public static TREX1__Membership__c createCompletedPunchPassesFromType(
        Contact contact, 
        Account account, 
        Id transactionId, 
        Id membershipTypeId
    ) {
        if (punchPassRecTypeId == null) {
            punchPassRecTypeId = getPunchPassRecordTypeId();
        }
        return new TREX1__Membership__c(
                TREX1__Contact__c = contact.Id, 
                TREX1__Account__c = account.Id, 
                RecordTypeId = punchPassRecTypeId, 
                TREX1__memb_Type__c = membershipTypeId, 
                TREX1__Status__c = MEMBERSHIP_STATUS_COMPLETE,
                TREX1__Category_Name__c = VALID_MEMBERSHIP_CATEGORY,
                TREX1__Start_Date__c = Date.today().addDays(-1),
                TREX1__Stored_Value__c = 1,
                TREX1__Purchasing_Transaction__c = transactionId
        );
    }

    /**
     * Create membership sObjects
     * No DML - returns unsaved list of sObjects
     * @param Contact membership contact
     * @param Account household
     * @param TREX1__Transaction__c parent transaction 
     */

    public static TREX1__Membership__c createActivePunchPassMembership(
        Contact contact, 
        Account account, 
        TREX1__Transaction__c trans
    ) {
        if (punchPassRecTypeId == null) {
            punchPassRecTypeId = getPunchPassRecordTypeId();
        }
        return new TREX1__Membership__c(
                TREX1__Contact__c = contact.Id, 
                TREX1__Account__c = account.Id, 
                RecordTypeId = punchPassRecTypeId, 
                TREX1__Status__c = MEMBERSHIP_STATUS_ACTIVE,
                TREX1__Category_Name__c = VALID_MEMBERSHIP_CATEGORY,
                TREX1__Start_Date__c = Date.today().addDays(-1),
                TREX1__Stored_Value__c = 1,
                TREX1__Purchasing_Transaction__c = trans.Id
        );
    }

    /**
     * Create membership sObjects
     * No DML - returns unsaved list of sObjects
     * @param Contact membership contact
     * @param Account household
     * @param Id parent transaction id
     * @param Id membership type id
     */

    public static TREX1__Membership__c createActivePunchPassesFromType(
        Contact contact, 
        Id accountId, 
        Id transactionId, 
        Id membershipTypeId
    ) {
        if (punchPassRecTypeId == null) {
            punchPassRecTypeId = getPunchPassRecordTypeId();
        }
        
        Id categoryId = [SELECT TREX1__Category__c FROM TREX1__Membership_Type__c WHERE Id = :membershipTypeId LIMIT 1].TREX1__Category__c;
        
        return new TREX1__Membership__c(
                TREX1__Contact__c = contact.Id, 
                TREX1__Account__c = accountId, 
                RecordTypeId = punchPassRecTypeId, 
                TREX1__memb_Type__c = membershipTypeId, 
        		TREX1__memb_Category__c = categoryId, 
                TREX1__Status__c = MEMBERSHIP_STATUS_ACTIVE, 
                TREX1__Category_Name__c = VALID_MEMBERSHIP_CATEGORY, 
                TREX1__Start_Date__c = Date.today().addDays(-1), 
                TREX1__Stored_Value__c = 1, 
                TREX1__Purchasing_Transaction__c = transactionId
        );
    }

    /**
     * Get punch pass record type id
     */

    private static Id getPunchPassRecordTypeId() {
        if (punchPassRecTypeId == null) {
            punchPassRecTypeId = Schema.SObjectType.TREX1__Membership__c.getRecordTypeInfosByDeveloperName().get('Punch_Pass_Membership').getRecordTypeId();
        }
        return punchPassRecTypeId;
    }

    
    /***********************************
     * Membership Categories (TREX1)
     ***********************************/

    /**
     * Create membership category sObjects
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of membership categories to create
     */

    public static List<TREX1__Membership_Category__c> createMembershipCategories(
        Integer numberOfMembershipCategories
    ) {
        List<TREX1__Membership_Category__c> lstMembershipCategories = new List<TREX1__Membership_Category__c>();
        for (Integer i = 0; i < numberOfMembershipCategories; i++) {
            lstMembershipCategories.add(
                new TREX1__Membership_Category__c(
                    Name = VALID_MEMBERSHIP_CATEGORY,
                    TREX1__Available_For_Purchase__c = true
                )
            );
        }
        return lstMembershipCategories;
    }

    public static List<TREX1__Membership_Category__c> createPunchPassMembershipCategories(
        Integer numberOfMembershipCategories
    ) {
        List<TREX1__Membership_Category__c> lstMembershipCategories = new List<TREX1__Membership_Category__c>();

        if (membershipCategoryPunchPassRecTypeId == null) {
            membershipCategoryPunchPassRecTypeId = Schema.SObjectType.TREX1__Membership_Category__c.getRecordTypeInfosByDeveloperName().get('Punch_Pass').getRecordTypeId();
        }

        for (Integer i = 0; i < numberOfMembershipCategories; i++) {
            lstMembershipCategories.add(
                new TREX1__Membership_Category__c(
                    Name = VALID_MEMBERSHIP_CATEGORY,
                    TREX1__Available_For_Purchase__c = true, 
                    Maximum_Monthly_Appointments__c = 2, 
                    Minimum_Days_Between_Appointments__c = 2, 
                    Scheduling_Hours_Notice_Required__c = 1, 
                    Cancellation_Hours_Notice_Required__c = 1, 
                    Appointment_Time_Slot_Interval__c = 30
                )
            );
        }
        return lstMembershipCategories;
    }


    /***********************************
     * Membership Types (TREX1)
     ***********************************/

    /**
     * Create membership type sObjects
     * No DML - returns unsaved list of sObjects
     * @param List<TREX1__Membership_Category__c> list of categories
     * @param TREX1__Location__c location
     * @param Integer Number of membership types per category
     */

    public static List<TREX1__Membership_Type__c> createMembershipTypes(
        List<TREX1__Membership_Category__c> lstMembershipCategories, 
        TREX1__Location__c location, 
        Integer numberOfMembershipTypes
    ) {
        List<TREX1__Membership_Type__c> lstMembershipTypes = new List<TREX1__Membership_Type__c>();

        if (membershipTypePunchPassRecTypeId == null) {
            membershipTypePunchPassRecTypeId = Schema.SObjectType.TREX1__Membership_Type__c.getRecordTypeInfosByDeveloperName().get('Punch_Pass_Membership_Type').getRecordTypeId();
        }

        for (TREX1__Membership_Category__c cat : lstMembershipCategories) {
            for (Integer i = 0; i < numberOfMembershipTypes; i++) {
                lstMembershipTypes.add(
                    new TREX1__Membership_Type__c(
                        Name = 'Mem Type ' + String.valueOf(i),
                        Appointment_Length__c = 60,
                        RecordTypeId = membershipTypePunchPassRecTypeId,
                        TREX1__Available_For_Purchase__c = true, 
                        TREX1__Available_Online__c = true, 
                        TREX1__Can_Freeze__c = true, 
                        TREX1__Cancellation_Policy__c = 'N Days Notice', 
                        TREX1__Category__c = cat.Id, 
                        TREX1__End_Date_Setting__c = 'Fixed Length', 
                        TREX1__Location__c = location.Id, 
                        TREX1__Stored_Value__c = 5, 
                        TREX1__Term_Length__c = 90, 
                        TREX1__Term_Type__c = 'Daily'
                    )
                );
            }
        }
        return lstMembershipTypes;
    }

    
    /***********************************
     * Programs (TREX1)
     ***********************************/

    /**
     * Create program sObjects
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of programs to create
     */

    public static List<TREX1__Program__c> createPrograms(
        Integer numberOfPrograms
    ) {
        List<TREX1__Program__c> lstPrograms = new List<TREX1__Program__c>();
        for (Integer i = 0; i < numberOfPrograms; i++) {
            lstPrograms.add(
                new TREX1__Program__c(
                    Name = PROGRAM_BASE_NAME + String.valueOf(i),
                    TREX1__Available__c = true,
                    TREX1__Available_Online__c = true
                )
            );
        }
        return lstPrograms;
    }


    /***********************************
     * Registrations (TREX1)
     ***********************************/

    /**
     * Create registration sObjects of the historical variety
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of registrations to create for each contact
     */

    public static List<TREX1__Registration__c> createHistoricalRegistrations(
        List<Contact> lstContacts,
        Integer numberOfRegistrations
    ) {
        List<TREX1__Registration__c> lstRegistrations = new List<TREX1__Registration__c>();
        for (Contact ct : lstContacts) {
            for (Integer i = 0; i < numberOfRegistrations; i++) {
                lstRegistrations.add(
                    new TREX1__Registration__c(
                        TREX1__Contact__c = ct.Id, 
                        TREX1__Account__c = ct.AccountId, 
                        Course_Option_Names__c = 'Test Course Option', 
                        Course_Option_Codes__c = 'IMA.FA.KECODE001', 
                        Session_Name__c = 'Spring 20', 
                        Total_Fee__c = 500, 
                        Total_Paid__c = 500, 
                        TREX1__Start_Date__c = Date.newInstance(2020, 03, 01), 
                        TREX1__End_Date__c = Date.newInstance(2020, 04, 01),
                        TREX1__Registration_Status__c = 'Complete'
                    )
                );
            }
        }
        return lstRegistrations;
    }

        
    /***********************************
     * Rental Contracts
     ***********************************/

    /**
     * Create rental contracts
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of records to create
     */

    public static TREX1__Rental_Contract__c createRentalContract(
        Contact ct
    ) {
        if (rentalContractRentalRTId == null) {
            rentalContractRentalRTId = Schema.SObjectType.TREX1__Rental_Contract__c.getRecordTypeInfosByDeveloperName().get('Rental').getRecordTypeId();
        }
        return new TREX1__Rental_Contract__c(
            TREX1__Payment_Option__c = RENTAL_CONTRACT_PAYMENT_OPTION,
            TREX1__Status__c = RENTAL_CONTRACT_STATUS,
            TREX1__Contact__c = ct.Id,
            TREX1__Account__c = ct.AccountId
        );
    }

    
    /***********************************
     * Rental Rates
     ***********************************/

    /**
     * Create rental rates for a list of facilities and functions
     * No DML - returns unsaved list of sObjects
     * @param List<TREX1__Facility__c> List of facilities to link to functions
     * @param List<TREX1__Function__c> List of functions to link to facilities
     * @param Integer Number of rental rates to create for each combo
     * @param String Type of rental rate. Accepts either 'Standard_Rate' or 'Incremental_Rate'
     */

    public static List<Rental_Rate__c> createRentalRates(
        List<TREX1__Facility__c> lstFacilities,
        List<TREX1__Function__c> lstFunctions,
        Integer numberOfRentalRates,
        String typeOfRate
    ) {
        List<Rental_Rate__c> lstRentalRates = new List<Rental_Rate__c>();
        for (TREX1__Facility__c facility : lstFacilities) {
            for (TREX1__Function__c function : lstFunctions) {
                for (Integer i = 0; i < numberOfRentalRates; i++) {
                    if (typeOfRate == INCREMENTAL_RATE_RT_NAME) {
                        if (incrementalRateRTId == null) {
                            incrementalRateRTId = Schema.SObjectType.Rental_Rate__c.getRecordTypeInfosByDeveloperName().get(INCREMENTAL_RATE_RT_NAME).getRecordTypeId();
                        }
                        Rental_Rate__c rate = new Rental_Rate__c();
                        rate.Name = RENTAL_RATE_BASE_NAME;
                        rate.Facility__c = facility.Id;
                        rate.Function__c = function.Id;
                        rate.Hourly_Rate__c = 100 * (i + 1);
                        rate.RecordTypeId = incrementalRateRTId;
                        rate.Amount_of_Hours__c = (i + 1) < numberOfRentalRates ? (numberOfRentalRates - i) : 0;
                        lstRentalRates.add(rate);
                    } else {
                        if (standardRateRTId == null) {
                            standardRateRTId = Schema.SObjectType.Rental_Rate__c.getRecordTypeInfosByDeveloperName().get(STANDARD_RATE_RT_NAME).getRecordTypeId();
                        }
                        Integer timeCount = i < 12 ? i : Math.mod(i, 12);
                        Rental_Rate__c rate = new Rental_Rate__c();
                        rate.Name = RENTAL_RATE_BASE_NAME;
                        rate.Facility__c = facility.Id;
                        rate.Function__c = function.Id;
                        rate.Hourly_Rate__c = 100 * (i + 1);
                        rate.RecordTypeId = standardRateRTId;
                        rate.Is_Weekday__c = false;
                        rate.Outside_of_Hours__c = false;
                        rate.Start_Time__c = Time.newInstance(timeCount + 7, 0, 0, 0);
                        rate.End_Time__c   = Time.newInstance((timeCount + 8), 0, 0, 0);

                        Rental_Rate__c weekdayRate = new Rental_Rate__c();
                        weekdayRate.Name = RENTAL_RATE_BASE_NAME;
                        weekdayRate.Facility__c = facility.Id;
                        weekdayRate.Function__c = function.Id;
                        weekdayRate.Hourly_Rate__c = 100 * (i + 1);
                        weekdayRate.RecordTypeId = standardRateRTId;
                        weekdayRate.Is_Weekday__c = true;
                        weekdayRate.Outside_of_Hours__c = false;
                        weekdayRate.Start_Time__c = Time.newInstance(timeCount + 7, 0, 0, 0);
                        weekdayRate.End_Time__c   = Time.newInstance((timeCount + 8), 0, 0, 0);
                        
                        lstRentalRates.add(rate);
                        lstRentalRates.add(weekdayRate);
                    }
                }
            }
        }
        return lstRentalRates;
    }

    public static Map<Id, List<Rental_Rate__c>> createMapFacilityIdToRentalRates(
        List<TREX1__Facility__c> lstFacilities,
        List<TREX1__Function__c> lstFunctions,
        Integer numberOfRentalRates,
        String typeOfRate
    ) {
        Map<Id, List<Rental_Rate__c>> mapFacilityIdToRentalRates = new Map<Id, List<Rental_Rate__c>>();
        for (TREX1__Facility__c facility : lstFacilities) {
            List<Rental_Rate__c> lstRentalRates = new List<Rental_Rate__c>();
            for (TREX1__Function__c function : lstFunctions) {
                for (Integer i = 0; i < numberOfRentalRates; i++) {
                    if (typeOfRate == INCREMENTAL_RATE_RT_NAME) {
                        if (incrementalRateRTId == null) {
                            incrementalRateRTId = Schema.SObjectType.Rental_Rate__c.getRecordTypeInfosByDeveloperName().get(INCREMENTAL_RATE_RT_NAME).getRecordTypeId();
                        }
                        Rental_Rate__c rate = new Rental_Rate__c();
                        rate.Name = RENTAL_RATE_BASE_NAME;
                        rate.Facility__c = facility.Id;
                        rate.Function__c = function.Id;
                        rate.Hourly_Rate__c = 100 * (i + 1);
                        rate.RecordTypeId = incrementalRateRTId;
                        rate.Amount_of_Hours__c = (i + 1) < numberOfRentalRates ? (numberOfRentalRates - i) : 0;
                        lstRentalRates.add(rate);
                    } else {
                        if (standardRateRTId == null) {
                            standardRateRTId = Schema.SObjectType.Rental_Rate__c.getRecordTypeInfosByDeveloperName().get(STANDARD_RATE_RT_NAME).getRecordTypeId();
                        }
                        Integer timeCount = i < 12 ? i : Math.mod(i, 12);
                        Rental_Rate__c rate = new Rental_Rate__c();
                        rate.Name = RENTAL_RATE_BASE_NAME;
                        rate.Facility__c = facility.Id;
                        rate.Function__c = function.Id;
                        rate.Hourly_Rate__c = 100 * (i + 1);
                        rate.RecordTypeId = standardRateRTId;
                        rate.Is_Weekday__c = false;
                        rate.Outside_of_Hours__c = false;
                        rate.Start_Time__c = Time.newInstance(timeCount + 7, 0, 0, 0);
                        rate.End_Time__c   = Time.newInstance((timeCount + 8), 0, 0, 0);

                        Rental_Rate__c weekdayRate = new Rental_Rate__c();
                        weekdayRate.Name = RENTAL_RATE_BASE_NAME;
                        weekdayRate.Facility__c = facility.Id;
                        weekdayRate.Function__c = function.Id;
                        weekdayRate.Hourly_Rate__c = 100 * (i + 1);
                        weekdayRate.RecordTypeId = standardRateRTId;
                        weekdayRate.Is_Weekday__c = true;
                        weekdayRate.Outside_of_Hours__c = false;
                        weekdayRate.Start_Time__c = Time.newInstance(timeCount + 7, 0, 0, 0);
                        weekdayRate.End_Time__c   = Time.newInstance((timeCount + 8), 0, 0, 0);
                        
                        lstRentalRates.add(rate);
                        lstRentalRates.add(weekdayRate);
                    }
                }
            }
            mapFacilityIdToRentalRates.put(
                facility.Id, 
                lstRentalRates
            );
        }
        return mapFacilityIdToRentalRates;
    }

    
    /***********************************
     * Rules (TREX1)
     ***********************************/

    /**
     * Create rules sObjects
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of rules to create
     */

    public static List<TREX1__Rule__c> createRules(
        Integer numberOfRules
    ) {
        List<TREX1__Rule__c> lstRules = new List<TREX1__Rule__c>();
        for (Integer i = 0; i < numberOfRules; i++) {
            lstRules.add( 
                new TREX1__Rule__c(Name = RULE_BASE_NAME + String.valueOf(i)) 
            );
        }
        return lstRules;
    }


    /***********************************
     * Scheduled Rules
     ***********************************/

    /**
     * Create scheduled rules sObjects for a list of rules
     * No DML - returns unsaved list of Scheduled Rule sObjects
     * @param List<TREX1__Rule__c> List of Rules to create scheduled rules for
     * @param Integer Number of scheduled rules to create for each rule
     */

    public static List<Scheduled_Rule__c> createScheduledRules(
        List<TREX1__Rule__c> lstParentRules, Integer numberOfScheduledRules
    ) {
        List<Scheduled_Rule__c> lstScheduledRules = new List<Scheduled_Rule__c>();
        for (TREX1__Rule__c rule : lstParentRules) {
            for (Integer i = 0; i < numberOfScheduledRules; i++) {
                lstScheduledRules.add(
                    new Scheduled_Rule__c(
                        Name = SCHEDULED_RULE_BASE_NAME + String.valueOf(i),
                        Rule__c = rule.Id,
                        Start_Date_Time__c = Datetime.now().addDays(i+1),
                        End_Date_Time__c = Datetime.now().addDays(i+2),
                        Description__c = SCHEDULED_RULE_DESCRIPTION
                    )
                );
            }
        }
        return lstScheduledRules;
    }

    /***********************************
     * Services (pmdm)
     ***********************************/

    /**
     * Create service sObjects for a community program
     * No DML - returns unsaved list of sObjects
     * @param pmdm__Program__c community program
     * @param Integer Number of services to create
     */

    public static List<pmdm__Service__c> createServices(
        pmdm__Program__c program, 
        Integer numberOfServices
    ) {
        List<pmdm__Service__c> lstServices = new List<pmdm__Service__c>();
        for (Integer i = 0; i < numberOfServices; i++) {
            lstServices.add(
                new pmdm__Service__c(
                    Name = SERVICE_BASE_NAME + String.valueOf(i), 
                    pmdm__Program__c = program.Id, 
                    pmdm__Status__c = SERVICE_STATUS_ACTIVE, 
                    pmdm__AttendanceFieldSet__c = SERVICE_ATTENDANCE_FIELD_SET, 
                    pmdm__ServiceDeliveryFieldSet__c = SERVICE_BULK_DELIVERY_FIELD_SET, 
                    pmdm__UnitOfMeasurement__c = SERVICE_UNIT_OF_MEASUREMENT
                )
            );
        }
        return lstServices;
    }

    /***********************************
     * Service Schedules (pmdm)
     ***********************************/

    /**
     * Create service schedule sObjects for a service
     * No DML - returns unsaved list of sObjects
     * @param pmdm__Service__c service
     * @param Integer Number of service schedules to create
     */

    public static List<pmdm__ServiceSchedule__c> createServiceSchedules(
        pmdm__Service__c service, 
        Integer numberOfSchedules
    ) {
        List<pmdm__ServiceSchedule__c> lstSchedules = new List<pmdm__ServiceSchedule__c>();
        for (Integer i = 0; i < numberOfSchedules; i++) {
            lstSchedules.add(
                new pmdm__ServiceSchedule__c(
                    Name = SERVICE_SCHEDULE_BASE_NAME + String.valueOf(i), 
                    pmdm__Service__c = service.Id, 
                    pmdm__DefaultServiceQuantity__c = SERVICE_SCHEDULE_DEFAULT_SERVICE_QUANTITY, 
                    pmdm__FirstSessionStart__c = DateTime.now(), 
                    pmdm__FirstSessionEnd__c = DateTime.now().addHours(SERVICE_SCHEDULE_DEFAULT_SERVICE_QUANTITY)
                )
            );
        }
        return lstSchedules;
    }

    /***********************************
     * Service Participants (pmdm)
     ***********************************/

    /**
     * Create service participant sObjects for a service schedule
     * No DML - returns unsaved list of sObjects
     * @param pmdm__ServiceSchedule__c service schedule
     * @param Contact[] list of contacts to enroll
     */

    public static List<pmdm__ServiceParticipant__c> createServiceParticipants(
        pmdm__ServiceSchedule__c serviceSchedule, 
        List<Contact> lstContacts
    ) {
        List<pmdm__ServiceParticipant__c> lstParticipants = new List<pmdm__ServiceParticipant__c>();
        for (Contact ct : lstContacts) {
            lstParticipants.add(
                new pmdm__ServiceParticipant__c(
                    Name = ct.FirstName + ' ' + ct.LastName + ' ' + serviceSchedule.Name, 
                    pmdm__Contact__c = ct.Id, 
                    pmdm__Service__c = serviceSchedule.pmdm__Service__c, 
                    pmdm__ServiceSchedule__c = serviceSchedule.Id, 
                    pmdm__SignUpDate__c = Date.today(), 
                    pmdm__Status__c = SERVICE_PARTICIPANT_STATUS_ENROLLED, 
                    Bypass_Auto_Emails__c = true
                )
            );
        }
        return lstParticipants;
    }

    /***********************************
     * Staff (TREX1)
     ***********************************/

    /**
     * Create staff sObjects for a list of contacts
     * No DML - returns unsaved list of Staff sObjects
     * @param List<Contact> List of Contacts to create staff for
     */

    public static List<TREX1__Staff__c> createStaffFromContacts(
        List<Contact> lstContacts
    ) {
        List<TREX1__Staff__c> lstStaff = new List<TREX1__Staff__c>();
        for (Contact ct : lstContacts) {
            lstStaff.add(
                new TREX1__Staff__c(
                    Name = ct.FirstName + ' ' + ct.LastName, 
                    Contact__c = ct.Id
                )
            );
        }
        return lstStaff;
    }

    /***********************************
     * Staff Availability Schedules
     ***********************************/

    /**
     * Create sas sObjects for a staff record
     * No DML - returns unsaved list of sas sObjects
     * @param TREX1__Staff__c Staff
     * @param Date start date
     * @param Time start time
     * @param Time end time
     * @param Id location id
     * @param Integer number of days
     */

    public static List<Staff_Availability_Schedule__c> createAvailabilityForConsecutiveDays(
        TREX1__Staff__c staff, 
        Date startDate,
        Time startTime, 
        Time endTime, 
        Id locationId, 
        Integer numberOfDays
    ) {
        List<Staff_Availability_Schedule__c> lstSchedules = new List<Staff_Availability_Schedule__c>();
        for (Integer i = 0; i < numberOfDays; i++) {
            lstSchedules.add(
                new Staff_Availability_Schedule__c(
                    Name = 'Test', 
                    Staff__c = staff.Id, 
                    Start_DateTime__c = DateTime.newInstance(startDate.addDays(i), startTime),
                    End_DateTime__c = DateTime.newInstance(startDate.addDays(i), endTime), 
                    Location__c = locationId
                )
            );
        }
        return lstSchedules;
    }

    /***********************************
     * Transactions (TREX1)
     ***********************************/

    /**
     * Create a transaction for a contact and account
     * Inserts records to use id in receipt attachment
     * @param Contact transaction contact
     * @param Account household
     * @return List<TREX1__Transaction__c> Transactions
     */

    public static TREX1__Transaction__c createTransaction(
        Contact contact
    ) {
        if (standardTransactionRecTypeId == null) {
            standardTransactionRecTypeId = Schema.SObjectType.TREX1__Transaction__c.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();
        }

        TREX1__Transaction__c trans = new TREX1__Transaction__c();
        trans.RecordTypeId = standardTransactionRecTypeId;
        trans.TREX1__Account__c = contact.AccountId;
        trans.TREX1__Contact__c = contact.Id;
        trans.TREX1__Public_Visibility__c = true;
        trans.TREX1__Status__c = TRANSACTION_STATUS_CLOSE;
        insert trans;

        Attachment attach = new Attachment();   	
    	attach.Name = TRANSACTION_RECEIPT_NAME;
    	Blob bodyBlob = Blob.valueOf('Receipt Attachment Body');
    	attach.body = bodyBlob;
        attach.parentId = trans.id;
        insert attach;

        return trans;
    }


    /***********************************
     * Users
     ***********************************/

    /**
     * Create external users for a list of contacts
     * No DML - returns unsaved list of sObjects
     * @param List<Contact> Parent contacts for created users
     */

    public static List<User> createExternalUsers(
        List<Contact> lstParentContacts
    ) {
        List<User> lstUsers = new List<User>();
        for (Contact ct : lstParentContacts) {
            User u = ExternalUserUtilities.getUserWithDefaults();
            u.ContactId           = ct.Id;
            u.Username            = ct.Email;
            u.Email               = ct.Email;
            u.FirstName           = ct.FirstName;
            u.LastName            = ct.LastName;
            u.Alias               = ExternalUserUtilities.getAliasFromName(ct.FirstName, ct.LastName);
            u.CommunityNickname   = ExternalUserUtilities.getNicknameFromUsername(ct.Email);
            lstUsers.add(u);
        }
        return lstUsers;
    }

    /**
     * Create internal standard user
     * No DML - returns unsaved list of sObjects
     */

    public static User createStandardUser() {
        User u = ExternalUserUtilities.getUserWithDefaults();
        u.Username  = STANDARD_USER_USERNAME;
        u.Email     = STANDARD_USER_EMAIL;
        u.FirstName = STANDARD_USER_FIRSTNAME;
        u.LastName  = STANDARD_USER_LASTNAME;
        u.Alias     = STANDARD_USER_ALIAS;
        u.CommunityNickname = STANDARD_USER_NICKNAME;
        return u;
    }

    /**
     * Create internal standard user
     * No DML - returns unsaved sObject
     */

    public static User createStandardInternalUser() {

        Profile profile = [SELECT Id FROM Profile WHERE Name = :STANDARD_USER_PROFILE_NAME LIMIT 1];

        User u = new User();
        u.IsActive          = true;
        u.ProfileId         = profile.Id;
        u.TimeZoneSidKey    = UserInfo.getTimeZone().toString();
        u.LocaleSidKey      = UserInfo.getLocale();
        u.LanguageLocaleKey = UserInfo.getLocale();
        u.EmailEncodingKey  = EMAIL_ENCODING_KEY;
        u.Username          = STANDARD_USER_USERNAME;
        u.Email             = STANDARD_USER_EMAIL;
        u.FirstName         = STANDARD_USER_FIRSTNAME;
        u.LastName          = STANDARD_USER_LASTNAME;
        u.Alias             = STANDARD_USER_ALIAS;
        return u;

    }


}