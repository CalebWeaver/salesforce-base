# Lightning Web Component Patterns

Detailed patterns and examples for LWC development. Referenced from the base rules.

## File Structure

```
force-app/main/default/lwc/
├── accountList/
│   ├── accountList.html
│   ├── accountList.js
│   ├── accountList.css           (optional)
│   ├── accountList.js-meta.xml
│   └── __tests__/                (optional, Jest)
│       └── accountList.test.js
```

- One component per folder, folder name matches component name
- Use `camelCase` for folder/file names: `accountList`, `orderDetail`
- CSS is scoped to the component automatically

## Wire Service (Reactive Reads)

Use `@wire` for data that should refresh automatically when parameters change:

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

Use imperative for DML operations, calls you want to control, or conditional logic:

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

## Error Handling

Always handle errors and show user-friendly messages:

```javascript
// Standard error reducer for wire and imperative
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

## Custom Labels in LWC

Never hardcode user-facing strings:

```javascript
import LABEL_SAVE from '@salesforce/label/c.Button_Save';
import LABEL_ERROR from '@salesforce/label/c.Error_GenericMessage';

export default class MyComponent extends LightningElement {
    label = {
        save: LABEL_SAVE,
        error: LABEL_ERROR
    };
}
```

```html
<template>
    <lightning-button label={label.save} onclick={handleSave}></lightning-button>
</template>
```

## Use Standard Components First

Before building custom forms, check if standard components work:

```html
<!-- Simple record view — no Apex needed -->
<lightning-record-view-form record-id={recordId} object-api-name="Account">
    <lightning-output-field field-name="Name"></lightning-output-field>
    <lightning-output-field field-name="Industry"></lightning-output-field>
</lightning-record-view-form>

<!-- Simple record edit — handles CRUD/FLS automatically -->
<lightning-record-edit-form record-id={recordId} object-api-name="Account"
    onsuccess={handleSuccess}>
    <lightning-input-field field-name="Name"></lightning-input-field>
    <lightning-input-field field-name="Industry"></lightning-input-field>
    <lightning-button type="submit" label="Save"></lightning-button>
</lightning-record-edit-form>
```

## Component Communication

| Pattern | When to Use |
|---------|-------------|
| `@api` properties | Parent → Child data passing |
| Custom events | Child → Parent communication |
| Lightning Message Service | Unrelated components on the same page |
| Platform Events | Cross-context (Apex to LWC via emp API) |

```javascript
// Child dispatches custom event
this.dispatchEvent(new CustomEvent('accountselected', {
    detail: { accountId: this.selectedId }
}));

// Parent listens
// <c-account-list onaccountselected={handleAccountSelected}></c-account-list>
handleAccountSelected(event) {
    this.selectedAccountId = event.detail.accountId;
}
```

## Meta XML Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/09/metadata">
    <apiVersion>59.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
        <target>lightning__AppPage</target>
        <target>lightning__HomePage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>Account</object>
            </objects>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

## Lightweight Profile: LWC + Apex

LWC controllers can be simple Apex classes with `@AuraEnabled` methods. No need for a formal service layer:

```apex
public with sharing class AccountController {

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(Id parentId) {
        SecurityEnforcer.checkReadable(Account.SObjectType, new List<SObjectField>{Account.Name});
        return [SELECT Id, Name FROM Account WHERE ParentId = :parentId];
    }

    @AuraEnabled
    public static void activateAccount(Id accountId) {
        SecurityEnforcer.checkUpdateable(Account.SObjectType);
        Account acc = [SELECT Id, Status__c FROM Account WHERE Id = :accountId];
        acc.Status__c = 'Active';
        update acc;
    }
}
```

## Enterprise Profile: LWC + FFLib Service Layer

LWC controllers should be thin wrappers that delegate to Service methods:

```apex
public with sharing class AccountController {

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(Id parentId) {
        return AccountsSelector.newInstance().selectByParentId(new Set<Id>{parentId});
    }

    @AuraEnabled
    public static void activateAccount(Id accountId) {
        AccountService.activateAccounts(new Set<Id>{accountId});
    }
}
```

Rules for enterprise LWC controllers:
- Controllers are thin — one-line delegation to Service or Selector
- Read operations call Selectors directly (cacheable)
- Write operations call Service methods
- Never put business logic in the controller
- Register nothing in `Application.cls` for controllers — they're not a formal FFLib layer

## Testing LWC

Use Jest for component-level tests:

```javascript
import { createElement } from 'lwc';
import AccountList from 'c/accountList';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

// Mock Apex
jest.mock('@salesforce/apex/AccountController.getAccounts', () => ({
    default: jest.fn()
}), { virtual: true });

describe('c-account-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders accounts from wire', async () => {
        getAccounts.mockResolvedValue([
            { Id: '001xx000003ABCABC', Name: 'Acme' }
        ]);

        const element = createElement('c-account-list', { is: AccountList });
        document.body.appendChild(element);

        // Wait for async DOM updates
        await Promise.resolve();

        const items = element.shadowRoot.querySelectorAll('li');
        expect(items.length).toBe(1);
        expect(items[0].textContent).toBe('Acme');
    });
});
```

## What NOT to Do

- Don't put business logic in LWC JavaScript — keep it in Apex
- Don't skip error handling on Apex calls
- Don't hardcode strings — use Custom Labels
- Don't use `@wire` for DML operations
- Don't build custom forms when `lightning-record-edit-form` works
- Don't expose Apex methods without CRUD/FLS enforcement
