---
name: build-async
description: How to implement async processing in Salesforce — when to use Queueable vs Batch vs Scheduled vs Platform Events, and the rules for each.
---

## Pattern Selection

| Pattern | When to Use | Key Limit |
|---------|-------------|-----------|
| **Queueable** | Complex processing, chaining steps, callouts from triggers | 50 per transaction |
| **Batch Apex** | Large data volumes (thousands to millions of records) | 5 concurrent batches |
| **Scheduled Apex** | Recurring jobs on a cron schedule | 100 per org |
| **Platform Events** | Decoupling publishers from subscribers, event-driven | 150K events/hour |
| **Future Methods** | Avoid — prefer Queueable in almost all cases | 50 per transaction |

## Decision Flow

1. **Need to process > 2,000 records?** → Batch Apex
2. **Need to chain multiple async steps?** → Queueable
3. **Need to run on a schedule?** → Scheduled Apex (kicks off Batch or Queueable)
4. **Need to decouple producer from consumer?** → Platform Events
5. **Simple one-off async with only primitives?** → Future (but prefer Queueable)

## Core Rules

- Always implement `Database.AllowsCallouts` for HTTP callouts
- Always handle errors — async failures are silent by default
- Never enqueue from a loop — collect IDs first, enqueue once
- Use Custom Metadata for batch sizes and retry counts (see `/configure-values`)
- Test with `Test.startTest()/stopTest()` to execute async jobs synchronously

## Profile Differences

- **Lightweight**: Async classes are standalone — query, process, and DML directly. Enqueue from trigger handlers.
- **Enterprise**: Async classes delegate to Service methods and use Unit of Work. Enqueue from Domain or Service — never from Selectors.

For full implementation examples, read the relevant file in `references/` for this skill: `queueable.md`, `batch.md`, `scheduled.md`, `platform-events.md`, or `profile-patterns.md` (profile-specific integration and testing).
