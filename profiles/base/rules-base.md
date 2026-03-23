## Hard Rules

- No SOQL or DML inside loops — always bulkify
- Never hardcode Salesforce IDs — they differ between orgs
- Every Apex class and trigger needs a `-meta.xml` file
- Never hardcode configurable values — use Custom Metadata Types, Custom Labels, or Custom Settings

## Project Documentation

Always read `docs/project-reference.md` at the start of every task. Check `docs/architecture.md` and the relevant `docs/modules/` file before working in an unfamiliar area. Update docs when making significant changes.
