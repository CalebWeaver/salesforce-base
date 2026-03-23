---
name: trigger-handler
description: Lightweight architecture for this project — TriggerHandler pattern, no service or domain layers, and when to extract logic into utility classes.
---

## Architecture

This project uses a **lightweight architecture** without FFLib. Keep things simple and direct.

Never put logic directly in triggers. One trigger per object, using a shared base handler class. Logic lives directly in handlers — no service or domain layers.

Check for existing `TriggerHandler` in project. If none exists, copy from `templates/salesforce/classes/TriggerHandler.cls`.

## Guidelines

- **No service layer required** — business logic lives directly in trigger handlers or utility classes
- **No domain layer** — validation and field defaults go in trigger handlers
- **No selector layer** — SOQL queries can live in handlers or simple query helper classes
- **Keep it flat** — avoid unnecessary abstraction layers for small projects
- **DataAccessor** is available if you need testable query isolation, but it's optional

## Trigger Handler Pattern

```apex
// Trigger file (one per object)
trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    new AccountTriggerHandler().run();
}

// Handler file
public class AccountTriggerHandler extends TriggerHandler {
    protected override void beforeInsert() {
        for (Account acc : (List<Account>) Trigger.new) {
            if (acc.Name == null) {
                acc.addError('Name is required');
            }
        }
    }
}
```

Rules:
- Never put logic directly in triggers
- One trigger per object — register all events in the trigger, handle them in the handler
- If a handler grows beyond ~200 lines, extract logic into a focused utility class
- Don't pre-create service/domain/selector layers "just in case"

## When to Add Abstraction

If a handler grows beyond ~200 lines, extract logic into a focused utility class. Don't pre-create service/domain/selector layers "just in case."

## Async in Lightweight Projects

Async classes are standalone — they query, process, and DML directly. No service layer routing needed. Enqueue from trigger handlers. See `/build-async` for full examples.

## Configuration Access

Query Custom Metadata Types directly in Apex — no accessor class needed for this profile. Cache results in static variables when a method is called multiple times in the same transaction.

```apex
private static Map<String, Integration_Config__mdt> integrationConfigs;

public static Integration_Config__mdt getIntegrationConfig(String developerName) {
    if (integrationConfigs == null) {
        integrationConfigs = new Map<String, Integration_Config__mdt>();
        for (Integration_Config__mdt config : Integration_Config__mdt.getAll().values()) {
            integrationConfigs.put(config.DeveloperName, config);
        }
    }
    return integrationConfigs.get(developerName);
}
```

Custom Labels:

```apex
String errorMsg = System.Label.Error_AccountNameRequired;
```

Hierarchy Custom Settings:

```apex
My_Settings__c settings = My_Settings__c.getInstance();
if (settings.Debug_Mode__c) {
    System.debug('Debug info...');
}
```

Config rules:
- Keep configuration access simple
- If you find yourself creating a dedicated configuration class, make it a single static utility
- Don't create a service/selector pattern for configuration in lightweight projects

## LWC Controllers

LWC controllers are simple Apex classes with `@AuraEnabled` methods — no service layer delegation needed. Business logic can live directly in the controller for small components.

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

- `@AuraEnabled(cacheable=true)` for read-only methods (wire-compatible)
- `@AuraEnabled` (without cacheable) for DML operations
- Use `WITH SECURITY_ENFORCED` in controller SOQL
- No service layer delegation needed

See `/build-lwc` for full LWC component patterns.

## What NOT to Do

- Don't create `fflib_*` classes or patterns — this project intentionally avoids FFLib
- Don't create UnitOfWork patterns — use `Database.insert/update/delete` directly
- Don't create Selector classes unless you genuinely need query testability for a specific case
- Don't create Domain classes — trigger handlers own validation and field logic
