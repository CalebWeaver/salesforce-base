/**
 * Example test class demonstrating the enterprise test data framework patterns.
 * Uses Unit of Work for all test data DML — the same pattern used in production code.
 *
 * Shows:
 *   1. Using builders with Unit of Work directly
 *   2. Using scenario fixtures for common setups
 *   3. Verifying relationships are correctly wired
 */
@IsTest(SeeAllData=false)
private class Example_TestDataPatterns_Test {

    /**
     * Demonstrates using Unit of Work with builders directly.
     * Use this pattern when you need custom setup not covered by fixtures.
     */
    @IsTest
    static void shouldCreateAccountAndContactWithUoW() {
        Account acc = new AccountBuilder()
            .withName('Acme Corporation')
            .withBillingCity('San Francisco')
            .withIndustry('Technology')
            .build();

        Contact con = new ContactBuilder()
            .withFirstName('Jane')
            .withLastName('Doe')
            .withEmail('jane.doe@acme.test')
            .withTitle('VP Sales')
            .build();

        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        uow.registerNew(acc);
        uow.registerNew(con, Contact.AccountId, acc);

        Test.startTest();
        uow.commitWork();
        Test.stopTest();

        System.assertNotEquals(null, acc.Id, 'Account should be inserted');
        System.assertNotEquals(null, con.Id, 'Contact should be inserted');
        System.assertEquals(acc.Id, con.AccountId, 'Contact should be related to Account');

        Contact queriedContact = [SELECT Id, AccountId, Account.Name FROM Contact WHERE Id = :con.Id];
        System.assertEquals('Acme Corporation', queriedContact.Account.Name);
    }

    /**
     * Demonstrates multi-level hierarchy with Unit of Work.
     */
    @IsTest
    static void shouldHandleAccountHierarchy() {
        Account parent = new AccountBuilder().withName('Parent Corp').build();
        Account child = new AccountBuilder().withName('Child Division').build();
        Contact parentContact = new ContactBuilder().withLastName('Parent Contact').build();
        Contact childContact = new ContactBuilder().withLastName('Child Contact').build();

        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        uow.registerNew(parent);
        uow.registerNew(child, Account.ParentId, parent);
        uow.registerNew(parentContact, Contact.AccountId, parent);
        uow.registerNew(childContact, Contact.AccountId, child);
        uow.commitWork();

        System.assertEquals(parent.Id, child.ParentId, 'Child account should have parent');
        System.assertEquals(parent.Id, parentContact.AccountId);
        System.assertEquals(child.Id, childContact.AccountId);
    }

    /**
     * Demonstrates using CustomerFixture for standard scenarios.
     * Prefer fixtures when they match your test needs.
     */
    @IsTest
    static void shouldCreateCustomerUsingFixture() {
        Test.startTest();
        CustomerFixture.Result result = CustomerFixture.createCustomerWithPrimaryContact();
        Test.stopTest();

        System.assertNotEquals(null, result.accountId, 'Account should have Id');
        System.assertNotEquals(null, result.primaryContactId, 'Contact should have Id');
        System.assertEquals(result.accountId, result.primaryContact.AccountId, 'Contact should be linked to Account');

        Account queriedAccount = [SELECT Id, Name, Type FROM Account WHERE Id = :result.accountId];
        System.assertEquals('Customer', queriedAccount.Type);
    }

    /**
     * Demonstrates creating multiple related records with fixture.
     */
    @IsTest
    static void shouldCreateCustomerWithMultipleContacts() {
        Integer contactCount = 5;

        Test.startTest();
        CustomerFixture.ResultWithContacts result = CustomerFixture.createCustomerWithContacts(contactCount);
        Test.stopTest();

        System.assertEquals(contactCount, result.contacts.size(), 'Should create requested number of contacts');

        for (Contact con : result.contacts) {
            System.assertNotEquals(null, con.Id, 'Contact should be inserted');
            System.assertEquals(result.accountId, con.AccountId, 'Contact should be linked to Account');
        }

        List<Contact> queriedContacts = [SELECT Id FROM Contact WHERE AccountId = :result.accountId];
        System.assertEquals(contactCount, queriedContacts.size());
    }

    /**
     * Demonstrates that builders create valid records by default.
     */
    @IsTest
    static void buildersShouldCreateValidDefaultRecords() {
        Account defaultAccount = new AccountBuilder().build();
        Contact defaultContact = new ContactBuilder().build();

        System.assert(defaultAccount.Name.startsWith('Test Account'), 'Account should have default name');
        System.assert(defaultContact.LastName.startsWith('Test Contact'), 'Contact should have default last name');
        System.assert(defaultContact.Email.contains('@example.test'), 'Contact should have default email');
    }

    /**
     * Demonstrates using withField for custom/non-standard fields.
     */
    @IsTest
    static void shouldSupportGenericFieldSetting() {
        Account acc = new AccountBuilder()
            .withField(Account.Description, 'Custom description')
            .withField(Account.NumberOfEmployees, 100)
            .build();

        System.assertEquals('Custom description', acc.Description);
        System.assertEquals(100, acc.NumberOfEmployees);
    }
}
