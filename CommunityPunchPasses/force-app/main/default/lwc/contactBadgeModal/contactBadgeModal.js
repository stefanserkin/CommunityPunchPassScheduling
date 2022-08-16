import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ContactBadgeModal extends NavigationMixin(LightningElement) {
    modalHeader = 'Badge Details';
    @track recordid;
    @track badge;
    @track obj;
    @track label;
    @api fieldset = [];
    showCancel = false;
    showOkay = true;

    @api
    get selectedbadge() {
        return this.badge;
    }
    set selectedbadge(value) {
        this.badge = value;
    }

    @api
    get contactid() {
        return this.recordid;
    }
    set contactid(value) {
        this.recordid = value;
    }

    @api
    get object() {
        return this.obj;
    }
    set object(value) {
        this.obj = value;
    }

    @api
    get objlabel() {
        return this.label;
    }
    set objlabel(value) {
        this.label = value;
    }

    get isContactBadge() {
        return this.badge == this.recordid ? true : false;
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

    handleGoToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.badge,
                objectApiName: this.obj,
                actionName: 'view'
            }
        });
    }

}