import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getStaffAppointments from '@salesforce/apex/CommunityStaffAppointmentsController.getStaffAppointments';
import checkInAppointments from '@salesforce/apex/CommunityStaffAppointmentsController.checkInAppointments';
import cancelAppointments from '@salesforce/apex/CommunityStaffAppointmentsController.cancelAppointments';

import USER_ID from '@salesforce/user/Id';

/* Appointment statuses */
const STATUSES = ['Scheduled','Complete','Cancelled'];

/* Datatable columns */
const COLS = [
    { label: 'Date', fieldName: 'startTime', type: 'date', hideDefaultActions: true, 
        typeAttributes:{
            year: "numeric", 
            month: "long", 
            day: "2-digit", 
            hour: 'numeric', 
            minute: 'numeric', 
            hour12: true
        }
    },
    { label: 'Athlete', fieldName: 'athlete', type: 'text', hideDefaultActions: true },
    { label: 'Lesson Type', fieldName: 'membershipCategory', type: 'text', hideDefaultActions: true },
    { label: 'Phone', fieldName: 'primaryPhone', type: 'phone', hideDefaultActions: true }, 
    { label: 'Email', fieldName: 'primaryEmail', type: 'email', hideDefaultActions: true }, 
    { label: 'Attended', fieldName: 'isAttended', type: 'boolean', hideDefaultActions: true }
];

export default class CommunityStaffAppointments extends LightningElement {
    isLoading = false;
    error;

    cardTitle = 'My Appointments';

    activeStatus = this.firstStatus;
    activeTab = 1;

    userId = USER_ID;
    cols = COLS;
    statuses = STATUSES;

    wiredAppointments = [];
    allAppointments;
    filteredAppointments;
    selectedAppointments = [];

    /* Tab navigation and card actions */

	get tabs() {
        const tabs = [];
        for (let i = 0; i < this.numOfTabs; i++) {
            tabs.push({
                value: `${i}`,
                label: `${this.statuses[i]}`,
                header: `${this.statuses[i]} Appointments`,
            });
        }
        return tabs;
    }

	get numOfTabs() {
		return this.statuses != null && this.statuses.length > 0 ? this.statuses.length : 0;
	}

    handleActiveTab(event) {
        this.activeTab = event.target.value;
		this.activeStatus = `${event.target.label}`;
		this.filteredAppointments = [];
		if (this.allAppointments != null && this.allAppointments.length > 0) {
			this.filteredAppointments = this.allAppointments.filter(row => row.status === this.activeStatus);
		}
        // Data is sorted by start time ascending. Reverse for complete and cancelled.
        if (this.activeStatus === 'Complete' || this.activeStatus === 'Cancelled') {
            this.filteredAppointments = this.filteredAppointments.reverse();
        }
        console.table(this.filteredAppointments);
    }

    get firstStatus() {
        return this.statuses != null && this.statuses.length > 0 ? this.statuses[0] : 'All';
    }

    get showCheckIn() {
        return this.activeStatus != null && this.activeStatus == 'Complete' ? true : false;
    }

    get showCancel() {
        return this.activeStatus != null && this.activeStatus == 'Scheduled' ? true : false;
    }

    /* Wire staff appointments */

    @wire(getStaffAppointments, {
        userId: '$userId'
    }) wiredAppts(result) {
        this.isLoading = true;
        this.wiredAppointments = result;

        if (result.data) {
            let rows = JSON.parse( JSON.stringify(result.data) );
            
            this.allAppointments = rows;
            this.filteredAppointments = rows.filter(row => row.status === this.activeStatus);
            // Data is sorted by start time ascending. Reverse for complete and cancelled.
            if (this.activeStatus === 'Complete' || this.activeStatus === 'Cancelled') {
                this.filteredAppointments = this.filteredAppointments.reverse();
            }

            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            console.error(result.error);
            this.allAppointments = undefined;
            this.error = result.error;
            this.isLoading = false;
        }
    }

    /* Datatable selection */

    getSelected(event) {
        let selectedRows = event.detail.selectedRows;
        if (this.selectedAppointments.length > 0) {
            let selectedIds = selectedRows.map(row => row.id);
            let unselectedRows = this.selectedAppointments.filter(row => !selectedIds.includes(row.id));
            console.log(unselectedRows);
        }
        this.selectedAppointments = selectedRows;
    }

    /* Button actions */

    handleCheckIn() {
        if (this.selectedAppointments.length == 0) {
            alert(`Please select an appointment to check in`);
            return;
        }

        this.isLoading = true;

        let appIds = [];
        this.selectedAppointments.forEach(app => {
            appIds.push(app.id);
        });

        /**
         * Should have some sort of modal guard here - confirm
         */

        checkInAppointments({lstAppointmentIds: appIds})
            .then((result) => {
                const lstFailedCheckinIds = result;
                var toastMessage;
                var toastVariant;
                var toastTitle;

                let lstAlreadyCheckedIn = [];
                lstAlreadyCheckedIn = this.selectedAppointments.filter(item => item.isAttended);
                console.table(lstAlreadyCheckedIn);

                if (lstFailedCheckinIds.length == 0) {
                    toastMessage = 'Appointments were successfully checked in';
                    toastVariant = 'success';
                    toastTitle = 'Success!';
                } else if (lstFailedCheckinIds.length < this.selectedAppointments.length) {
                    toastMessage = 'Eligible appointments were successfully checked in. Some records were either already checked in or have no remaining credits';
                    toastVariant = 'success';
                    toastTitle = 'Success!';
                } else {
                    toastMessage = 'Check the records and try again';
                    toastVariant = 'error';
                    toastTitle = 'Failed to check in records';
                }

                const toastEvent = new ShowToastEvent({
                    title: toastTitle,
                    message: toastMessage,
                    variant: toastVariant
                });
                this.dispatchEvent(toastEvent);
                refreshApex(this.wiredAppointments);
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
            });

    }

    handleCancel() {

        /**
         * Should have some sort of modal guard here - confirm
         */

        if (this.selectedAppointments.length == 0) {
            alert(`Please select at least one appointment to cancel`);
            return;
        }

        this.isLoading = true;

        let appIds = [];
        this.selectedAppointments.forEach(app => {
            appIds.push(app.id);
        });

        cancelAppointments({lstAppointmentIds: appIds})
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'The appointment(s) were successfully cancelled',
                        variant: 'success'
                    })
                );
                refreshApex(this.wiredAppointments);
                this.isLoading = false;
            })
            .catch((error) => {
                this.error = error;
                this.isLoading = false;
            })
    }

    refreshComponent() {
		this.isLoading = true;
		refreshApex(this.wiredAppointments);
		this.isLoading = false;
	}

}