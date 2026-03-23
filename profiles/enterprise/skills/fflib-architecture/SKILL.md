---
name: fflib-architecture
description: FFLib Domain-Service-Selector-UnitOfWork architecture patterns for this enterprise project — layer responsibilities, naming conventions, Application factory, and how to implement new features.
---

## Architecture

All code follows: **Trigger → Domain → Service → Selector**, with an Application factory managing dependency injection.

| Layer | Responsibility |
|-------|---------------|
| **Domain** | Trigger delegation, validation (`onValidate`), field defaults (`onBeforeInsert`, etc.) |
| **Service** | Business logic and orchestration. Only layer that uses Unit of Work for DML. |
| **Selector** | All SOQL lives here. Never write inline SOQL outside of Selectors. |
| **Application** | Singleton factory registering all Domain, Selector, Service, and UnitOfWork bindings. |

## Naming Conventions

| Layer | Naming | Example |
|-------|--------|---------|
| Domain | Plural object name | `Accounts`, `Opportunities` |
| Selector | Plural + "Selector" | `AccountsSelector`, `OpportunitiesSelector` |
| Service | Singular + "Service" | `AccountService`, `OpportunityService` |
| Service Interface | "I" + Service name | `IAccountService` |
| Application | `Application` (singleton) | `Application.cls` |

## Implementing New Features

For every new SObject or feature, create all layers:
1. **Domain** class with Constructor inner class
2. **Selector** class with field list and custom query methods
3. **Service** class (with interface) for business operations
4. **Register** all classes in `Application.cls`
5. **Trigger** using `fflib_SObjectDomain.triggerHandler()`
6. **Permission set** granting CRUD and field access — add to Admin PSG and assign to running user
7. **Tests** using `fflib_ApexMocks` for layer isolation

For every new Custom Metadata Type, create a config selector:
1. Selector class extending `fflib_SObjectSelector` with `getAll()` caching
2. Register in `Application.cls` Selector factory
3. Consume through `newInstance()` in services — never inline queries

## Trigger → Domain

```apex
// Trigger (one per object)
trigger AccountTrigger on Account (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    fflib_SObjectDomain.triggerHandler(Accounts.class);
}

// Domain class
public class Accounts extends fflib_SObjectDomain {
    public Accounts(List<Account> records) {
        super(records);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new Accounts(records);
        }
    }

    public override void onBeforeInsert() {
        for (Account acc : (List<Account>) Records) {
            if (acc.Industry == null) {
                acc.Industry = 'Other';
            }
        }
    }

    public override void onValidate() {
        for (Account acc : (List<Account>) Records) {
            if (acc.Name == null || acc.Name.length() < 2) {
                acc.addError('Account name must be at least 2 characters');
            }
        }
    }
}
```

## Service Layer

```apex
public class AccountService {

    public static void activateAccounts(Set<Id> accountIds) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        List<Account> accounts = AccountsSelector.newInstance().selectById(accountIds);

        for (Account acc : accounts) {
            acc.Status__c = 'Active';
            acc.ActivatedDate__c = Date.today();
            uow.registerDirty(acc);
        }

        uow.commitWork();
    }
}
```

## Selector Layer

```apex
public class AccountsSelector extends fflib_SObjectSelector {

    public static AccountsSelector newInstance() {
        return (AccountsSelector) Application.Selector.newInstance(Account.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Account.Id,
            Account.Name,
            Account.Industry,
            Account.Status__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return Account.SObjectType;
    }

    public List<Account> selectById(Set<Id> ids) {
        return (List<Account>) selectSObjectsById(ids);
    }

    public List<Account> selectByIndustry(String industry) {
        return (List<Account>) Database.query(
            newQueryFactory()
                .setCondition('Industry = :industry')
                .toSOQL()
        );
    }
}
```

## Application Factory

```apex
public class Application {

    public static final fflib_Application.UnitOfWorkFactory UnitOfWork =
        new fflib_Application.UnitOfWorkFactory(
            new List<SObjectType>{
                Account.SObjectType,
                Contact.SObjectType,
                Opportunity.SObjectType
            }
        );

    public static final fflib_Application.SelectorFactory Selector =
        new fflib_Application.SelectorFactory(
            new Map<SObjectType, Type>{
                Account.SObjectType => AccountsSelector.class,
                Contact.SObjectType => ContactsSelector.class
            }
        );

    public static final fflib_Application.DomainFactory Domain =
        new fflib_Application.DomainFactory(
            Application.Selector,
            new Map<SObjectType, Type>{
                Account.SObjectType => Accounts.Constructor.class,
                Contact.SObjectType => Contacts.Constructor.class
            }
        );

    public static final fflib_Application.ServiceFactory Service =
        new fflib_Application.ServiceFactory(
            new Map<Type, Type>{
                IAccountService.class => AccountService.class
            }
        );
}
```

## LWC Controller (Enterprise)

Thin wrappers that delegate to Service and Selector layers — no business logic in controllers:

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

## Async in Enterprise Projects

Async classes delegate to Service methods and use Unit of Work for DML — they don't query or DML directly. Enqueue from Service methods or Domain classes, never from Selectors.

## Configuration Selectors

All Custom Metadata Type access goes through dedicated Selectors registered in `Application.cls`, keeping configuration reads mockable and testable.

```apex
// Register in Application.cls Selector factory
App_Config__mdt.SObjectType => AppConfigSelector.class,
Feature_Flag__mdt.SObjectType => FeatureFlagSelector.class,
```

Consuming configuration in services:

```apex
AppConfigSelector configSelector = AppConfigSelector.newInstance();
String threshold = configSelector.getValue('Approval_Threshold', '10000');

FeatureFlagSelector flagSelector = FeatureFlagSelector.newInstance();
if (!flagSelector.isEnabled('Enhanced_Validation')) {
    return;
}
```

Mocking config in tests:

```apex
fflib_ApexMocks mocks = new fflib_ApexMocks();
AppConfigSelector mockConfig = (AppConfigSelector) mocks.mock(AppConfigSelector.class);

mocks.startStubbing();
mocks.when(mockConfig.sObjectType()).thenReturn(App_Config__mdt.SObjectType);
mocks.when(mockConfig.getValue('Approval_Threshold', '10000')).thenReturn('5000');
mocks.stopStubbing();

Application.Selector.setMock(mockConfig);
```

Config selector naming:

| Custom Metadata Type | Selector Class |
|---------------------|----------------|
| `App_Config__mdt` | `AppConfigSelector` |
| `Feature_Flag__mdt` | `FeatureFlagSelector` |
| `Integration_Config__mdt` | `IntegrationConfigSelector` |
| `Field_Mapping__mdt` | `FieldMappingSelector` |

## What NOT to Do

- Don't write SOQL outside of Selector classes
- Don't perform DML outside of Unit of Work — including test setup
- Don't put business logic in Domain classes — they handle validation and field defaults only
- Don't skip the Service layer for "simple" operations
- Don't use the lightweight TriggerHandler pattern — use `fflib_SObjectDomain.triggerHandler()`
- Don't query CMDTs inline — use config selectors registered in `Application.cls`
- Don't skip the selector "because it's just config" — testability matters
- Don't create a single "god config" CMDT — group by domain (integration, features, mappings)
