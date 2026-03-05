/**
 * Abstract base class for fluent test data builders.
 * Builders create valid-by-default SObjects without performing DML.
 * 
 * Usage:
 *   Account acc = new AccountBuilder().withName('Acme').build();
 * 
 * Rules:
 *   - Builders NEVER insert records
 *   - Builders NEVER query the database
 *   - Builders set sensible defaults for required fields
 *   - Use TestDataGraph for all DML operations
 */
@IsTest
public abstract class BaseFluentBuilder {

    protected SObject record;

    /**
     * Subclasses must implement to set up required field defaults.
     */
    protected abstract void applyDefaults();

    /**
     * Generic field setter for any field on the SObject.
     */
    public BaseFluentBuilder withField(Schema.SObjectField field, Object value) {
        record.put(field, value);
        return this;
    }

    /**
     * Returns the built record WITHOUT inserting.
     */
    public SObject build() {
        return record;
    }

    /**
     * Returns the record cast to a specific type.
     */
    public SObject getRecord() {
        return record;
    }
}
