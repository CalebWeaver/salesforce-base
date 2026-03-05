# FFLib Architecture Patterns

All new features must follow the Domain-Service-Selector-UnitOfWork pattern.

## Trigger → Domain

Triggers delegate to Domain classes, NOT directly to service methods or handler logic.

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

Business logic and orchestration lives in Service classes. Services are the only layer that should use Unit of Work for DML.

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

All SOQL lives in Selector classes. Never write inline SOQL outside of selectors.

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

Register all Domain, Selector, Service, and UnitOfWork bindings in the Application class.

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

Thin wrappers that delegate to Service and Selector layers — no business logic in controllers.

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

## Naming Conventions

| Layer | Naming | Example |
|-------|--------|---------|
| Domain | Plural object name | `Accounts`, `Opportunities` |
| Selector | Plural + "Selector" | `AccountsSelector`, `OpportunitiesSelector` |
| Service | Singular + "Service" | `AccountService`, `OpportunityService` |
| Service Interface | "I" + Service name | `IAccountService` |
| Application | `Application` (singleton) | `Application.cls` |
