---
name: configure-values
description: How to handle configurable values in this project — when to use Custom Metadata Types, Custom Labels, Custom Settings, or Custom Objects instead of hardcoding.
---

## Never Hardcode Configurable Values

Never hardcode configurable values in Apex. Pull them into the appropriate configuration mechanism based on the use case.

| Mechanism | When to Use | Examples |
|-----------|-------------|---------|
| **Custom Metadata Types** | Admin-configurable business rules, feature flags, mappings, thresholds. Deployable, packageable, queryable without SOQL limits. | Integration endpoints, retry counts, field mappings, approval thresholds, feature toggles |
| **Custom Labels** | User-facing text that may need translation or change without deployment. | Error messages, email subjects, notification text, UI labels |
| **Custom Settings (Hierarchy)** | Per-user or per-profile overrides for runtime behavior. | Debug mode per user, bypass flags, user-specific thresholds |
| **Custom Objects** | End-user-managed data that changes frequently and needs a UI for non-admin users. | Pricing tiers, commission rates, territory assignments, routing rules |

## Decision Flow

1. **Does it need translation or is it user-facing text?** → Custom Label
2. **Does it need per-user/profile overrides?** → Hierarchy Custom Setting
3. **Is it admin-managed configuration that deploys across environments?** → Custom Metadata Type
4. **Do end users need to manage it through a UI with full CRUD?** → Custom Object
5. **Is it a simple on/off flag?** → Custom Metadata Type (not a checkbox on a custom setting)

## What NOT to Hardcode

- **Never hardcode**: URLs, endpoints, email addresses, thresholds, retry counts, error messages, field API names used in mappings, record type names, picklist values used in branching logic
- **OK to hardcode**: SObject API names in strongly-typed code, field tokens (`Account.Name`), standard Salesforce constants
