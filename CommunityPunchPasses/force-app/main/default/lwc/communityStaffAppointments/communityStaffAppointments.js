import { LightningElement, wire } from 'lwc';
import getUpcomingStaffAppointments from '@salesforce/apex/CommunityStaffAppointmentsController.getUpcomingStaffAppointments';

import USER_ID from '@salesforce/user/Id';

const COLS = [
    { label: 'Appt Id', fieldName: 'Id', type: 'text', hideDefaultActions: true },
    { label: 'Package', fieldName: 'membershipType', type: 'text', hideDefaultActions: true },
    { label: 'Start Date', fieldName: 'Start_DateTime__c', type: 'date', fixedWidth: 144, hideDefaultActions: true, 
        typeAttributes:{
            year: "numeric",
            month: "long",
            day: "2-digit"
        }
    },
    { label: 'Status', fieldName: 'Status__c', type: 'text', fixedWidth: 144, hideDefaultActions: true }
];

export default class CommunityStaffAppointments extends LightningElement {
    isLoading = false;
    error;

    cardTitle = 'Upcoming Appointments';

    userId = USER_ID;
    cols = COLS;

    wiredAppointments = [];
    staffWithAppointments;

    @wire(getUpcomingStaffAppointments, {
        userId: '$userId'
    }) wiredAppts(result) {
        console.log('user id when entering wire function: ' + this.userId);
        this.isLoading = true;
        this.wiredAppointments = result;

        if (result.data) {
            let rows = JSON.parse( JSON.stringify(result.data) );
            
            rows.forEach(dataParse => {
                console.table(dataParse.Appointments__r);
                
				dataParse.Appointments__r.forEach(appt => {
                    appt.membershipType = appt.Membership__r.TREX1__Type__c != null ?
                        appt.Membership__r.TREX1__Type__c :
                        '';
                });
                
			}); 
            
            this.staffWithAppointments = rows;
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            console.error(result.error);
            this.staffWithAppointments = undefined;
            this.error = result.error;
            this.isLoading = false;
        }
    }

}