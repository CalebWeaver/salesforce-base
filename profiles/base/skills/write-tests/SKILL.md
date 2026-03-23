---
name: write-tests
description: How to write Apex tests in this project — 85% coverage requirements, test data builders and fixtures, mocking, and isolation rules.
---

## Coverage Requirement

85% coverage is enforced at sandbox deployment. Write tests alongside code from the start. Every class gets a corresponding test class.

- Use `@TestSetup` for common data, `Test.startTest()/stopTest()` to reset limits
- Test bulk (200+ records), positive, negative, and boundary cases
- Never use `seeAllData=true` — create isolated test data
- Use `UniversalMocker` for mocking dependencies if available (see `references/UniversalMock/`)

## Test Data Standard — Builders and Fixtures

Use fluent builders from `templates/salesforce/classes/testsupport/` for in-memory record creation. Builders produce valid-by-default objects with no DML.

Use scenario fixtures for common business states (e.g., `AccountWithContactsFixture`). Fixtures compose builders into reusable setups.

**DML layer depends on profile:**
- **Lightweight**: Use `TestDataGraph` for relationship wiring and insert ordering. `TestDataGraph` handles parent-before-child ordering automatically.
- **Enterprise**: Use `Application.UnitOfWork.newInstance()` for test data DML — the same pattern used in production. Do NOT use `TestDataGraph` in enterprise projects.

## Fluent Builders

One builder per SObject type. Builders are valid-by-default — required fields are auto-populated with unique values. Builders perform NO DML and NO queries.

```apex
Account acc = new AccountBuilder()
    .withName('Acme Corp')
    .withIndustry('Technology')
    .build();  // Returns uninserted Account
```

## DML Layer: Lightweight — TestDataGraph

ALL DML happens via `TestDataGraph.commit()`. Handles relationship wiring and insert ordering automatically.

```apex
TestDataGraph graph = new TestDataGraph();
Account acc = new AccountBuilder().build();
Contact con = new ContactBuilder().build();

graph.register(acc);
graph.register(con);
graph.relate(con, Contact.AccountId, acc);
graph.commit();  // Inserts in correct order, wires AccountId
```

## DML Layer: Enterprise — Unit of Work

Use `Application.UnitOfWork.newInstance()` for test data DML. UoW handles insert ordering based on the SObjectType list in `Application.cls` and wires relationships via `registerNew` with the parent reference.

```apex
fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
Account acc = new AccountBuilder().build();
Contact con = new ContactBuilder().build();

uow.registerNew(acc);
uow.registerNew(con, Contact.AccountId, acc);
uow.commitWork();  // Inserts in correct order, wires AccountId
```

Do NOT use `TestDataGraph` in enterprise projects — it duplicates what UoW already provides.

## Scenario Fixtures

Name fixtures by **business state**, not object graphs. Return result objects with all created records and IDs.

```apex
// Good
CustomerFixture.Result result = CustomerFixture.createCustomerWithPrimaryContact();
System.assertEquals(result.accountId, result.primaryContact.AccountId);

// Bad — name describes the object graph, not the scenario
createAccountWithOppWithLineItemsWithContacts();
```

Fixture internals use the DML layer appropriate to the profile (TestDataGraph for lightweight, UoW for enterprise).

## When to Use What

| Scenario | Lightweight | Enterprise |
|----------|-------------|------------|
| Simple single-object test | Builder + `insert` directly | Builder + `uow.registerNew()` + `commitWork()` |
| Multi-object with relationships | Builders + TestDataGraph | Builders + UoW `registerNew` with parent refs |
| Common business scenarios | Scenario Fixtures | Scenario Fixtures |
| Mocking without DML | MockSObjectBuilder | MockSObjectBuilder |

## Adding Builders for New Objects

1. Create a builder in `testsupport/builders/` extending `BaseFluentBuilder`
2. Set sensible defaults in `applyDefaults()`
3. Use `TestIds.nextSuffix()` for unique names/external IDs
4. Add fluent methods for commonly-used fields
5. If needed, add a scenario fixture in the profile's fixtures directory (`lightweight/fixtures/` or `enterprise/fixtures/`)

## Key Reminders

- **Test data isolation** — tests create their own data, never rely on org data
- **Builders for in-memory records** — no DML until explicitly needed
- **Fixtures for scenario setup** — compose builders into reusable states
- **Profile-appropriate DML** — TestDataGraph (lightweight) vs UoW (enterprise)
- **Bulk test every trigger path** — 200+ records through every handler
