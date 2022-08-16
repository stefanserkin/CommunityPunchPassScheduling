import { LightningElement, api } from 'lwc';

export default class ApplicationEnrollmentManagerModal extends LightningElement {
	@api modalHeader;
    @api app;
    @api answeredQuestions;
	@api aqcols;

	get contactInfo() {
		return '<strong>Contact Information</strong><br />' + this.app.transactionContactInfo;
	}

	get dateSubmittedHeader() {
		return '<strong>Date Submitted</strong><br />';
	}

    handleCloseEvent() {
        this.dispatchEvent(new CustomEvent('close'));
    }

	handleRejectEvent() {
		this.dispatchEvent(new CustomEvent('reject'));
	}

	handleOfferEvent() {
		this.dispatchEvent(new CustomEvent('offer'));
	}

}