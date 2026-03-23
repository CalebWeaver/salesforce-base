
## Project Profile: Lightweight

This project uses a **lightweight architecture** without FFLib. Keep things simple and direct.

## Trigger Handler Pattern

Never put logic directly in triggers. One trigger per object, use a shared base handler class. Logic lives directly in handlers — no service or domain layers.

Check for existing `TriggerHandler` in project. If none exists, copy from `templates/salesforce/classes/TriggerHandler.cls`.

Invoke `/trigger-handler` for implementation examples.

## Architecture Guidelines

- **No service layer required** - Business logic lives directly in trigger handlers or utility classes
- **No domain layer** - Validation and field defaults go in trigger handlers
- **No selector layer** - SOQL queries can live in handlers or simple query helper classes
- **Keep it flat** - Avoid unnecessary abstraction layers for small projects
- **DataAccessor** is available if you need testable query isolation, but it's optional

## When to Add Abstraction

If you find a handler growing beyond ~200 lines, extract logic into a focused utility class. Don't pre-create service/domain/selector layers "just in case."

## Async in Lightweight Projects

Async classes are standalone — they query, process, and DML directly. No service layer routing needed. Enqueue from trigger handlers. Invoke `/build-async` for full examples.

## Configuration Access

Query Custom Metadata Types directly in Apex — no accessor class needed for this profile. Cache results in static variables when a method is called multiple times in the same transaction.

Invoke `/trigger-handler` for CMDT access implementation examples.

## LWC in Lightweight Projects

LWC controllers are simple Apex classes with `@AuraEnabled` methods — no service layer delegation needed. Business logic can live directly in the controller for small components.

Invoke `/trigger-handler` for LWC controller implementation examples and `/build-lwc` for full LWC component patterns.

## What NOT to Do

- Don't create fflib_* classes or patterns - this project intentionally avoids FFLib
- Don't create UnitOfWork patterns - use `Database.insert/update/delete` directly
- Don't create Selector classes unless you genuinely need query testability for a specific case
- Don't create Domain classes - trigger handlers own validation and field logic
