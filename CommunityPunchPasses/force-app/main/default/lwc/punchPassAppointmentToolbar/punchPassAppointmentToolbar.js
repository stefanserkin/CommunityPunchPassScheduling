import { LightningElement, api, wire } from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { loadStyle } from 'lightning/platformResourceLoader';
import getPunchPassById from '@salesforce/apex/CommunityPunchPassesController.getPunchPassById';
import modalStyle from '@salesforce/resourceUrl/modalWide';

export default class PunchPassAppointmentToolbar extends LightningElement {

    @api recordId;

    // Load wide modal css from static resource
	connectedCallback() {
		Promise.all([
		    loadStyle(this, modalStyle)
		]);
	}

    isLoading = false;
    error;

    showScheduler = false;
    showCancelModal = false;

    wiredMembership;
    membership;
    membershipTypeId;
    locationId;
    appointmentLength = 0;
    cancellationHoursNotice = 0;

    @wire(getPunchPassById, { 
		membershipId: '$recordId'
	}) wiredRecord(result) {
		this.isLoading = true;
		this.wiredMembership = result;
        if (result.data) {
            const mem = result.data;
            this.membership = mem;
            this.membershipTypeId = mem.TREX1__memb_Type__c;
            this.locationId = mem.TREX1__memb_Type__r.TREX1__Location__c;
            this.appointmentLength = mem.TREX1__memb_Type__r.Appointment_Length__c;
            this.cancellationHoursNotice = mem.TREX1__memb_Type__r.Cancellation_Hours_Notice_Required__c;
            this.error = undefined;
			this.isLoading = false;
        } else if (result.error) {
			console.error(result.error);
            this.error = result.error;
            this.membership = undefined;
			this.isLoading = false;
        }
    }

    get hasAppointmentsToSchedule() {
        return this.membership != null && this.membership.Bookable_Credits__c > 0 ? true : false;
    }

    handleOpenScheduler() {
        this.showCancelModal = false;
        this.showScheduler = true;
    }

    handleOpenCancelModal() {
        this.showCancelModal = true;
        this.showScheduler = false;
    }

    handleModalClose() {
        getRecordNotifyChange([{recordId: this.recordId}]);
        refreshApex(this.wiredMembership);
        eval("$A.get('e.force:refreshView').fire();");
        this.showCancelModal = false;
		this.showScheduler = false;
    }

}