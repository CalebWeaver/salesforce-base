# SecurityEnforcer Usage

Check for existing `SecurityEnforcer` in project. If none exists, copy from `templates/salesforce/classes/SecurityEnforcer.cls`.

## Permission Checks Before Operations

```apex
// Check permissions before operations
SecurityEnforcer.checkReadable(Account.SObjectType, new List<SObjectField>{Account.Name});
SecurityEnforcer.checkCreatable(Account.SObjectType, new List<SObjectField>{Account.Name});

// Strip inaccessible fields for DML
List<Account> safeRecords = (List<Account>) SecurityEnforcer.stripInaccessible(AccessType.CREATABLE, accounts);
insert safeRecords;

// Boolean checks for conditional logic
if (SecurityEnforcer.isUpdateable(Account.SObjectType)) { /* update */ }
```

## When to Use

- `checkReadable` / `checkCreatable` / `checkUpdateable` — before DML operations, throws exception if user lacks access
- `stripInaccessible` — silently removes fields the user can't access, returns safe records for DML
- `isReadable` / `isUpdateable` — boolean checks for conditional logic (when you don't want to throw)

## Rules

- Use `with sharing` by default, `without sharing` only when explicitly necessary
- Always enforce CRUD/FLS before any DML operation
