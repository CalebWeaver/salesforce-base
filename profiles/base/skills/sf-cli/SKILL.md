---
name: sf-cli
description: Working with the Salesforce sf CLI — correct modern commands, deprecated patterns to avoid, and common LLM mistakes.
---

## Always Use `sf`, Never `sfdx`

`sfdx` commands and all `force:` namespace commands were removed from `sf` (v2) in November 2024. Always use the `sf` executable with the unified command syntax.

```bash
# CORRECT
sf project deploy start --source-dir force-app --target-org myalias
sf project retrieve start --metadata ApexClass:MyClass --target-org myalias
sf org login web --alias myalias
sf org list
sf org open --target-org myalias
sf apex run --file scripts/apex/seed.apex --target-org myalias
sf data query --query "SELECT Id FROM Account LIMIT 5" --target-org myalias

# WRONG — these commands no longer exist
sfdx force:source:deploy -p force-app
sf force:source:retrieve -m ApexClass:MyClass
sfdx force:auth:web:login
```

## Common LLM Mistakes to Avoid

| Wrong (old) | Correct (current) |
|---|---|
| `sfdx force:source:deploy` | `sf project deploy start` |
| `sfdx force:source:retrieve` | `sf project retrieve start` |
| `sfdx force:mdapi:deploy` | `sf project deploy start` |
| `sfdx force:auth:web:login` | `sf org login web` |
| `sfdx force:org:list` | `sf org list` |
| `sf force:apex:execute` | `sf apex run` |
| `--targetusername` / `-u` | `--target-org` / `-o` |
| `--sourcepath` | `--source-dir` |
| `--targetdevhubusername` | `--target-dev-hub` |
| `org login device` | `sf org login jwt` (headless) or `sf org login web` |

## Deploy/Retrieve

```bash
# Deploy with tests
sf project deploy start --source-dir force-app --test-level RunLocalTests --target-org myalias

# Dry run (validate only)
sf project deploy start --source-dir force-app --dry-run --target-org myalias

# Deploy specific metadata
sf project deploy start --metadata ApexClass:MyClass --target-org myalias

# Retrieve into local project
sf project retrieve start --metadata CustomObject:Account --target-org myalias
```

> **Note:** As of December 2025, `project deploy start` and `project retrieve start` require either source tracking enabled on the target org, or explicit `--metadata` / `--source-dir` flags. Omitting both will error.

## Auth

```bash
sf org login web --alias myalias --instance-url https://login.salesforce.com
sf org login jwt --username user@example.com --jwt-key-file server.key --client-id <id> --alias myalias
```

Use `jwt` for CI/headless environments. `org login device` was removed.

## Useful Flags

- `--target-org` / `-o` — target org alias or username (replaces `-u`)
- `--json` — machine-readable output for scripting
- `--verbose` — debug output on failures
