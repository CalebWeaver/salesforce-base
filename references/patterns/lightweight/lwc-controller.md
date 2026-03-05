# LWC Controller (Lightweight)

Controllers are simple Apex classes with `@AuraEnabled` methods — no service layer delegation needed. Business logic can live directly in the controller for small components.

```apex
public with sharing class AccountController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(Id parentId) {
        return [SELECT Id, Name FROM Account WHERE ParentId = :parentId WITH SECURITY_ENFORCED];
    }

    @AuraEnabled
    public static void activateAccount(Id accountId) {
        Account acc = [SELECT Id, Status__c FROM Account WHERE Id = :accountId WITH SECURITY_ENFORCED];
        acc.Status__c = 'Active';
        update acc;
    }
}
```

## Rules

- `@AuraEnabled(cacheable=true)` for read-only methods (wire-compatible)
- `@AuraEnabled` (without cacheable) for DML operations
- Use `WITH SECURITY_ENFORCED` in controller SOQL
- Business logic can live directly in the controller for small components
- No service layer delegation needed

See `references/lwc-patterns.md` for full LWC component patterns.
