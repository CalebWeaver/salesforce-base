# Batch Apex Pattern

```apex
public class AccountCleanupBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Integer successCount = 0;
    private Integer errorCount = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name FROM Account
            WHERE IsActive__c = false
            AND LastModifiedDate < LAST_N_DAYS:365
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Database.DeleteResult> results = Database.delete(scope, false);
        for (Database.DeleteResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            } else {
                errorCount++;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'Batch complete: ' + successCount + ' succeeded, ' + errorCount + ' failed');
    }
}

// Execute with configurable scope size
Database.executeBatch(new AccountCleanupBatch(), 200);
```

## Batch Conventions

- Use `Database.Stateful` when you need to track state across `execute()` calls (counts, error lists)
- Use `Database.AllowsCallouts` when making HTTP callouts in `execute()`
- Keep scope size reasonable (100–200) for complex processing; up to 2,000 for simple updates
- Pull scope sizes from Custom Metadata for configurability
- Use `Database.getQueryLocator` (not iterable) unless you need custom iteration
