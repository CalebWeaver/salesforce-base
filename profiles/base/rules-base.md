# Salesforce Development Standards

## Governor Limits - Design for Bulk

Salesforce enforces strict limits per transaction. Always bulkify code, absolutely no queries in loops.

## SOQL Best Practices

- Always use WHERE clauses and LIMIT when appropriate
- Use `WITH SECURITY_ENFORCED` to respect FLS
- Filter on indexed fields (standard, ExternalId, unique)
- Never put SOQL inside a loop

See `references/patterns/base/soql-examples.md` for query examples.

## Security - CRUD/FLS Enforcement

Use `SecurityEnforcer` for all CRUD/FLS checks before DML operations. Check for existing `SecurityEnforcer` in project. If none exists, copy from `templates/salesforce/classes/SecurityEnforcer.cls`.

Use `with sharing` by default, `without sharing` only when explicitly necessary.

See `references/patterns/base/security-enforcer.md` for usage examples.

## Test Classes (85% Coverage Required)

Write tests alongside your code from the start — sandbox deployments enforce the 85% coverage gate. Every class gets a corresponding test class.

- Use `@TestSetup` for common data, `Test.startTest()/stopTest()` to reset limits
- Test bulk (200+ records), positive, negative, and boundary cases
- Never use `seeAllData=true`; create isolated test data
- Use `UniversalMocker` for mocking dependencies if available (see `references/UniversalMock/`)

## Salesforce Test Data Standard

Use fluent builders from `templates/salesforce/classes/testsupport/` for in-memory record creation (valid-by-default objects, no DML). Use scenario fixtures for common business states.

**DML layer depends on profile:**
- **Lightweight**: Use `TestDataGraph` for relationship wiring and insert ordering in tests.
- **Enterprise**: Use `Application.UnitOfWork.newInstance()` for test data DML — the same pattern used in production. Do NOT use `TestDataGraph` in enterprise projects.

See `references/patterns/base/test-data-framework.md` for builder and fixture patterns.

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

When adding fields to existing objects, add field permissions to the relevant permission sets.

## Configuration Strategy - When to Use What

Never hardcode configurable values in Apex. Pull them into the appropriate configuration mechanism based on the use case:

| Mechanism | When to Use | Examples |
|-----------|-------------|---------|
| **Custom Metadata Types** | Admin-configurable business rules, feature flags, mappings, thresholds. Deployable, packageable, queryable without SOQL limits. | Integration endpoints, retry counts, field mappings, approval thresholds, feature toggles |
| **Custom Labels** | User-facing text that may need translation or change without deployment. | Error messages, email subjects, notification text, UI labels |
| **Custom Settings (Hierarchy)** | Per-user or per-profile overrides for runtime behavior. | Debug mode per user, bypass flags, user-specific thresholds |
| **Custom Objects** | End-user-managed data that changes frequently and needs a UI for non-admin users. | Pricing tiers, commission rates, territory assignments, routing rules |

### Decision Flow

1. **Does it need translation or is it user-facing text?** → Custom Label
2. **Does it need per-user/profile overrides?** → Hierarchy Custom Setting
3. **Is it admin-managed configuration that deploys across environments?** → Custom Metadata Type
4. **Do end users need to manage it through a UI with full CRUD?** → Custom Object
5. **Is it a simple on/off flag?** → Custom Metadata Type (not a checkbox on a custom setting)

### What NOT to Hardcode

- **Never hardcode**: URLs, endpoints, email addresses, thresholds, retry counts, error messages, field API names used in mappings, record type names, picklist values used in branching logic
- **OK to hardcode**: SObject API names in strongly-typed code, field tokens (`Account.Name`), standard Salesforce constants

## Async Processing

| Pattern | When to Use | Key Limit |
|---------|-------------|-----------|
| **Queueable** | Complex processing, chaining steps, callouts from triggers | 50 per transaction |
| **Batch Apex** | Large data volumes (thousands to millions of records) | 5 concurrent batches |
| **Scheduled Apex** | Recurring jobs on a cron schedule | 100 per org |
| **Platform Events** | Decoupling publishers from subscribers, event-driven | 150K events/hour |
| **Future Methods** | Avoid — prefer Queueable in almost all cases | 50 per transaction |

**Core rules**: always implement `Database.AllowsCallouts` for HTTP callouts; always handle errors (async failures are silent); never enqueue from a loop; use Custom Metadata for batch sizes and retry counts; test with `Test.startTest()/stopTest()`.

For detailed patterns and examples, see `references/async-patterns.md`.

## Lightning Web Components (LWC)

| Decision | Guidance |
|----------|----------|
| **Wire vs Imperative** | Use `@wire` for read-only data that should refresh reactively. Use imperative for DML operations, conditional calls, or when you need control over timing. |
| **Error handling** | Always handle errors in both wire and imperative calls. Display user-facing messages via `lightning/platformShowToastEvent`. |
| **Apex method exposure** | Mark Apex methods `@AuraEnabled(cacheable=true)` for wire-compatible reads. Use `@AuraEnabled` (without cacheable) for DML operations. |
| **Security** | Never trust client-side input — validate and enforce CRUD/FLS in Apex. |
| **Naming** | Components: `camelCase` folder/file names. Apex controllers: match the feature, not the component. |

**Core rules**: keep components small and focused; pull labels from Custom Labels; use `lightning-record-*-form` for simple CRUD before building custom forms; avoid SOQL in LWC controllers — delegate to existing query patterns.

For detailed patterns and examples, see `references/lwc-patterns.md`.

## Error Handling

Use `Database.insert(records, false)` for partial success and iterate `Database.SaveResult` for errors. Use `System.debug()` with appropriate `LoggingLevel` for basic logging. See profile-specific rules for enterprise logging options.

See `references/patterns/base/error-handling.md` for code examples.

## Project Resources

- **Templates**: `templates/salesforce/classes/` - Base classes and utilities
- **References**: `references/` - Cloned repo structures (see `repos.json`, run `scripts/sync-references.sh`)
- **Patterns**: `references/patterns/` - Implementation examples organized by profile

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
11. **Never hardcode configurable values** - Use Custom Metadata Types, Custom Labels, or Custom Settings per the Configuration Strategy section
12. **Read pattern files before implementing** - Check `references/patterns/` for the implementation pattern before writing code
