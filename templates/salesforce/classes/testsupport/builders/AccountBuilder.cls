/**
 * Fluent builder for Account test data.
 * Creates valid-by-default Account records without DML.
 * 
 * Usage:
 *   Account acc = new AccountBuilder()
 *       .withName('Acme Corp')
 *       .withBillingCity('San Francisco')
 *       .build();
 */
@IsTest
public class AccountBuilder extends BaseFluentBuilder {

    public AccountBuilder() {
        record = new Account();
        applyDefaults();
    }

    protected override void applyDefaults() {
        record.put(Account.Name, 'Test Account ' + TestIds.nextSuffix());
    }

    public AccountBuilder withName(String name) {
        record.put(Account.Name, name);
        return this;
    }

    public AccountBuilder withBillingCity(String city) {
        record.put(Account.BillingCity, city);
        return this;
    }

    public AccountBuilder withBillingState(String state) {
        record.put(Account.BillingState, state);
        return this;
    }

    public AccountBuilder withBillingCountry(String country) {
        record.put(Account.BillingCountry, country);
        return this;
    }

    public AccountBuilder withIndustry(String industry) {
        record.put(Account.Industry, industry);
        return this;
    }

    public AccountBuilder withType(String accountType) {
        record.put(Account.Type, accountType);
        return this;
    }

    public AccountBuilder withAnnualRevenue(Decimal revenue) {
        record.put(Account.AnnualRevenue, revenue);
        return this;
    }

    public AccountBuilder withPhone(String phone) {
        record.put(Account.Phone, phone);
        return this;
    }

    public AccountBuilder withWebsite(String website) {
        record.put(Account.Website, website);
        return this;
    }

    public AccountBuilder withParentId(Id parentId) {
        record.put(Account.ParentId, parentId);
        return this;
    }

    public AccountBuilder withParent(Account parent) {
        record.put(Account.ParentId, parent.Id);
        return this;
    }

    public new AccountBuilder withField(Schema.SObjectField field, Object value) {
        record.put(field, value);
        return this;
    }

    public Account build() {
        return (Account) record;
    }
}
