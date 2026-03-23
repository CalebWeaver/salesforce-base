---
name: poc-promotion
description: Checklist for hardening a completed POC into a production-ready project. Use when a POC is approved for development.
---

## Promotion Checklist

When a POC gets approved for development, work through this checklist to identify what needs hardening:

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
- [ ] **Harden guest user access** — replace catch-all POC permission set on guest profile with granular per-object perm sets and criteria-based sharing rules
