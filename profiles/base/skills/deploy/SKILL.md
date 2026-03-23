---
name: deploy
description: How to deploy to Salesforce sandboxes — retrieve/deploy commands, test levels, and permission set assignment after deploying new objects or fields.
disable-model-invocation: true
---

## Sandbox Deployment Workflow

```bash
# Retrieve current metadata first
sf project retrieve start --metadata ApexClass:MyClass

# Validate before deploying
sf project deploy start --source-dir force-app --dry-run

# Deploy with tests
sf project deploy start --source-dir force-app --test-level RunLocalTests
```

Always retrieve before modifying metadata. Get current org state before making changes.

## Permission Set Assignment After Deploy

When deploying new custom objects or fields, assign the relevant permission set to the running user so fields are immediately visible:

```bash
sf org assign permset --name <PermSetApiName>
```

For new custom objects:
1. Create the object metadata
2. Create a permission set granting CRUD access to the object
3. Add the permission set to the Admin PSG (and other relevant PSGs)
4. Assign the permission set to the running user

When adding fields to existing objects, add field permissions to the relevant permission sets and redeploy them.

## Key Reminders

- **Retrieve before modify** — always get current state before making changes
- **New objects need permission sets** — create permission set and add to Admin PSG
- **Assign after deploy** — run `sf org assign permset` so fields are visible immediately
