---
name: poc-approach
description: POC and demo development standards — what rules are enforced vs relaxed, LWC-first development priority, deployment workflow, and naming conventions.
---

## POC Philosophy

Speed of delivery matters more than production hardening. The goal is a visual demo in front of customers quickly. Prioritize LWCs and Apex controllers; skip everything that isn't needed for the demo.

## What's Enforced

These rules prevent POCs from failing during a live demo:

- **Governor limits / bulkification** — a POC that hits limits during a demo is worse than no POC. Always bulkify, no queries in loops.
- **No SOQL in loops** — same reason
- **Never hardcode Salesforce IDs** — POCs get moved between orgs constantly
- **Create `-meta.xml` files** — required for deployment to work at all

## What's Relaxed

- **`with sharing` / `without sharing`** — use whichever gets the demo working. Default to `without sharing` if sharing enforcement causes confusing errors.
- **`WITH SECURITY_ENFORCED`** — skip it. Causes cryptic errors when permissions aren't configured.
- **SecurityEnforcer** — skip entirely
- **Permission sets** — one catch-all permission set for the project (e.g., `FR_Access`). Add object CRUD + field access whenever you create new objects or fields. Skip PSGs. Assign after deploy:
```bash
sf org assign permset --name <PermSetApiName>
```
- **Triggers** — only create if the demo needs backend automation. Skip for UI-only demos.
- **Tests** — skip entirely. Deploy with `--test-level NoTestRun`.
- **Configuration** — hardcode everything. Extract to CMDT/Labels only for values the demo audience will see.
- **Error handling** — simple `try/catch` or direct DML. No partial success patterns.
- **Logging** — `System.debug()` is fine.

## LWC-First Development

Build the UI first, wire it to Apex second.

1. **`lightning-record-*-form` first** — zero Apex needed for basic CRUD screens
2. **LWC with `@wire`** — fast, cacheable, reactive. Use `@AuraEnabled(cacheable=true)` on the controller method.
3. **LWC with imperative Apex** — button clicks, saves, custom logic
4. **Apex triggers only when the demo requires backend automation**

Controllers do everything — query, process, DML, all in the `@AuraEnabled` method. No service layer, no selector, no domain.

## LWC Controller Pattern

```apex
public class FR_CaseController {
    @AuraEnabled(cacheable=true)
    public static List<Case> getOpenCases(Id accountId) {
        return [SELECT Id, Subject, Status, Priority FROM Case WHERE AccountId = :accountId AND IsClosed = false];
    }

    @AuraEnabled
    public static void escalateCase(Id caseId) {
        Case c = [SELECT Id, Priority FROM Case WHERE Id = :caseId];
        c.Priority = 'High';
        update c;
    }
}
```

- `@AuraEnabled(cacheable=true)` for read-only methods — fast page loads for demos
- Skip `WITH SECURITY_ENFORCED` — causes permission errors in unconfigured scratch orgs
- `without sharing` is fine for POC controllers

## Trigger Handler Pattern

Only use when the demo requires backend automation (e.g., auto-assignment, field updates on save). Skip entirely for UI-only demos.

```apex
// Trigger file (one per object)
trigger FR_CaseTrigger on Case (before insert, before update, after insert, after update) {
    new FR_CaseTriggerHandler().run();
}

// Handler file — without sharing is fine for POC
public without sharing class FR_CaseTriggerHandler extends TriggerHandler {
    protected override void beforeInsert() {
        for (Case c : (List<Case>) Trigger.new) {
            if (c.Priority == null) {
                c.Priority = 'Medium';
            }
        }
    }
}
```

- Only create triggers if the demo needs backend automation
- `without sharing` is fine — scratch orgs have one user
- Use the POC prefix on trigger and handler class names
- One trigger per object still applies (avoids trigger conflicts)

## Static Mock Data

Drive the UI from static JSON when the demo is about the UI/UX, not the data flow.

```javascript
// Import from Static Resource
import MOCK_DATA from '@salesforce/resourceUrl/mockCaseData';

// Or hardcode directly for throwaway demos
const DEMO_CASES = [
    { Id: '001', Subject: 'Routing Issue', Status: 'Open', Priority: 'High' },
    { Id: '002', Subject: 'Escalation Request', Status: 'In Progress', Priority: 'Medium' }
];
```

Use static data when:
- The demo is about the UI/UX, not the data flow
- You need to iterate on the frontend without waiting for Apex/data setup
- The demo audience won't be clicking through to record detail pages (fake IDs won't resolve)

## Deployment

```bash
# Validate
sf project deploy start --source-dir force-app --dry-run --test-level NoTestRun

# Deploy
sf project deploy start --source-dir force-app --test-level NoTestRun
```

## Demo Data

Use anonymous Apex scripts to seed demo data. Don't build data factories.

