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
    isLoading = false;
    error;

    showSelectStaff = true;
    showStaffSchedule = false;

    wiredStaff = [];
    lstStaff;

    selectedStaff;
    selectedAvailability;

    appointmentStart;
    appointmentEnd;
    newAppointmentId;

    @wire(getAssignedStaffAvailability, { 
		membershipTypeId: '$membershipTypeId', 
        locationId: '$locationId'
	}) wiredStaffMembers(result) {
		this.isLoading = true;
		this.wiredStaff = result;
	
        if (result.data) {
			let rows = JSON.parse( JSON.stringify(result.data) );
            const options = {
                year: 'numeric', month: 'numeric', day: 'numeric', 
                hour: 'numeric', minute: 'numeric', second: 'numeric', 
                hour12: true
            };
            rows.forEach(dataParse => {
				dataParse.availabilitySlots.forEach(slot => {
                    if (slot.startTime) {
                        let dt = new Date( slot.startTime );
                        slot.formattedStartTime = new Intl.DateTimeFormat('en-US', options).format(dt);
                    }
                    if (slot.endTime) {
                        let dt = new Date( slot.endTime );
                        slot.formattedEndTime = new Intl.DateTimeFormat('en-US', options).format(dt);
                    }
                })
			});
            this.lstStaff = rows;
            this.error = undefined;
			this.isLoading = false;
        } else if (result.error) {
			console.error(result.error);
            this.error = result.error;
            this.lstStaff = undefined;
			this.isLoading = false;
        }
    }


    bookAppointment(event) {
        this.isLoading = true;
        
        const newAppointmentStatus = 'Scheduled';
        this.appointmentStart = event.target.dataset.startTime;
        let endTime = new Date(this.appointmentStart);
        endTime.setMinutes(endTime.getMinutes() + 60);
        this.appointmentEnd = endTime;

        const fields = {};
        fields[CONTACT_FIELD.fieldApiName] = this.punchPass.TREX1__Contact__c;
        fields[STARTDATE_FIELD.fieldApiName] = this.appointmentStart;
        fields[ENDDATE_FIELD.fieldApiName] = this.appointmentEnd;
        fields[STAFF_FIELD.fieldApiName] = this.selectedStaff.staffId;
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
                refreshApex(this.wiredStaff);
                this.isLoading = false;
                this.handleCloseEvent();
            })
            .catch((error => {
                console.error(error);
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: 'Something went wrong. Please refresh the page and try again',
                        variant: 'error'
                    })
                );
                this.isLoading = false;
                this.handleCloseEvent();
            }))

    }

    openStaffSchedule(event) {
        this.selectedStaff = this.lstStaff.find(staff => staff.staffId === event.target.dataset.recordId);
        this.showSelectStaff = false;
        this.showStaffSchedule = true;
    }

    goBackToSelectStaff() {
        this.showStaffSchedule = false;
        this.showSelectStaff = true;
    }

    handleCloseEvent() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleCancelEvent() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleOkayEvent() {
        this.dispatchEvent(new CustomEvent('okay'));
    }

}