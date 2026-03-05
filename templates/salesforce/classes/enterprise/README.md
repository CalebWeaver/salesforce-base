# Enterprise Templates (FFLib)

These templates are used with the **enterprise** profile and require FFLib Apex Common and FFLib Apex Mocks to be installed in the org.

## Files

| File | Purpose |
|------|---------|
| `Application.cls` | Central factory for UnitOfWork, Selector, Domain, and Service DI |
| `AppConfigSelector.cls` | FFLib selector for Custom Metadata Type config access with caching |

## Prerequisites

Install FFLib packages before deploying these classes:

```bash
# FFLib Apex Common (install first)
sf package install --wait 20 --security-type AdminsOnly --package 04t6S000001IhOQQA0

# FFLib Apex Mocks
sf package install --wait 20 --security-type AdminsOnly --package 04t6S000001IhObQAK
```

Or clone from source (see `references/repos.json` and run `./scripts/sync-references.sh`).

## Adding New Objects

For every new SObject, create all FFLib layers and register in `Application.cls`:

1. Create `{PluralName}.cls` (Domain) extending `fflib_SObjectDomain`
2. Create `{PluralName}Selector.cls` extending `fflib_SObjectSelector`
3. Create `I{Name}Service.cls` (interface) and `{Name}Service.cls` (implementation)
4. Register all in `Application.cls` factory maps
5. Create trigger using `fflib_SObjectDomain.triggerHandler()`
