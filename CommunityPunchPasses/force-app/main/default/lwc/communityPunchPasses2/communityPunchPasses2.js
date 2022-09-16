import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getActivePunchPassesByContact from '@salesforce/apex/CommunityPunchPassesController.getActivePunchPassesByContact';
import getCompletedPunchPassesByContact from '@salesforce/apex/CommunityPunchPassesController.getCompletedPunchPassesByContact';
import getTransactionReceiptId from '@salesforce/apex/CommunityPunchPassesController.getTransactionReceiptId';

import { loadStyle } from 'lightning/platformResourceLoader';
import modalStyle from '@salesforce/resourceUrl/modalWide';

import USER_ID from '@salesforce/user/Id';
import CONTACTID_FIELD from '@salesforce/schema/User.ContactId';
import ACCOUNTID_FIELD from '@salesforce/schema/User.AccountId';
import ACCOUNTNAME_FIELD from '@salesforce/schema/User.Account.Name';


export default class CommunityPunchPasses2 extends NavigationMixin(LightningElement) {

	constructor() {
        super();
        this.cols = [
			{ label: 'Package', fieldName: 'TREX1__Type__c', type: 'text', hideDefaultActions: true },
			{ label: 'Used', fieldName: 'Effectively_Used_Credits__c', type: 'number', hideDefaultActions: true,
				cellAttributes: { 
					alignment: 'left' 
				}
			},
			{ label: 'Remaining', fieldName: 'Bookable_Credits__c', type: 'number', hideDefaultActions: true,
				cellAttributes: { 
					alignment: 'left' 
				}
			},
			{ label: 'Expiration Date', fieldName: 'TREX1__End_Date__c', type: 'date', hideDefaultActions: true, 
				typeAttributes:{
					year: "numeric",
					month: "long",
					day: "2-digit"
				}
			},
			{
				type: 'action',
				typeAttributes: { rowActions: this.getRowActions }
			}
		];
    }

	getRowActions(row, doneCallback) {
		if (row.showScheduleAppointmentAction) {
			doneCallback([
				{ label: 'Download Receipt', name: 'download_receipt', iconName: 'action:download' },
				{ label: 'View Appointments', name: 'view_appointments', iconName: 'action:preview' },
				{ label: 'Schedule Appointment', name: 'schedule_appointment', iconName: 'action:new_event' }
			]);

		} else {
			doneCallback([
				{ label: 'Download Receipt', name: 'download_receipt', iconName: 'action:download' },
				{ label: 'View Appointments', name: 'view_appointments', iconName: 'action:preview' }
			]);
		}
    }

	// Load wide modal css from static resource
	connectedCallback() {
		Promise.all([
			 loadStyle(this, modalStyle)
		 ])
	}

	@api cardIcon;
	@api membershipCategoryNames = '';
	@api packageReferenceNameSingular = '';
	@api packageReferenceNamePlural = '';
	@api showNavigationButton;
	@api navigationButtonLabel;
	@api navigationButtonIcon;
	@api navigationButtonUrl;
	@api openNavigationUrlInNewTab;
	@api enableAppointmentScheduling = false;
	@api cancellationHoursNotice;

	cols;

	isLoading = false;
	error;

	showModal = false;
	modalContent;
	appointments = [];

	showScheduler = false;

	contactId;
	accountId;
	accountName;

	contactsWithActivePunchPasses;
	wiredContactsWithActivePunchPasses = [];
	contactsWithCompletedPunchPasses;
	wiredContactsWithCompletedPunchPasses = [];

	numHouseholdActivePunchPasses;
	numHouseholdCompletedPunchPasses;

	selectedPunchPass;
	selectedPunchPassId;
	selectedMembershipTypeId;
	selectedLocationId;
	selectedAppointmentLength;
	selectedReceiptId = '';

	get noPunchPassActivityDescription() {
		return 'No ' + this.packageReferenceNameSingular + ' Data';
	}

	get noActivePunchPassesDescription() {
		return 'No Active ' + this.packageReferenceNamePlural;
	}

	get noCompletedPunchPassesDescription() {
		return 'No Completed ' + this.packageReferenceNamePlural;
	}