```apex
// scripts/seed-demo-data.apex
List<Account> accounts = new List<Account>{
    new Account(Name = 'Acme Corp', Industry = 'Technology'),
    new Account(Name = 'Global Industries', Industry = 'Manufacturing')
};
insert accounts;

List<Case> cases = new List<Case>{
    new Case(AccountId = accounts[0].Id, Subject = 'Routing Demo Case', Status = 'New', Priority = 'High'),
    new Case(AccountId = accounts[1].Id, Subject = 'Escalation Demo', Status = 'Open', Priority = 'Low')
};
insert cases;
```

```bash
sf apex run -f scripts/seed-demo-data.apex
```

- Keep seed scripts in `scripts/` so they're easy to find and re-run
- Name them by what they set up: `seed-demo-data.apex`, `seed-routing-cases.apex`
- Hardcode field values — this isn't production code, readability matters more than flexibility

## Experience Cloud (Quick Setup)

Add to `config/project-scratch-def.json`:

```json
{
  "features": ["Communities", "Sites"],
  "settings": {
    "experienceBundle": { "enableExperienceBundleMetadata": true },
    "communities": { "enableNetworkSettings": true }
  }
}
```

```bash
sf community create --name "Demo Portal" --template-name "Build Your Own (LWR)" --url-path-prefix demo
sf community publish --name "Demo Portal"
sf org open --path /demo/s/
```

Available templates: `Build Your Own (LWR)`, `Customer Service`, `Help Center`. Use `Build Your Own (LWR)` for POCs — it's the most flexible.

After creation, retrieve generated metadata to have it in source:

```bash
sf project retrieve start --metadata ExperienceBundle:Demo_Portal --metadata Network:Demo_Portal
```

### Guest User Setup (POC Shortcut)

1. Find the guest user profile name — it's `{Site Label} Profile` (e.g., `Demo Portal Profile`)
2. Add object and field permissions to the guest profile metadata, or add them through Setup UI
3. Add Apex class access for any `@AuraEnabled` controllers guest users will invoke

```xml
<!-- In Profile: Demo_Portal_Profile -->
<classAccesses>
    <apexClass>FR_ArticleController</apexClass>
    <enabled>true</enabled>
</classAccesses>
<objectPermissions>
    <allowRead>true</allowRead>
    <object>Knowledge__kav</object>
</objectPermissions>
```

**Shortcut**: In Setup → Digital Experiences → All Sites → Workspaces → Administration → Pages → Go to Force.com → Public Access Settings. Check the boxes for objects and fields the guest user needs.

### Common Scratch Org Pitfalls

| Issue | Fix |
|-------|-----|
| `sf community create` fails with "Communities not enabled" | Add `"Communities"` to `features` array in scratch org definition |
| Site URL returns 404 | Publish the site: `sf community publish --name "Demo Portal"` |
| Guest user can't see any data | Add object permissions to guest profile + enable "View All" for POC |
| `Cannot retrieve ExperienceBundle` | Enable `experienceBundle.enableExperienceBundleMetadata` in scratch def |
| LWC doesn't appear in Experience Builder | Add `lightning__CommunityPage` to component's `targets` in `.js-meta.xml` |
| Site shows "Under Maintenance" | Network `status` is `DownForMaintenance` — publish the site |

Scratch org site URL pattern: `https://{domain}.scratch.my.site.com/{urlPathPrefix}/s/`

## Naming Convention

Prefix POC-specific classes with a short project tag (e.g., `FR_RoutingEngine`, `FR_CaseController`). Makes cleanup trivial if the POC doesn't move forward, and makes it easy to find everything that needs hardening if it does.

## Project Documentation

Project-specific context lives in `docs/`. Check these before working in an unfamiliar area.

- **`docs/project-reference.md`** — Always read at the start of every task. Org quirks, team decisions, hard-won knowledge.
- **`docs/architecture.md`** — Project overview, data model, integrations, key decisions
- **`docs/modules/`** — One file per module describing purpose, key classes, and objects
- **`docs/user-stories/`** — One file per user story with acceptance criteria and technical notes

Keep docs lightweight for POCs — a few sentences per section is fine. Enough context that an agent or another developer can pick up where you left off.

## AI Agent Reminders

1. **Never hardcode Salesforce IDs** — IDs differ between orgs
2. **LWC first** — build the UI before writing Apex. Use `lightning-record-*-form` before custom components.
3. **Skip triggers unless needed** — only create if backend automation is being demoed
4. **Use POC prefix consistently** — every class and trigger gets the project tag
5. **Avoid SOQL in loops** — most common governor limit violation
6. **Create meta.xml files** — every Apex class/trigger needs a `-meta.xml`
7. **Deploy with NoTestRun** — POCs don't need tests for scratch org deployment
8. **Retrieve before modify** — always get current state before making changes
9. **Skip security enforcement** — no `WITH SECURITY_ENFORCED`, no `SecurityEnforcer`, no `with sharing` requirements
10. **Update the project permission set** — when creating objects or fields, add CRUD and field access to the catch-all permission set and assign it to the running user
11. **Static resources for mock data** — if the demo is UI-only, skip Apex and use static JSON
12. **Enable Communities in scratch org definition** — add `"Communities"` to features and `enableExperienceBundleMetadata` to settings before creating Experience Cloud sites
