# Salesforce POC / Demo Standards

This project uses a **POC/demo architecture** — the lightest possible structure for getting something visual in front of customers quickly. Speed of delivery matters more than production hardening. Preference LWCs and Apex controllers; skip everything that isn't needed for the demo.

## What's Enforced

These rules prevent POCs from failing during a live demo:

- **Governor limits / bulkification** — a POC that hits limits during a demo is worse than no POC. Always bulkify code, absolutely no queries in loops.
- **No SOQL in loops** — same reason
- **Never hardcode Salesforce IDs** — POCs get moved between orgs constantly
- **Create `-meta.xml` files** — required for deployment to work at all

## What's Relaxed

Everything else bends toward speed:

- **`with sharing` / `without sharing`** — use whichever gets the demo working. Default to `without sharing` if sharing enforcement causes confusing "insufficient access" errors.
- **`WITH SECURITY_ENFORCED`** — skip it. Causes cryptic errors when permissions aren't configured.
- **SecurityEnforcer** — skip entirely
- **Permission sets** — keep it minimal. Create a single permission set for the project (e.g., `FR_Access`) and add object CRUD + field access there whenever you create new objects or fields. Assign it to the running user after deploy so fields are visible. Skip PSGs, skip per-object perm sets — one catch-all is fine for POC.
```bash
sf org assign permset --name <PermSetApiName>
```
- **Triggers** — only create them if the demo needs backend automation. If you're just showing a UI, skip triggers entirely.
- **Tests** — skip entirely. Deploy with `--test-level NoTestRun`.
- **Configuration strategy** — hardcode everything. Extract to CMDT/Labels only for values the demo audience will see or need to change.
- **Error handling** — simple `try/catch` or direct DML. No partial success patterns.
- **Logging** — `System.debug()` is fine. No logging framework.

## LWC-First Development

Build the UI first, wire it to Apex second. The goal is a visual demo, so prioritize what the customer will see.

### Development Priority

1. **`lightning-record-*-form` components first** — zero Apex needed for basic CRUD screens
2. **LWC with `@wire` for read-only views** — fast, cacheable, reactive. Use `@AuraEnabled(cacheable=true)` on the controller method.
3. **LWC with imperative Apex for actions** — button clicks, saves, custom logic
4. **Apex triggers only when the demo requires backend automation** — don't scaffold trigger handlers just because an object exists

### LWC Controllers

Controllers do everything — query, process, DML, all in the `@AuraEnabled` method. No service layer, no selector, no domain.

See `references/patterns/poc/lwc-controller.md` for implementation examples.

### Static Resources for Mock Data

If the demo doesn't need real data processing, drive the UI from static JSON. This is faster than building Apex controllers and avoids data setup issues.

See `references/patterns/poc/static-mock-data.md` for patterns.

## SOQL

- Always use WHERE clauses and LIMIT when appropriate
- Inline SOQL is fine — no need to isolate queries
- Skip `WITH SECURITY_ENFORCED` — it causes permission errors in scratch orgs that aren't fully configured

## Trigger Handler Pattern

Only use when the demo requires backend automation (e.g., auto-assignment, field updates on save). Skip entirely for UI-only demos. `without sharing` is fine for POC handlers.

See `references/patterns/poc/trigger-handler.md` for implementation examples.

## Tests

**Skip tests entirely.** POCs target scratch orgs where coverage isn't enforced. Deploy with `--test-level NoTestRun`. Only write tests if the POC itself is demonstrating a testing pattern.

If you need to deploy to a shared sandbox (e.g., for a stakeholder demo), you'll need at least 85% coverage. At that point, write minimal positive-path tests to clear the gate — don't invest in bulk/negative tests until promotion.

## Deployment

```bash
# Validate
sf project deploy start --source-dir force-app --dry-run --test-level NoTestRun

# Deploy
sf project deploy start --source-dir force-app --test-level NoTestRun
```

## Demo Data Setup

Use anonymous Apex scripts to seed demo data. Don't build data factories — just create what you need.

See `references/patterns/poc/demo-data-seed.md` for script examples. Run with: `sf apex run -f scripts/seed-demo-data.apex`

## Naming Convention

Prefix POC-specific classes with a short project tag (e.g., `FR_RoutingEngine`, `FR_CaseController`) to make cleanup easy later. This makes it trivial to identify and remove POC code if it doesn't move forward, or to find everything that needs hardening if it does.

## Project Documentation

Project-specific context lives in `docs/`. Check these before working in an unfamiliar area.

- **`docs/architecture.md`** — Project overview, data model, integrations, key decisions
- **`docs/modules/`** — One file per module describing purpose, key classes, and objects
- **`docs/user-stories/`** — One file per user story with acceptance criteria and technical notes

Keep docs lightweight for POCs — a few sentences per section is fine. The goal is enough context that an agent (or another developer) can pick up where you left off.

## AI Agent Reminders

1. **Never hardcode Salesforce IDs** - IDs differ between orgs
2. **LWC first** - Build the UI before writing Apex. Use `lightning-record-*-form` before custom components.
3. **Skip triggers unless needed** - If no backend automation is being demoed, don't create them
4. **Use POC prefix consistently** - Every class and trigger gets the project tag
5. **Avoid SOQL in loops** - Most common governor limit violation
6. **Create meta.xml files** - Every Apex class/trigger needs corresponding `-meta.xml`
7. **Deploy with NoTestRun** - POCs don't need tests for scratch org deployment
8. **Retrieve before modify** - Always get current state before making changes
9. **Skip security enforcement** - No `WITH SECURITY_ENFORCED`, no `SecurityEnforcer`, no `with sharing` requirements
10. **Update the project permission set** - When creating objects or fields, add CRUD and field access to the project's catch-all permission set and assign it to the running user
11. **Static resources for mock data** - If the demo is UI-only, skip Apex and use static JSON
12. **Read pattern files before implementing** - Check `references/patterns/poc/` for examples before writing code
13. **Check project docs** - Read `docs/architecture.md` before working in an unfamiliar area

## Promotion Checklist

When a POC gets approved for development, use this checklist to identify what needs hardening:

- [ ] **Add `with sharing`** — review every class and set appropriate sharing context
- [ ] **Add `WITH SECURITY_ENFORCED`** — add to all SOQL queries
- [ ] **Add SecurityEnforcer** — replace bare DML with CRUD/FLS checks
- [ ] **Split permission sets** — break the catch-all POC perm set into one per custom object, add to Admin PSG
- [ ] **Write tests** — POC likely has zero coverage; write positive-path tests for every class first
- [ ] **Add bulk tests** — 200+ records through every trigger path
- [ ] **Add negative tests** — invalid data, missing required fields, permission errors
- [ ] **Replace hardcoded config** — move to Custom Metadata Types / Custom Labels
- [ ] **Replace static mock data** — swap static JSON for real Apex controllers
- [ ] **Add proper error handling** — `Database.insert(records, false)` with SaveResult logging
- [ ] **Adopt test data framework** — convert inline `new SObject()` to builders + TestDataGraph
- [ ] **Remove POC prefix** — rename `FR_RoutingEngine` → `RoutingEngine` (or keep if namespacing helps)
- [ ] **Add logging** — decide on `System.debug` vs NebulaLogger based on target profile
- [ ] **Replace demo data scripts** — convert anonymous Apex seeds to proper test data framework
