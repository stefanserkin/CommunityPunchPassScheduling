import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getAppointmentsFromMembership from '@salesforce/apex/CommunityPunchPassesController.getAppointmentsFromMembership';

import ID_FIELD from '@salesforce/schema/Appointment__c.Id';
import STATUS_FIELD from '@salesforce/schema/Appointment__c.Status__c';
import CANCEL_DATE_FIELD from '@salesforce/schema/Appointment__c.Cancellation_Date__c';

const INITIAL_WIDTH = '25%';

const SCHEDULED_COLS = [
    { label: 'Start Date', fieldName: 'Start_DateTime__c', type: 'date', initialWidth: INITIAL_WIDTH, hideDefaultActions: true, 
        typeAttributes: {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        }
    },
    { label: 'Instructor', fieldName: 'staffName', type: 'text', initialWidth: INITIAL_WIDTH, hideDefaultActions: true},
    { label: 'Status', fieldName: 'Status__c', type: 'text', initialWidth: INITIAL_WIDTH, hideDefaultActions: true},
    {  
        type: 'button',
        initialWidth: INITIAL_WIDTH, 
        typeAttributes: {
            label: 'Cancel', 
            name: 'Cancel', 
            variant: 'destructive-text', 
            iconName: 'action:close', 
            disabled: { fieldName: 'disableCancel' },
        }
    }
];

const COMPLETE_COLS = [
    { label: 'Start Date', fieldName: 'Start_DateTime__c', type: 'date', initialWidth: INITIAL_WIDTH, hideDefaultActions: true, 
        typeAttributes: {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        }
    },
    { label: 'Instructor', fieldName: 'staffName', type: 'text', initialWidth: INITIAL_WIDTH, hideDefaultActions: true},
    { label: 'Status', fieldName: 'Status__c', type: 'text', initialWidth: INITIAL_WIDTH, hideDefaultActions: true},
    { label: 'Attended', fieldName: 'Attended__c', type: 'boolean', hideDefaultActions: true}
];

const CANCELLED_COLS = [
    { label: 'Start Date', fieldName: 'Start_DateTime__c', type: 'date', initialWidth: INITIAL_WIDTH, hideDefaultActions: true, 
        typeAttributes: {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        }
    },
    { label: 'Instructor', fieldName: 'staffName', type: 'text', initialWidth: INITIAL_WIDTH, hideDefaultActions: true},
    { label: 'Status', fieldName: 'Status__c', type: 'text', initialWidth: INITIAL_WIDTH, hideDefaultActions: true},
    { label: 'Cancellation Date', fieldName: 'cancellationDate', type: 'date', hideDefaultActions: true, 
        typeAttributes: {
            day: 'numeric',
            month: 'short',
            year: 'numeric'
        }
    },
];

export default class CommunityPunchPassesModal extends LightningElement {

    @api punchPass;
    @api cancellationHoursNotice;

    error;
    isLoading = false;

    scheduledCols = SCHEDULED_COLS;
    completeCols = COMPLETE_COLS;
    cancelledCols = CANCELLED_COLS;

    wiredAppointments = [];
    appointments;
    scheduledAppointments;
    completeAppointments;
    cancelledAppointments;

    selectedAppointmentId;

    get hasBookableAppointments() {
        return this.punchPass.Bookable_Credits__c > 0 ? true : false;
    }

    get creditSummary() {
        return `Original Value: ${this.punchPass.TREX1__Stored_Value__c} | Credits Used: ${this.punchPass.Effectively_Used_Credits__c} | Remaining Value: ${this.punchPass.Bookable_Credits__c}`;
    }

    get cancellationPolicy() {
        return `${this.cancellationHoursNotice} hours-notice is required for all cancellations`;
    }

