# Test Data Framework

Use the test data framework from `templates/salesforce/classes/testsupport/`.

## Layer 1: Fluent Builders (All Profiles)

One builder per SObject type. Builders are valid-by-default — required fields are auto-populated with unique values. Builders perform NO DML and NO queries.

```apex
Account acc = new AccountBuilder()
    .withName('Acme Corp')
    .withIndustry('Technology')
    .build();  // Returns uninserted Account
```

## Layer 2: DML (Profile-Specific)

### Lightweight — TestDataGraph

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

### Enterprise — Unit of Work

Use `Application.UnitOfWork.newInstance()` for test data DML — the same tool used in production code. UoW handles insert ordering based on the SObjectType list in `Application.cls` and wires relationships via `registerNew` with the parent reference.

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
