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
4. Assign the new permission set to the running user so fields are immediately visible:
```bash
sf org assign permset --name <PermSetApiName>
```

For examples of how to structure Salesforce permission sets and permission set groups, see the official Salesforce documentation:

- [Salesforce Metadata API: PermissionSet](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_permissionset.htm)
- [Salesforce Metadata API: PermissionSetGroup](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_permissionsetgroup.htm)

When adding fields to existing objects, add field permissions to the relevant permission sets and redeploy them.

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

## Experience Cloud (Digital Experiences)

Experience Cloud metadata is among the most complex in Salesforce — deployment order matters, ExperienceBundles are large and conflict-prone, and guest user configuration requires coordinating profiles, sharing rules, and permission sets. Always retrieve before modifying, and always read the pattern files before deploying.

| Rule | Details |
|------|---------|
| **Deploy order** | Network + CustomSite must deploy before ExperienceBundle. Full source deploys handle ordering automatically. |
| **Guest user profile** | Auto-named `{Site Label} Profile`. Add object permissions, field-level security, and Apex class access for guest-facing controllers. |
| **Guest user limits** | Guest license only allows Create + Read — no Edit, Delete, View All. Field perms must be `editable: false`. Use `without sharing` Apex for DML. |
| **Sharing for guests** | Guest users belong to `{SiteApiName}_Site_Guest_User` public group. Create criteria-based sharing rules to expose records. |
| **LWR guest access** | Site-level `authenticationType` can't be changed via deploy. Set `"pageAccess": "Public"` on individual route `content.json` files instead. |
| **ExperienceBundle noise** | Add `**/experiences/**/config/**` to `.forceignore` to avoid constant diffs from auto-generated files. |
| **LWR vs Aura metadata** | LWR (Build Your Own) sites use `DigitalExperienceBundle` and `digitalExperiences/` directory. Aura sites use `ExperienceBundle` and `experiences/`. |
| **Retrieve by name** | Use `--metadata ExperienceBundle:SiteName` or `--metadata DigitalExperienceBundle`, not source tracking — source tracking is unreliable for experience bundles. |
| **Publish after deploy** | Run `sf community publish --name "Site Name"` after deploying to make changes live. |

See `references/patterns/base/experience-cloud-metadata.md` for deployment patterns, metadata structure, LWR site setup, and common errors.

See `references/experience-cloud-patterns.md` for LWC exposure, guest user Apex controllers, and community navigation patterns.

## Error Handling

Use `Database.insert(records, false)` for partial success and iterate `Database.SaveResult` for errors. Use `System.debug()` with appropriate `LoggingLevel` for basic logging. See profile-specific rules for enterprise logging options.

See `references/patterns/base/error-handling.md` for code examples.

## Project Documentation

Project-specific context lives in `docs/` — always check these before making architectural decisions or working in an unfamiliar area of the codebase.

- **`docs/project-reference.md`** — **Always read this file at the start of every task.** Contains project-specific conventions, lessons learned, and context that supplements the baseline rules. This is the place for org-specific quirks, team decisions, and hard-won knowledge that doesn't belong in the baseline.
- **`docs/architecture.md`** — Project-level architecture: org topology, data model, integrations, and key architectural decisions. Read this first when joining a project or before making cross-cutting changes.
- **`docs/modules/`** — One file per major module or domain area (e.g., `case-routing.md`, `billing.md`). Describes the module's purpose, key classes, custom objects, automation, and testing notes. Read the relevant module doc before modifying code in that area.
- **`docs/user-stories/`** — One file per user story (e.g., `US-101-case-auto-routing.md`). Contains the story statement, acceptance criteria, technical notes, and dependencies. Read the relevant story file before starting implementation work.

**Keeping docs current**: When you make a significant change — new module, new integration, architectural decision — update the relevant doc. If a module doc doesn't exist yet for the area you're working in, create one.

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
13. **Check project docs first** - Read `docs/architecture.md` and the relevant `docs/modules/` file before working in an unfamiliar area
14. **Update docs when making significant changes** - New modules, integrations, or architectural decisions should be documented in `docs/`
15. **Experience Cloud metadata has strict deployment order** - Read `references/patterns/base/experience-cloud-metadata.md` before modifying site configuration, guest user profiles, or ExperienceBundles
