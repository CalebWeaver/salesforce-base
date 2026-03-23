# Wire and Imperative Apex Patterns

## Wire Service (Reactive Reads)

```javascript
import { LightningElement, wire, api } from 'lwc';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

export default class AccountList extends LightningElement {
    @api recordId;
    accounts;
    error;

    @wire(getAccounts, { parentId: '$recordId' })
    wiredAccounts({ data, error }) {
        if (data) {
            this.accounts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accounts = undefined;
        }
    }
}
```

Apex method must be `cacheable=true`:

```apex
@AuraEnabled(cacheable=true)
public static List<Account> getAccounts(Id parentId) {
    return [SELECT Id, Name FROM Account WHERE ParentId = :parentId WITH SECURITY_ENFORCED];
}
```

## Imperative Calls (DML and Controlled Timing)

```javascript
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import activateAccount from '@salesforce/apex/AccountController.activateAccount';

export default class AccountActivator extends LightningElement {
    @api recordId;
    isLoading = false;

    async handleActivate() {
        this.isLoading = true;
        try {
            await activateAccount({ accountId: this.recordId });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Account activated',
                variant: 'success'
            }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'An error occurred',
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }
}
```

## Error Reduction Utility

```javascript
reduceErrors(errors) {
    if (!Array.isArray(errors)) {
        errors = [errors];
    }
    return errors
        .filter(error => !!error)
        .map(error => {
            if (Array.isArray(error.body)) {
                return error.body.map(e => e.message);
            } else if (error.body && typeof error.body.message === 'string') {
                return error.body.message;
            }
            return error.statusText || 'Unknown error';
        })
        .flat();
}
```
