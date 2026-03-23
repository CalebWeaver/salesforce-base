---
name: write-apex
description: Entry point for Apex development in this project — governor limits, SOQL, security, error handling, logging, and pointers to specific skill areas like async, LWC, and testing.
---

## Governor Limits — Design for Bulk

Always bulkify code. Absolutely no SOQL or DML inside loops. Design every method to handle 200+ records.

## SOQL Best Practices

- Always use WHERE clauses and LIMIT when appropriate
- Filter on indexed fields (standard, ExternalId, unique)
- Never put SOQL inside a loop

```apex
// ✅ Only needed fields, filtered, with relationship queries
List<Account> accounts = [
    SELECT Id, Name, (SELECT Id, FirstName FROM Contacts)
    FROM Account
    WHERE Id IN :accountIds
];
```

### FLS in SOQL — `WITH USER_MODE` vs `WITH SECURITY_ENFORCED`

Only apply FLS enforcement in SOQL when the query runs in a **user-facing context** (`with sharing` or `inherited sharing` classes exposed to user input). Do not apply it in system-context classes.

- `WITH USER_MODE` — preferred (API v56+); enforces CRUD, FLS, and sharing rules; throws `QueryException` if user lacks field access
- `WITH SECURITY_ENFORCED` — legacy; enforces FLS only; use if org API version is below 56

```apex
// ✅ User-facing controller or inherited sharing service — enforce FLS
List<Account> accounts = [
    SELECT Id, Name FROM Account WHERE Id IN :accountIds WITH USER_MODE
];

// ✅ System-context class (background job, cross-ownership query) — no FLS clause needed
List<Account> accounts = [
    SELECT Id, Name FROM Account WHERE Id IN :accountIds
];
```

Do not use `WITH SECURITY_ENFORCED` or `WITH USER_MODE` in `without sharing` classes — it is semantically inconsistent and can produce unexpected field-access errors.

## Security — Sharing and CRUD/FLS Enforcement

### Sharing declarations

Choose the sharing keyword based on the class's role, and document the reason at the class level when it isn't obvious:

| Keyword | When to use |
|---------|-------------|
| `inherited sharing` | Default for service, selector, and utility classes — inherits context from the caller |
| `with sharing` | Explicit for UI-facing controllers and entry points that must always respect sharing |
| `without sharing` | System-context operations: background jobs, cross-ownership queries, assignment logic, admin utilities |

`without sharing` is a normal, legitimate choice — not a red flag. Document why at the class header when non-obvious.

```apex
// UI-facing controller — always enforce sharing
public with sharing class AccountController { }

// Service layer — inherit sharing from whatever called it
public inherited sharing class AccountService { }

// Background job — system context, sharing is irrelevant or actively wrong
// without sharing: processes records across owners as part of nightly sync
public without sharing class AccountSyncQueueable implements Queueable { }
```

### CRUD/FLS for DML

Use `SecurityEnforcer` for CRUD/FLS checks before DML in user-facing classes. Check for existing `SecurityEnforcer` in project. If none exists, copy from `templates/salesforce/classes/SecurityEnforcer.cls`.

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

- `checkReadable` / `checkCreatable` / `checkUpdateable` — before DML operations, throws exception if user lacks access
- `stripInaccessible` — silently removes fields the user can't access, returns safe records for DML
- `isReadable` / `isUpdateable` — boolean checks for conditional logic (when you don't want to throw)

Skip `SecurityEnforcer` in `without sharing` system-context classes — they intentionally bypass user permissions.

## Error Handling

Use `Database.insert(records, false)` for partial success. The second parameter (`false`) means allOrNothing is disabled — some records can succeed while others fail.

```apex
List<Database.SaveResult> results = Database.insert(accounts, false);
for (Integer i = 0; i < results.size(); i++) {
    if (!results[i].isSuccess()) {
        for (Database.Error err : results[i].getErrors()) {
            System.debug(LoggingLevel.ERROR, 'Error: ' + err.getMessage());
        }
    }
}
```

- **`Database.insert(records, false)`** — when processing a batch and some failures are acceptable
- **`insert records`** (allOrNothing) — when all records must succeed or none should

## Logging

Use `System.debug()` with appropriate `LoggingLevel`:

```apex
System.debug(LoggingLevel.ERROR, 'Error processing record: ' + record.Id);
System.debug(LoggingLevel.WARN, 'Unexpected state: ' + detail);
System.debug(LoggingLevel.INFO, 'Processing complete: ' + count + ' records');
System.debug(LoggingLevel.DEBUG, 'Variable value: ' + value);
```

Enterprise projects using NebulaLogger should invoke `/nebula-logger` instead.

## Creating Custom Objects and Fields

When creating a custom object, always create an accompanying permission set and add it to the Admin permission set group.

1. Create the object metadata
2. Create a permission set granting CRUD access to the object
3. Add the permission set to the Admin PSG (and other relevant PSGs)
4. Add field permissions to relevant permission sets when adding fields to existing objects

Every Apex class and trigger needs a corresponding `-meta.xml` file.

## Specific Skill Areas

| Task | Skill |
|------|-------|
| Writing tests, test data builders, fixtures, mocking | `/write-tests` |
| Deploying to sandboxes, permission set assignment | `/deploy` |
| Configuring values — CMDT, custom labels, custom settings | `/configure-values` |
| Async jobs — queueable, batch, scheduled, platform events | `/build-async` |
| Lightning Web Components | `/build-lwc` |
| Experience Cloud sites and guest user access | `/build-for-experience-cloud` |
| Project docs — architecture, modules, user stories | `/use-project-docs` |

## Key Reminders

- **Never hardcode Salesforce IDs** — IDs differ between orgs
- **Check for existing patterns** — look for handlers, utilities, and query helpers before creating new ones
- **Respect naming conventions** — follow the project's existing patterns
- **Avoid SOQL in loops** — most common governor limit violation
- **Create meta.xml files** — every Apex class/trigger needs a corresponding `-meta.xml`
- **Use Database methods** — prefer `Database.insert(records, false)` for partial success
- **Never hardcode configurable values** — use Custom Metadata Types, Custom Labels, or Custom Settings (see `/configure-values`)
