# Salesforce Development Standards

## Governor Limits - Design for Bulk

Salesforce enforces strict limits per transaction. Always bulkify code, absolutely no queries in loops.

## Trigger Handler Pattern

Never put logic directly in triggers. One trigger per object, use a shared base handler class.

**Base class**: Check for existing `TriggerHandler` in project. If none exists, copy from `templates/salesforce/classes/TriggerHandler.cls`

## SOQL Best Practices

```apex
// ✅ Only needed fields, filtered, with relationship queries
List<Account> accounts = [
    SELECT Id, Name, (SELECT Id, FirstName FROM Contacts)
    FROM Account 
    WHERE Id IN :accountIds
    WITH SECURITY_ENFORCED
];
```

- Always use WHERE clauses and LIMIT when appropriate
- Use `WITH SECURITY_ENFORCED` to respect FLS
- Filter on indexed fields (standard, ExternalId, unique)

## Security - CRUD/FLS Enforcement

**Utility class**: Check for existing `SecurityEnforcer` in project. If none exists, copy from `templates/salesforce/classes/SecurityEnforcer.cls`

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

Use `with sharing` by default, `without sharing` only when explicitly necessary.

## Test Classes (75% Coverage Required)

- Use `@TestSetup` for common data, `Test.startTest()/stopTest()` to reset limits
- Test bulk (200+ records), positive, negative, and boundary cases
- Never use `seeAllData=true`; create isolated test data
- Use `UniversalMocker` for mocking dependencies if available (see `references/UniversalMock/`)

## Sandbox Deployment Workflow

```bash
# Retrieve current metadata first
sf project retrieve start --metadata ApexClass:MyClass

# Validate before deploying
sf project deploy start --source-dir force-app --dry-run

# Deploy with tests
sf project deploy start --source-dir force-app --test-level RunLocalTests
```

## Creating Custom Objects and Fields

When creating a custom object, **always create an accompanying permission set** and add it to the Admin permission set group.

**Required steps for new custom objects:**
1. Create the object metadata
2. Create a permission set granting CRUD access to the object
3. Add the permission set to the Admin PSG (and other relevant PSGs)

For examples of how to structure Salesforce permission sets and permission set groups, see the official Salesforce documentation:

- [Salesforce Metadata API: PermissionSet](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_permissionset.htm)
- [Salesforce Metadata API: PermissionSetGroup](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_permissionsetgroup.htm)

Follow these resources for XML examples and full schema when creating permission set and permission set group metadata files.
When adding fields to existing objects, add field permissions to the relevant permission sets.

## Async Processing

- **Queueable**: Chaining jobs, complex processing
- **Batch Apex**: Large volumes (millions of records)
- **Scheduled Apex**: Recurring jobs
- **Platform Events**: Event-driven architecture

## Error Handling

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

## Logging

Use [NebulaLogger](https://github.com/jongpie/NebulaLogger) for enterprise logging instead of `System.debug()`.

**Install**: See `references/repos.json` for package install commands.

```apex
Logger.error('Error message', record).addTag('MyFeature');
Logger.warn('Warning message');
Logger.info('Info message');
Logger.debug('Debug message');
Logger.saveLog();
```

NebulaLogger provides: persistent logs in `Log__c`/`LogEntry__c`, tagging, Flow support, LWC support, and log retention policies.

## Project Resources

- **Templates**: `templates/salesforce/classes/` - Base classes (TriggerHandler, SecurityEnforcer)
- **References**: `references/` - Cloned repo structures (see `repos.json`, run `scripts/sync-references.sh`)
- **NebulaLogger**: Reference `references/NebulaLogger/` for logging patterns after syncing

When starting a new project, check references for established patterns before creating new structures.

## AI Agent Reminders

1. **Never hardcode Salesforce IDs** - IDs differ between orgs
2. **Check for existing patterns** - Look for handlers, utilities, test factories in project and `references/`
3. **Respect naming conventions** - Follow project's existing patterns
4. **Avoid SOQL in loops** - Most common governor limit violation
5. **Create meta.xml files** - Every Apex class/trigger needs corresponding `-meta.xml`
6. **Use Database methods** - Prefer `Database.insert(records, false)` for partial success
7. **Test data isolation** - Tests create own data, never rely on org data
8. **Retrieve before modify** - Always get current state before making changes
9. **New objects need permission sets** - Create permission set and add to Admin PSG
10. **Use templates and references** - Copy from `templates/` and `references/` before creating from scratch
