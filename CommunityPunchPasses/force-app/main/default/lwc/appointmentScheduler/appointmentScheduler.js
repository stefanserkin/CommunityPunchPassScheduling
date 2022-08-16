import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from "lightning/navigation";

export default class AppointmentScheduler extends LightningElement {
	cardTitle = 'Appointment Scheduler'
	@track displayText;

	@track membershipId;

	@wire(CurrentPageReference)
	getStateParameters(currentPageReference) {
		if (currentPageReference && currentPageReference.state.c__mt) {
			this.memTypeId = currentPageReference.state.c__mem;
		}
	}



}