    @wire(getAppointmentsFromMembership, { 
		membership: '$punchPass'
	}) wiredAppointmentList(result) {
		this.isLoading = true;
		this.wiredAppointments = result;
	
        if (result.data) {
			let rows = JSON.parse( JSON.stringify(result.data) );
            const options = {
                year: 'numeric', month: 'numeric', day: 'numeric', 
                hour: 'numeric', minute: 'numeric', second: 'numeric', 
                hour12: true
            };
            
			rows.forEach(dataParse => {
				let label = '';
                if (dataParse.Start_DateTime__c) {
                    let dt = new Date( dataParse.Start_DateTime__c );
                    dataParse.formattedStartTime = new Intl.DateTimeFormat('en-US', options).format(dt);
                }
                if (dataParse.End_DateTime__c) {
                    let dt = new Date( dataParse.End_DateTime__c );
                    dataParse.formattedEndTime = dt.toLocaleTimeString();
                }
                label += dataParse.formattedStartTime + ' - ' + 
                    dataParse.formattedEndTime + 
                    ' with ' + dataParse.Staff__r.Name + 
                    ' (' + dataParse.Status__c + ')';
                dataParse.label = label;

                dataParse.staffName = dataParse.Staff__r.Name;

                let earliestCancelTime = new Date();
                let appointmentStartTime = new Date(dataParse.Start_DateTime__c);
                earliestCancelTime.setHours(earliestCancelTime.getHours() + this.cancellationHoursNotice);

                let cancelDate = new Date(dataParse.Cancellation_Date__c);
                cancelDate.setDate(cancelDate.getDate() + 1);
                dataParse.cancellationDate = cancelDate;

                if (
                    appointmentStartTime >= earliestCancelTime && 
                    dataParse.Status__c == 'Scheduled'
                ) {
                    dataParse.isCancellable = true;
                } else {
                    dataParse.isCancellable = false;
                }
                dataParse.disableCancel = !dataParse.isCancellable;

			}); 
            // this.appointments = rows;
            this.scheduledAppointments = rows.filter(appt => appt.Status__c === 'Scheduled');
            this.completeAppointments = rows.filter(appt => appt.Status__c === 'Complete');
            this.cancelledAppointments = rows.filter(appt => appt.Status__c === 'Cancelled');
            this.error = undefined;
			this.isLoading = false;
        } else if (result.error) {
			console.error(result.error);
            this.error = result.error;
            this.appointments = undefined;
			this.isLoading = false;
        }
    }

    handleCancelAppointment(event) {
        this.isLoading = true;
        this.selectedAppointmentId = event.detail.row.Id;

        let today = new Date().toISOString().slice(0, 10);
        
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.selectedAppointmentId;
        fields[STATUS_FIELD.fieldApiName] = 'Cancelled';
        fields[CANCEL_DATE_FIELD.fieldApiName] = today;
        const recordInput = {
            fields: fields
        };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "The appointment has been cancelled",
                        variant: "success"
                    })
                );
                refreshApex(this.wiredAppointments);
                this.isLoading = false;
            })
            .catch((error) => {
                console.error(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Cancellation Error",
                        message: "Could not cancel appointment. Please contact us to make updates.",
                        variant: "error"
                    })
                );
                this.isLoading = false;
            });

    }

    // Controls the height of the datatable based on the number of records
    get setScheduledDatatableHeight() {
        if (this.numScheduledAppointments == 0) {
            return 'height:2rem;';
        }
        else if (this.numScheduledAppointments > 10) {
            return 'height:50rem;';
        }
        return '';
    }

    get setCompleteDatatableHeight() {
        if (this.numCompleteAppointments == 0) {
            return 'height:2rem;';
        }
        else if (this.numCompleteAppointments > 10) {
            return 'height:50rem;';
        }
        return '';
    }

    get setCancelledDatatableHeight() {
        if (this.numCancelledAppointments == 0) {
            return 'height:2rem;';
        }
        else if (this.numCancelledAppointments > 10) {
            return 'height:50rem;';
        }
        return '';
    }

    get numScheduledAppointments() {
        return this.scheduledAppointments != null && this.scheduledAppointments.length > 0 ? this.scheduledAppointments.length : 0;
    }

    get numCompleteAppointments() {
        return this.completeAppointments != null && this.completeAppointments.length > 0 ? this.completeAppointments.length : 0;
    }

    get numCancelledAppointments() {
        return this.cancelledAppointments != null && this.cancelledAppointments.length > 0 ? this.cancelledAppointments.length : 0;
    }

    get hasScheduledAppointments() {
        return this.numScheduledAppointments > 0 ? true : false;
    }

    get hasCompleteAppointments() {
        return this.numCompleteAppointments > 0 ? true : false;
    }

    get hasCancelledAppointments() {
        return this.numCancelledAppointments > 0 ? true : false;
    }

    handleCloseEvent() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showScheduler() {
        this.dispatchEvent(new CustomEvent('gotoscheduler'));
    }

}
