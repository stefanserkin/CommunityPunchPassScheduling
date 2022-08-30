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

export default class CommunityPunchPassesScheduler2 extends LightningElement {
    @api punchPass;
    @api membershipTypeId;
    @api locationId;
    @api appointmentLength;

    isLoading = false;
    error;

    showSelectStaff = true;
    showStaffSchedule = false;

    lstStaff;
    selectedStaffId;

    wiredAppointmentDays = [];
    allAppointmentDays;

    selectedStaffAppointmentDays;

    appointmentStart;
    appointmentEnd;
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
		membershipTypeId: '$membershipTypeId', 
        locationId: '$locationId', 
        appointmentLength: '$appointmentLength'
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
                year: "numeric", month: "numeric", day: "numeric"
            };
            rows.forEach(dataParse => {
                // Add staff to list to later de-dupe for staff selection screen
                let staff = {staffId: dataParse.staffId, staffName: dataParse.staffName};
                lstStaffWithDuplicates.push(staff);

                let d = new Date(dataParse.availabilityDate);
                dataParse.formattedDate = new Intl.DateTimeFormat('en-US', dateOptions).format(d);
                
				dataParse.availabilitySlots.forEach(slot => {
                    if (slot.startTime) {
                        let dt = new Date( slot.startTime );
                        slot.formattedStartTime = new Intl.DateTimeFormat('en-US', timeOptions).format(dt);
                    }
                    if (slot.endTime) {
                        let dt = new Date( slot.endTime );
                        slot.formattedEndTime = new Intl.DateTimeFormat('en-US', timeOptions).format(dt);
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

    bookAppointment(event) {
        this.isLoading = true;
        
        const newAppointmentStatus = 'Scheduled';
        this.appointmentStart = event.target.dataset.startTime;
        let endTime = new Date(this.appointmentStart);
        endTime.setMinutes(endTime.getMinutes() + this.appointmentLength);
        this.appointmentEnd = endTime;

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

    goToStaffSchedule(event) {
        this.selectedStaffId = event.target.dataset.recordId;
        console.log('selected staff id is ' + this.selectedStaffId);
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


}