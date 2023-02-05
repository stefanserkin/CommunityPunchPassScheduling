import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { createRecord } from 'lightning/uiRecordApi';
import getAssignedStaffAvailability from '@salesforce/apex/CommunityPunchPassesController.getAssignedStaffAvailability';

import APPOINTMENT_OBJECT from '@salesforce/schema/Appointment__c';
import CONTACT_FIELD from '@salesforce/schema/Appointment__c.Contact__c';
import STARTDATE_FIELD from '@salesforce/schema/Appointment__c.Start_DateTime__c';
import ENDDATE_FIELD from '@salesforce/schema/Appointment__c.End_DateTime__c';
import STAFF_FIELD from '@salesforce/schema/Appointment__c.Staff__c';
import STATUS_FIELD from '@salesforce/schema/Appointment__c.Status__c';
import MEMBERSHIP_FIELD from '@salesforce/schema/Appointment__c.Membership__c';

export default class CommunityPunchPassesScheduler extends LightningElement {
    @api punchPass;
    @api membershipTypeId;
    @api locationId;
    @api appointmentLength;
    @api punchPassId;

    isLoading = false;
    error;

    showSelectStaff = true;
    showStaffSchedule = false;
    showConfirmationModal = false;

    lstStaff;
    selectedStaffId;
    staffName;

    wiredAppointmentDays = [];
    allAppointmentDays;

    selectedStaffAppointmentDays;

    appointmentStart;
    appointmentEnd;

    formattedappointmentStart;
    formattedappointmentEnd;

    formattedDate;

    newAppointmentId;

    /*****************************************
     * Returns array of dates with a nested array of availability slots
     * Each day has a staffId and staffName to identify the staff member
     * (Date) row.availabilityDate
     * (String) row.staffId
     * (String) row.staffName
     * (Array) row.availabilitySlots
     *      (DateTime) row.availabilitySlots[0].startTime
     *      (DateTime) row.availabilitySlots[0].endTime
     *****************************************/

     @wire(getAssignedStaffAvailability, { 
		punchPassId: '$punchPassId'
	}) wiredWrappers(result) {
		this.isLoading = true;
		this.wiredAppointmentDays = result;
	
        if (result.data) {
			let rows = JSON.parse( JSON.stringify(result.data) );
            let lstStaffWithDuplicates = [];
            const timeOptions = {
                hour: 'numeric', minute: 'numeric', hour12: true
            };
            const dateOptions = {
                weekday: "long", year: "numeric", month: "numeric", day: "numeric", timeZone: 'UTC'
            };
            rows.forEach(dataParse => {
                // Add staff to list to later de-dupe for staff selection screen
                let staff = {staffId: dataParse.staffId, staffName: dataParse.staffName};
                lstStaffWithDuplicates.push(staff);

                // Format times and dates for rendering
                dataParse.formattedDate = this.formatTime(dataParse.availabilityDate, dateOptions);
                
				dataParse.availabilitySlots.forEach(slot => {
                    if (slot.startTime) {
                        slot.formattedStartTime = this.formatTime(slot.startTime, timeOptions);
                    }
                    if (slot.endTime) {
                        slot.formattedEndTime = this.formatTime(slot.endTime, timeOptions);
                    }
                })
			});

            // De-dupe staff list
            const key = 'staffId';
            this.lstStaff = [...new Map(lstStaffWithDuplicates.map(item => [item[key], item])).values()];

            this.allAppointmentDays = rows;
            this.error = undefined;
			this.isLoading = false;
        } else if (result.error) {
			console.error(result.error);
            this.error = result.error;
            this.allAppointmentDays = undefined;
			this.isLoading = false;
        }
    }

    bookAppointment() {

        this.showConfirmationModal = false;
        this.isLoading = true;
        
        // Guard against no credits available
        if (this.punchPass.Bookable_Credits__c <= 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No credits remaining',
                    message: 'There are no bookable credits remaining for this package',
                    variant: 'error'
                })
            );
            return;
        }
        
        const newAppointmentStatus = 'Scheduled';

        const fields = {};
        fields[CONTACT_FIELD.fieldApiName] = this.punchPass.TREX1__Contact__c;
        fields[STARTDATE_FIELD.fieldApiName] = this.appointmentStart;
        fields[ENDDATE_FIELD.fieldApiName] = this.appointmentEnd;
        fields[STAFF_FIELD.fieldApiName] = this.selectedStaffId;
        fields[STATUS_FIELD.fieldApiName] = newAppointmentStatus;
        fields[MEMBERSHIP_FIELD.fieldApiName] = this.punchPass.Id;
        const recordInput = { 
            apiName: APPOINTMENT_OBJECT.objectApiName, 
            fields 
        };
        createRecord(recordInput)
            .then((appt) => {
                this.newAppointmentId = appt.Id;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Your new appointment has been booked',
                        variant: 'success'
                    })
                );
                refreshApex(this.wiredAppointmentDays);
                this.isLoading = false;
                this.handleCloseEvent();
            })
            .catch((error => {
                console.error(error);
                this.error = error;
                let message = '';
                if (error.body.output.errors) {
                    message = error.body.output.errors[0].message;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating appointment',
                        message: message,
                        variant: 'error'
                    })
                );
                refreshApex(this.wiredAppointmentDays);
                this.selectedStaffAppointmentDays = this.allAppointmentDays.filter(appt => appt.staffId === this.selectedStaffId);
                this.isLoading = false;
                this.showConfirmationModal = false;
                this.handleCloseEvent();
            }))

    }

    goToStaffSchedule(event) {
        this.selectedStaffId = event.target.dataset.recordId;
        this.staffName = this.getStaffName(this.selectedStaffId);

        this.selectedStaffAppointmentDays = this.allAppointmentDays.filter(appt => appt.staffId === this.selectedStaffId);
        this.showSelectStaff = false;
        this.showStaffSchedule = true;
    }

    goToSelectStaff() {
        this.showStaffSchedule = false;
        this.showSelectStaff = true;
    }

    handleCloseEvent() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    onConfirmationCancel() {
        this.showConfirmationModal = false;
    }

    onAppointmentSelect(event) {

        this.showConfirmationModal = true;
        this.appointmentStart = event.target.dataset.startTime;

        const timeOptions = {
            hour: 'numeric', minute: 'numeric', hour12: true
        };
        const dateOptions = {
            weekday: "long", year: "numeric", month: "numeric", day: "numeric", timeZone: 'UTC'
        };

        this.formattedappointmentStart = this.formatTime(this.appointmentStart, timeOptions);
        let endTime = new Date(this.appointmentStart);

        this.formattedDate = this.formatTime(this.appointmentStart, dateOptions);
        
        endTime.setMinutes(endTime.getMinutes() + this.appointmentLength);
        this.appointmentEnd = endTime;
 
    }

    onScrollForward() {
        let appContainer = this.template.querySelector(".appointment-container");
        appContainer.scrollLeft += appContainer.getBoundingClientRect().width;
    }

    onScrollBack() {
        let appContainer = this.template.querySelector(".appointment-container");
        appContainer.scrollLeft -= appContainer.getBoundingClientRect().width;
    }

    /////////////////////////////////////////////
    //                  Utils
    /////////////////////////////////////////////

    formatTime(date, options) {
        let dt = new Date( date );
        return new Intl.DateTimeFormat('en-US', options).format(dt);
    }

    getStaffName(id) {
        for (let i = 0; i < this.lstStaff.length; i++) {
            if (this.lstStaff[i].staffId == id) return this.lstStaff[i].staffName;
        }
    }


}