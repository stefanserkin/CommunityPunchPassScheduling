# Community Punch Pass Scheduling

A solution for booking private lessons from Salesforce Communities. Review purchase and usage history. Schedule new appointments.

## Description

A component to allow community users to view household Punch Pass Membership data in Traction Rec.

Row actions allow the user to *Download Receipt* from the related Purchasing Transaction and view Pass Decrements related to each Punch Pass Membership via the *View Usage History* action.

*View Usage History* opens a pop-up window with related Pass Decrement data.

Enable the *Schedule Appointment* row action when configuring the component to allow the user to navigate to your booking system.

## Configuration

### Post-Installation Steps

In *Experience Builder*, search for “Punch Pass” in the Components menu.

Drag the component onto the page.

Click on the component to access the list of Design Attributes.

*SLDS Icon Name*
https://www.lightningdesignsystem.com/icons/

*Membership Categories to Display*
Use this field to define which Membership Categories will appear in this component. Enter the Names of the Membership Categories, separated by commas.

*Package Reference Name*
Define a preferred singular and plural name for when the component refers to punch pass memberships (e.g. Packages, Bundles, Pilates Sessions)

*Show Navigation Button*
If true, a button will display in the top right of the component.

*Navigation Button Label*
The label for the button. Default: Purchase Packages

*Navigation Button URL*
The target URL for the button

*Allow appointment scheduling*
Enables appointment functionality

*Required Hours Notice for Cancellation*
Appointment cancellation will be disabled for appointments within this window

## Appointment Settings

### Membership Category Appointment Settings

#### Maximum Monthly Appointments

The maximum number of appointments that can be scheduled within a calendar month for a particular contact within this membership category. Leave this blank to remove the restriction.

#### Minimum Days Between Appointments

The minimum number of days that must pass before another appointment can be scheduled. For example, if Minimum Days Between Appointments equals 7, availability slots within 7 days of an existing appointment (scheduled or complete) will not be available. Default is 0.

#### Scheduling Hours Notice Required

The amount of hours' notice required before an appointment can be scheduled. Availability slots that violate this policy will not appear to the user. Default is 0.

#### Cancellation Hours Notice Required

Appointment cancellation will be disabled for appointments that violate this policy. Default is 0.

#### Appointment Time Slot Interval

The number of minutes between available appointment slots. E.g. An interval of 15 will show slots at 3pm, 3:15pm, 3:30pm, etc.. Default is 30 minutes.

#### Automatically Check In Appointments

If checked, scheduled appointments will be automatically checked in and decremented when they have passed

### Membership Type Appointment Settings

#### Appointment Length

The length of an individual appointment in minutes.

### Permissions

The component is set to enforce the level of access defined in the org, so may require some additional permissions.

#### Apex Class Access

CommunityPunchPassesController

#### Sharing Settings

External users must have at least Read Only access to Memberships and Transactions related to their Account. Define access using Sharing Sets.

* TREX1__Membership__c
* TREX1__Transaction__c

Setup > Feature Settings > Digital Experiences > Settings > Sharing Sets

### Query Criteria (What Shows Up?)

#### Active Punch Passes

Membership (TREX1__Membership__c) records appear in the Active Punch Passes section when:

* Account matches the logged in User’s Account
* Record Type is ‘Punch Pass Membership’
* Membership Category Name is one of the names defined in the component’s Membership Categories to Display design attribute
* Remaining Value is greater than 0
* Status does not equal ‘Complete’
* End Date is greater than or equal to Today or null

#### Completed Punch Passes

Membership (TREX1__Membership__c) records appear in the Completed Punch Passes section when:

* Account matches the logged in User’s Account
* RecordType = ‘Punch Pass Membership’
* Membership Category Name is one of the names defined in the component’s Membership Categories to Display design attribute
* And either of the following are true
    * Total Value is greater than 0 AND Remaining Value equals 0
    * Status equals ‘Complete’

## Read All About It

- [Quip Doc](https://quip.com/Rs8gATCdwLxZ/Community-Punch-Passes-Component-Deck)
