import { LightningElement, api } from 'lwc';

export default class CommunityPunchPassesModal extends LightningElement {
	@api modalHeader;
    @api punchPass;
    @api decrements;
	
    showCancel = false;
    showOkay = true;

    get creditSummary() {
        return `Original Value: ${this.punchPass.TREX1__Stored_Value__c} | Credits Used: ${this.punchPass.TREX1__Total_Value__c} | Remaining Value: ${this.punchPass.TREX1__Remaining_Value__c}`;
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