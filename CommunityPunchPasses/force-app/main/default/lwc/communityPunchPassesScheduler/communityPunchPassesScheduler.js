import { LightningElement, api, wire } from 'lwc';
import getAssignedStaffAvailability from '@salesforce/apex/CommunityPunchPassesController.getAssignedStaffAvailability';

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
                        slot.startTime = new Intl.DateTimeFormat('en-US', options).format(dt);
                    }
                    if (slot.endTime) {
                        let dt = new Date( slot.endTime );
                        slot.endTime = new Intl.DateTimeFormat('en-US', options).format(dt);
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