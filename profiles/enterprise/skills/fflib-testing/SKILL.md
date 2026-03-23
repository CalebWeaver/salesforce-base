---
name: fflib-testing
description: How to write tests in this enterprise FFLib project — ApexMocks for layer isolation, Unit of Work for test data setup, and Application.*.setMock() for dependency injection.
---

## Approach

Use `fflib_ApexMocks` to mock Selectors, Services, and Unit of Work in tests. Use `Application.*.setMock()` for dependency injection in test context. This keeps tests fast and isolated to the layer under test.

## Test Data Setup with Unit of Work

In enterprise projects, use `Application.UnitOfWork.newInstance()` for test data DML — the same tool used in production code. Builders create in-memory records; UoW handles insert ordering and relationship wiring via `registerNew` and `registerRelationship`. Do NOT use `TestDataGraph` in enterprise — it duplicates what UoW already provides.

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

For multi-level hierarchies:

```apex
@TestSetup
static void setup() {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

    Account parent = new AccountBuilder().withName('Parent Corp').build();
    Account child = new AccountBuilder().withName('Child Division').build();
    Contact con = new ContactBuilder().withLastName('Smith').build();

    uow.registerNew(parent);
    uow.registerNew(child, Account.ParentId, parent);
    uow.registerNew(con, Contact.AccountId, child);
    uow.commitWork();
}
```

## Mocking with ApexMocks — Full Unit Test Example

```apex
@IsTest
static void testServiceActivatesAccounts() {
    // Arrange
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    AccountsSelector mockSelector = (AccountsSelector) mocks.mock(AccountsSelector.class);
    fflib_ISObjectUnitOfWork mockUow = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

    List<Account> testAccounts = new List<Account>{
        new AccountBuilder().withName('Test 1').build(),
        new AccountBuilder().withName('Test 2').build()
    };

    mocks.startStubbing();
    mocks.when(mockSelector.sObjectType()).thenReturn(Account.SObjectType);
    mocks.when(mockSelector.selectById(new Set<Id>{'001000000000001'})).thenReturn(testAccounts);
    mocks.stopStubbing();

    Application.Selector.setMock(mockSelector);
    Application.UnitOfWork.setMock(mockUow);

    // Act
    Test.startTest();
    AccountService.activateAccounts(new Set<Id>{'001000000000001'});
    Test.stopTest();

    // Assert
    ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, mocks.times(2)))
        .registerDirty(fflib_Match.anySObject());
    ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1))
        .commitWork();
}
```

## Integration Test Example

Integration tests use real UoW for both data setup and the code under test:

```apex
@IsTest
static void testServiceActivatesAccountsIntegration() {
    // Arrange — real data via UoW
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    Account acc = new AccountBuilder().withName('Integration Test').build();
    uow.registerNew(acc);
    uow.commitWork();

    // Act
    Test.startTest();
    AccountService.activateAccounts(new Set<Id>{ acc.Id });
    Test.stopTest();

    // Assert — query real results
    Account result = [SELECT Status__c, ActivatedDate__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals('Active', result.Status__c);
    System.assertEquals(Date.today(), result.ActivatedDate__c);
}
```

## Key Patterns

- **Mock creation**: `mocks.mock(ClassName.class)` for any mockable class
- **Stubbing**: Wrap method stubs in `mocks.startStubbing()` / `mocks.stopStubbing()`
- **DI injection**: Use `Application.Selector.setMock()`, `Application.UnitOfWork.setMock()`, etc.
- **Verification**: Cast to interface type and call `mocks.verify()` with expected call count
- **Matchers**: Use `fflib_Match.anySObject()`, `fflib_Match.anyString()`, etc. for flexible matching

## Scenario Fixtures (Enterprise)

Fixtures use UoW internally, not TestDataGraph:

```apex
@IsTest
public class CustomerFixture {

    public static Result createCustomerWithPrimaryContact() {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

        Account account = new AccountBuilder()
            .withName('Test Customer ' + TestIds.nextSuffix())
            .withType('Customer')
            .build();

        Contact primaryContact = new ContactBuilder()
            .withFirstName('Primary')
            .withTitle('Primary Contact')
            .build();

        uow.registerNew(account);
        uow.registerNew(primaryContact, Contact.AccountId, account);
        uow.commitWork();

        return new Result(account, primaryContact);
    }
}
```

## FFLib References

- `references/fflib-apex-mocks/` — ApexMocks source and patterns
- `references/fflib-apex-common/` — base class source
