---
name: build-lwc
description: How to build Lightning Web Components in this project — wire vs imperative, Apex method exposure, error handling, security, and naming conventions.
---

## Key Decisions

| Decision | Guidance |
|----------|----------|
| **Wire vs Imperative** | Use `@wire` for read-only data that should refresh reactively. Use imperative for DML operations, conditional calls, or when you need control over timing. |
| **Error handling** | Always handle errors in both wire and imperative calls. Display user-facing messages via `lightning/platformShowToastEvent`. |
| **Apex method exposure** | Mark Apex methods `@AuraEnabled(cacheable=true)` for wire-compatible reads. Use `@AuraEnabled` (without cacheable) for DML operations. |
| **Security** | Never trust client-side input — validate and enforce CRUD/FLS in Apex. |
| **Naming** | Components: `camelCase` folder/file names. Apex controllers: match the feature, not the component. |

## Core Rules

- Keep components small and focused
- Pull labels from Custom Labels — no hardcoded user-facing strings
- Use `lightning-record-*-form` for simple CRUD before building custom forms
- Avoid business logic in LWC JavaScript — keep it in Apex
- Don't expose Apex methods without CRUD/FLS enforcement

## File Structure

```
force-app/main/default/lwc/
├── accountList/
│   ├── accountList.html
│   ├── accountList.js
│   ├── accountList.css           (optional)
│   ├── accountList.js-meta.xml
│   └── __tests__/                (optional, Jest)
│       └── accountList.test.js
```

One component per folder, folder name matches component name. CSS is scoped to the component automatically.

## Component Communication

| Pattern | When to Use |
|---------|-------------|
| `@api` properties | Parent → Child data passing |
| Custom events | Child → Parent communication |
| Lightning Message Service | Unrelated components on the same page |
| Platform Events | Cross-context (Apex to LWC via emp API) |

## Profile Differences

- **Lightweight**: LWC controllers are simple Apex classes with `@AuraEnabled` methods — no service layer needed.
- **Enterprise**: LWC controllers are thin wrappers (one-line delegation) to Service or Selector methods. Never put business logic in the controller.

For full implementation examples, read the relevant file in `references/` for this skill: `wire-and-imperative.md`, `component-patterns.md` (labels, standard components, meta XML, events), or `profile-patterns.md` (lightweight vs enterprise Apex controllers, Jest tests).