	get noActivePunchPassesDescriptionContact() {
		return 'This contact does not have any active ' + this.packageReferenceNamePlural;
	}

	get noCompletedPunchPassesDescriptionContact() {
		return 'This contact does not have any completed ' + this.packageReferenceNamePlural;
	}

	get cardTitle() {
		return this.accountName != null ? this.packageReferenceNamePlural + ' for ' + this.accountName : this.packageReferenceNamePlural;
	}

	get activePunchPassesSectionLabel() {
		return 'Active ' + this.packageReferenceNamePlural + ' (' + this.numHouseholdActivePunchPasses + ')';
	}

	get completedPunchPassesSectionLabel() {
		return 'Completed ' + this.packageReferenceNamePlural + ' (' + this.numHouseholdCompletedPunchPasses + ')';
	}

	get householdHasPunchPassActivity() {
		return (this.numHouseholdActivePunchPasses != null && this.numHouseholdActivePunchPasses > 0) || 
			(this.numHouseholdCompletedPunchPasses != null && this.numHouseholdCompletedPunchPasses > 0) ? 
			true : 
			false;
	}

	get householdHasActivePunchPasses() {
		return this.numHouseholdActivePunchPasses != null && this.numHouseholdActivePunchPasses > 0 ? true : false;
	}

	get householdHasCompletedPunchPasses() {
		return this.numHouseholdCompletedPunchPasses != null && this.numHouseholdCompletedPunchPasses > 0 ? true : false;
	}

	@wire(getRecord, {
		recordId: USER_ID,
		fields: [CONTACTID_FIELD, ACCOUNTID_FIELD, ACCOUNTNAME_FIELD]
	}) wireuser({
		error,
		data
	}) {
		if (error) {
			this.error = error; 
		} else if (data) {
			this.contactId = data.fields.ContactId.value;
			this.accountId = data.fields.AccountId.value;
			this.accountName = getFieldValue(data, ACCOUNTNAME_FIELD);
		}
	}

	@wire(getActivePunchPassesByContact, { 
		accountId: '$accountId',
		strMembershipCategoryNames: '$membershipCategoryNames'
	}) wiredActivePunchPasses(result) {
		this.isLoading = true;
		this.wiredContactsWithActivePunchPasses = result;
		this.numHouseholdActivePunchPasses = 0;
	
        if (result.data) {
			let rows = JSON.parse( JSON.stringify(result.data) );
			rows.forEach(dataParse => {
				let label = '';
				dataParse.fullName = dataParse.FirstName + ' ' + dataParse.LastName;
				dataParse.numActivePunchPasses = 
					dataParse.TREX1__Memberships__r != null && dataParse.TREX1__Memberships__r.length > 0 ?
					dataParse.TREX1__Memberships__r.length :
					0;
				label = dataParse.fullName + ' - ' + dataParse.numActivePunchPasses;
				label += dataParse.numActivePunchPasses == 1 ?
					' Active ' + this.packageReferenceNameSingular :
					' Active ' + this.packageReferenceNamePlural;
				dataParse.sectionLabel = label;
				dataParse.TREX1__Memberships__r.forEach(element => {
					if (
						this.enableAppointmentScheduling && 
						element.Bookable_Credits__c != null && 
						element.Bookable_Credits__c > 0
					) {
						element.showScheduleAppointmentAction = true;
					} else {
						element.showScheduleAppointmentAction = false;
					}
					element.duration = element.TREX1__memb_Type__r.Appointment_Length__c;
				});
				this.numHouseholdActivePunchPasses += dataParse.numActivePunchPasses;
			}); 
            this.contactsWithActivePunchPasses = rows;
            this.error = undefined;
			this.isLoading = false;
        } else if (result.error) {
			console.error(result.error);
            this.error = result.error;
            this.contactsWithActivePunchPasses = undefined;
			this.isLoading = false;
        }
    }

