# LWC Controller (POC)

Controllers do everything — query, process, DML, all in the `@AuraEnabled` method. No service layer, no selector, no domain. No security enforcement needed in scratch orgs.

```apex
public class FR_CaseController {
    @AuraEnabled(cacheable=true)
    public static List<Case> getOpenCases(Id accountId) {
        return [SELECT Id, Subject, Status, Priority FROM Case WHERE AccountId = :accountId AND IsClosed = false];
    }

    @AuraEnabled
    public static void escalateCase(Id caseId) {
        Case c = [SELECT Id, Priority FROM Case WHERE Id = :caseId];
        c.Priority = 'High';
        update c;
    }
}
```

## Rules

- `@AuraEnabled(cacheable=true)` for read-only methods — fast page loads for demos
- `@AuraEnabled` (without cacheable) for DML operations
- Skip `WITH SECURITY_ENFORCED` — causes permission errors in unconfigured scratch orgs
- `without sharing` is fine for POC controllers
- No service layer delegation needed
