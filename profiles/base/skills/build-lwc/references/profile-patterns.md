# Profile-Specific LWC + Apex Patterns

## Lightweight: Simple Apex Controllers

LWC controllers are simple Apex classes with `@AuraEnabled` methods. No service layer needed:

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

## Enterprise: Thin Controllers Delegating to Service Layer

Controllers are one-line delegations. Read operations call Selectors; write operations call Service methods. Never put business logic in the controller:

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

Note: Don't register controllers in `Application.cls` — they're not a formal FFLib layer.

## Jest Testing

```javascript
import { createElement } from 'lwc';
import AccountList from 'c/accountList';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

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
            { Id: '001000000000001AAA', Name: 'Acme' }
        ]);

        const element = createElement('c-account-list', { is: AccountList });
        document.body.appendChild(element);

        await Promise.resolve();

        const items = element.shadowRoot.querySelectorAll('li');
        expect(items.length).toBe(1);
        expect(items[0].textContent).toBe('Acme');
    });
});
```
