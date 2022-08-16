import { LightningElement, api, wire } from 'lwc';
import getAssignedStaff from '@salesforce/apex/CommunityPunchPassesController.getAssignedStaff';

export default class CommunityPunchPassesScheduler extends LightningElement {
    @api punchPass;
    @api membershipTypeId;
    isLoading = false;
    error;

    showSelectInstructor = false;

    wiredStaff = [];
    lstStaff;

    selectedStaff;

    @wire(getAssignedStaff, { 
		membershipTypeId: '$membershipTypeId'
	}) wiredStaffMembers(result) {
		this.isLoading = true;
		this.wiredStaff = result;
	
        if (result.data) {
			let rows = JSON.parse( JSON.stringify(result.data) );
			console.table(rows);
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
        const staffData = event.target.dataset;
        this.selectedStaff = staffData.name;
        alert('Okay! A schedule for ' + this.selectedStaff + ' coming right up...');
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