	@wire(getCompletedPunchPassesByContact, { 
		accountId: '$accountId',
		strMembershipCategoryNames: '$membershipCategoryNames'
	}) wiredCompletedPunchPasses(result) {
		this.isLoading = true;
		this.wiredContactsWithCompletedPunchPasses = result;
		this.numHouseholdCompletedPunchPasses = 0;
	
        if (result.data) {
			let rows = JSON.parse( JSON.stringify(result.data) );
			for (let i = 0; i < rows.length; i++) {
                let dataParse = rows[i];
				let label = '';
				dataParse.fullName = dataParse.FirstName + ' ' + dataParse.LastName;
				dataParse.numCompletedPunchPasses = 
					dataParse.TREX1__Memberships__r != null && dataParse.TREX1__Memberships__r.length > 0 ?
					dataParse.TREX1__Memberships__r.length :
					0;
				label = dataParse.fullName + ' - ' + dataParse.numCompletedPunchPasses;
				label += dataParse.numCompletedPunchPasses == 1 ?
					' Completed ' + this.packageReferenceNameSingular :
					' Completed ' + this.packageReferenceNamePlural;
				dataParse.sectionLabel = label;
				this.numHouseholdCompletedPunchPasses += dataParse.numCompletedPunchPasses;
			}
            this.contactsWithCompletedPunchPasses = rows;
            this.error = undefined;
			this.isLoading = false;
        } else if (result.error) {
            this.error = result.error;
            this.contactsWithCompletedPunchPasses = undefined;
			this.isLoading = false;
        }
    }

	handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
		const transactionId = row.TREX1__Purchasing_Transaction__c;
        switch (actionName) {
            case 'download_receipt':
                this.downloadReceipt(transactionId);
                break;
			case 'view_appointments':
				this.viewAppointments(row);
				break;
			case 'schedule_appointment':
				this.scheduleAppointment(row);
				break;
            default:
        }
    }

	scheduleAppointment(row) {
		this.selectedPunchPass = row;
		this.selectedMembershipTypeId = row.TREX1__memb_Type__c;
		this.selectedLocationId = row.TREX1__memb_Type__r.TREX1__Location__c;
		this.selectedAppointmentLength = row.TREX1__memb_Type__r.Appointment_Length__c;
		this.showScheduler = true;
	}

	handleShowScheduler() {
		this.showModal = false;
		this.showScheduler = true;
	}

	downloadReceipt(transactionId) {

		getTransactionReceiptId({ transactionId: transactionId })
            .then((result) => {
                this.selectedReceiptId = result;
				let baseUrl = this.getBaseUrl();
				let downloadUrl = baseUrl+'servlet/servlet.FileDownload?file='+this.selectedReceiptId;
				this[NavigationMixin.Navigate]({
						type: 'standard__webPage',
						attributes: {
							url: downloadUrl
						}
					}, false 
				);
                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;
                this.selectedReceiptId = undefined;
            });

    }

	viewAppointments(row) {
		this.selectedPunchPass = row;
		this.selectedMembershipTypeId = row.TREX1__memb_Type__c;
		this.selectedLocationId = row.TREX1__memb_Type__r.TREX1__Location__c;
		this.selectedAppointmentLength = row.TREX1__memb_Type__r.Appointment_Length__c;
		this.showModal = true;
	}

	getBaseUrl(){
        let baseUrl = 'https://'+location.host+'/';
        return baseUrl;
    }

	showHelpInfo() {
		alert(`Click the dropdown arrow to the right of any row to access available actions. Download receipt, view appointment history, or schedule new appointments for an active package.`);
	}

	handleModalClose() {
        this.showModal = false;
		if (this.showScheduler) {
			this.showScheduler = false;
			this.isLoading = true;
			this.refreshComponent();
			this.isLoading = false;
		}
    }

	get targetBehavior() {
		return this.openNavigationUrlInNewTab ? '_blank' : '_self';
	}

	handleNavigationButton() {
		if (this.navigationButtonUrl != null) {
			this[NavigationMixin.GenerateUrl]({
				type: 'standard__webPage',
				attributes: {
					url: this.navigationButtonUrl
				}
			}).then(generatedUrl => {
				window.open(generatedUrl, this.targetBehavior);
			});
		}
	}

	refreshComponent() {
		this.isLoading = true;
		refreshApex(this.wiredContactsWithActivePunchPasses);
		refreshApex(this.wiredContactsWithCompletedPunchPasses);
		this.isLoading = false;
	}


}