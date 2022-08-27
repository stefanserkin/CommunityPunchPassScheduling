import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from "lightning/uiRecordApi";
import { refreshApex } from '@salesforce/apex';
import getAppointmentsFromMembership from '@salesforce/apex/CommunityPunchPassesController.getAppointmentsFromMembership';

import ID_FIELD from "@salesforce/schema/Appointment__c.Id";
import STATUS_FIELD from "@salesforce/schema/Appointment__c.Status__c";

const COLS = [
    { label: 'Start Date', fieldName: 'Start_DateTime__c', type: 'date', hideDefaultActions: true, 
        typeAttributes: {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        }
    },
    { label: 'Instructor', fieldName: 'staffName', type: 'text', hideDefaultActions: true},
    { label: 'Status', fieldName: 'Status__c', type: 'text', hideDefaultActions: true},
    {  
        type: 'button',
        initialWidth: 180, 
        typeAttributes: {
            label: 'Cancel', 
            name: 'Cancel', 
            iconName: 'action:close', 
            disabled: { fieldName: 'disableCancel'},
        }
    }
];

export default class CommunityPunchPassesModal2 extends LightningElement {

    @api punchPass;
    @api cancellationHoursNotice;

    error;
    isLoading = false;

    cols = COLS;

    wiredAppointments = [];
    appointments;

    selectedAppointmentId;

    get hasBookableAppointments() {
        return true;
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
            this.appointments = rows;
            this.error = undefined;
			this.isLoading = false;
        } else if (result.error) {
			console.error(result.error);
            this.error = result.error;
            this.appointments = undefined;
			this.isLoading = false;
        }
    }

    handleRowAction(event) {
        this.isLoading = true;
        this.selectedAppointmentId = event.detail.row.Id;
        
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.selectedAppointmentId;
        fields[STATUS_FIELD.fieldApiName] = 'Cancelled';
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

    handleCloseEvent() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showScheduler() {
        this.dispatchEvent(new CustomEvent('gotoscheduler'));
    }

}