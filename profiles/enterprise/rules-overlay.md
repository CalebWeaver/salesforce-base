
## Project Profile: Enterprise (FFLib)

This project uses **FFLib Apex Common** for enterprise separation of concerns. All new features must follow the Domain-Service-Selector-UnitOfWork pattern.

## Architecture Layers

All code follows the layered architecture: Trigger → Domain → Service → Selector, with an Application factory managing dependency injection.

Invoke `/fflib-architecture` for full implementation examples of each layer (Domain, Service, Selector, Application factory, LWC controllers).

### Layer Responsibilities

- **Trigger → Domain**: Triggers delegate to Domain classes via `fflib_SObjectDomain.triggerHandler()`. Domains handle validation (`onValidate`) and field defaults (`onBeforeInsert`, etc.)
- **Service**: Business logic and orchestration. Only layer that uses Unit of Work for DML.
- **Selector**: All SOQL lives here. Never write inline SOQL outside of selectors.
- **Application**: Singleton factory registering all Domain, Selector, Service, and UnitOfWork bindings.

## Naming Conventions (FFLib)

| Layer | Naming | Example |
|-------|--------|---------|
| Domain | Plural object name | `Accounts`, `Opportunities` |
| Selector | Plural + "Selector" | `AccountsSelector`, `OpportunitiesSelector` |
| Service | Singular + "Service" | `AccountService`, `OpportunityService` |
| Service Interface | "I" + Service name | `IAccountService` |
| Application | `Application` (singleton) | `Application.cls` |

## Logging (NebulaLogger)

This project uses [NebulaLogger](https://github.com/jongpie/NebulaLogger) for enterprise logging instead of `System.debug()`. Install via `references/repos.json` package commands.

Invoke `/nebula-logger` for usage examples.

## FFLib References

- Reference `references/fflib-apex-common/` for base class source and patterns
- Reference `references/fflib-apex-mocks/` for ApexMocks test patterns
- Install all via `references/repos.json` package commands

## Testing with FFLib

Use `fflib_ApexMocks` for mocking selectors, services, and unit of work in tests. Use `Application.*.setMock()` for dependency injection in test context.

### Test Data Setup with Unit of Work

In enterprise projects, use `Application.UnitOfWork.newInstance()` for test data DML — the same tool used in production code. Builders create in-memory records, UoW handles insert ordering and relationship wiring via `registerNew` and `registerRelationship`. Do NOT use `TestDataGraph` in enterprise — it duplicates what UoW already provides.

```apex
@TestSetup
static void setup() {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    Account acc = new AccountBuilder().withName('Acme Corp').build();
    Contact con = new ContactBuilder().withLastName('Doe').build();
    uow.registerNew(acc);
    uow.registerNew(con, Contact.AccountId, acc);
    uow.commitWork();
}
```

Scenario fixtures should also use UoW internally. Invoke `/fflib-testing` for full test examples.

## Async in Enterprise Projects

Async classes delegate to Service methods and use Unit of Work for DML — they don't query or DML directly. Enqueue from Service methods or Domain classes, never from Selectors. Invoke `/build-async` for full examples.

## Configuration Access (FFLib-Integrated)

All Custom Metadata Type access goes through dedicated Selectors registered in `Application.cls`, keeping configuration reads mockable and testable. Template: `AppConfigSelector.cls` in `templates/salesforce/classes/enterprise/`.

Invoke `/fflib-architecture` for config selector implementation, registration, consumption, and test mocking examples.

## LWC in Enterprise Projects

LWC controllers are thin wrappers that delegate to Service and Selector layers — no business logic in controllers. Read operations call Selectors directly (cacheable). Write operations call Service methods.

Invoke `/fflib-architecture` for controller examples and `/build-lwc` for full LWC component patterns.

## What NOT to Do

- Don't write SOQL outside of Selector classes
- Don't perform DML outside of Unit of Work — including test setup (use `Application.UnitOfWork.newInstance()` for test data)
- Don't put business logic in Domain classes — they handle validation and field defaults only
- Don't skip the Service layer for "simple" operations — consistency matters at scale
- Don't use the lightweight TriggerHandler pattern — use `fflib_SObjectDomain.triggerHandler()` instead
- Don't mix FFLib and non-FFLib patterns in the same project
- Don't query CMDTs inline — use config selectors registered in `Application.cls`

## When Implementing New Features

For every new SObject or feature, create all layers:
1. **Domain** class with Constructor inner class
2. **Selector** class with field list and custom query methods
3. **Service** class (with interface) for business operations
4. **Register** all classes in `Application.cls`
5. **Trigger** using `fflib_SObjectDomain.triggerHandler()`
6. **Permission set** granting CRUD and field access — add to Admin PSG and assign to running user (see base rules "Creating Custom Objects and Fields")
7. **Tests** using `fflib_ApexMocks` for layer isolation

For every new Custom Metadata Type, create a config selector:
1. **Selector** class extending `fflib_SObjectSelector` with `getAll()` caching
2. **Register** in `Application.cls` Selector factory
3. **Consume** through `newInstance()` in services — never inline queries
