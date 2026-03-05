/**
 * Scenario fixture for customer-related test data.
 * Fixtures are named by business state, not object graphs.
 * Uses Unit of Work for DML — the same pattern used in production code.
 *
 * Usage:
 *   CustomerFixture.Result result = CustomerFixture.createCustomerWithPrimaryContact();
 *   System.assertNotEquals(null, result.accountId);
 *   System.assertEquals(result.accountId, result.primaryContact.AccountId);
 */
@IsTest
public class CustomerFixture {

    /**
     * Creates a basic customer with one primary contact.
     * Both records are inserted and fully wired.
     */
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

    /**
     * Creates a customer with multiple contacts.
     */
    public static ResultWithContacts createCustomerWithContacts(Integer contactCount) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

        Account account = new AccountBuilder()
            .withName('Test Customer ' + TestIds.nextSuffix())
            .withType('Customer')
            .build();

        uow.registerNew(account);

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < contactCount; i++) {
            Contact con = new ContactBuilder()
                .withFirstName('Contact ' + i)
                .build();
            contacts.add(con);
            uow.registerNew(con, Contact.AccountId, account);
        }

        uow.commitWork();

        return new ResultWithContacts(account, contacts);
    }

    /**
     * Result object for single contact scenario.
     */
    public class Result {
        public Account account { get; private set; }
        public Contact primaryContact { get; private set; }
        public Id accountId { get { return account.Id; } }
        public Id primaryContactId { get { return primaryContact.Id; } }

        public Result(Account account, Contact primaryContact) {
            this.account = account;
            this.primaryContact = primaryContact;
        }
    }

    /**
     * Result object for multiple contacts scenario.
     */
    public class ResultWithContacts {
        public Account account { get; private set; }
        public List<Contact> contacts { get; private set; }
        public Id accountId { get { return account.Id; } }

        public ResultWithContacts(Account account, List<Contact> contacts) {
            this.account = account;
            this.contacts = contacts;
        }
    }
}
