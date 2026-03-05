/**
 * Fluent builder for Contact test data.
 * Creates valid-by-default Contact records without DML.
 * 
 * Usage:
 *   Contact con = new ContactBuilder()
 *       .withFirstName('Jane')
 *       .withLastName('Doe')
 *       .withEmail('jane@example.com')
 *       .build();
 */
@IsTest
public class ContactBuilder extends BaseFluentBuilder {

    public ContactBuilder() {
        record = new Contact();
        applyDefaults();
    }

    protected override void applyDefaults() {
        record.put(Contact.LastName, 'Test Contact ' + TestIds.nextSuffix());
        record.put(Contact.Email, TestIds.nextEmail());
    }

    public ContactBuilder withFirstName(String firstName) {
        record.put(Contact.FirstName, firstName);
        return this;
    }

    public ContactBuilder withLastName(String lastName) {
        record.put(Contact.LastName, lastName);
        return this;
    }

    public ContactBuilder withEmail(String email) {
        record.put(Contact.Email, email);
        return this;
    }

    public ContactBuilder withPhone(String phone) {
        record.put(Contact.Phone, phone);
        return this;
    }

    public ContactBuilder withMobilePhone(String mobile) {
        record.put(Contact.MobilePhone, mobile);
        return this;
    }

    public ContactBuilder withTitle(String title) {
        record.put(Contact.Title, title);
        return this;
    }

    public ContactBuilder withDepartment(String department) {
        record.put(Contact.Department, department);
        return this;
    }

    public ContactBuilder withMailingCity(String city) {
        record.put(Contact.MailingCity, city);
        return this;
    }

    public ContactBuilder withMailingState(String state) {
        record.put(Contact.MailingState, state);
        return this;
    }

    public ContactBuilder withMailingCountry(String country) {
        record.put(Contact.MailingCountry, country);
        return this;
    }

    public ContactBuilder withAccountId(Id accountId) {
        record.put(Contact.AccountId, accountId);
        return this;
    }

    public ContactBuilder withAccount(Account acc) {
        record.put(Contact.AccountId, acc.Id);
        return this;
    }

    public ContactBuilder withReportsToId(Id reportsToId) {
        record.put(Contact.ReportsToId, reportsToId);
        return this;
    }

    public new ContactBuilder withField(Schema.SObjectField field, Object value) {
        record.put(field, value);
        return this;
    }

    public Contact build() {
        return (Contact) record;
    }
}
