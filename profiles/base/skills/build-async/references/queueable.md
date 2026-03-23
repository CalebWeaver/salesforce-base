# Queueable Apex Pattern

```apex
public class AccountSyncQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> accountIds;

    public AccountSyncQueueable(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext context) {
        try {
            List<Account> accounts = [
                SELECT Id, Name, External_Id__c
                FROM Account
                WHERE Id IN :accountIds
                WITH SECURITY_ENFORCED
            ];
            // Processing logic here
        } catch (Exception ex) {
            // Always handle errors — async failures are silent otherwise
            System.debug(LoggingLevel.ERROR, 'AccountSync failed: ' + ex.getMessage());
        }
    }
}
```

## Enqueuing from Triggers

Collect IDs first, enqueue once — never enqueue inside a loop:

```apex
// ✅ Correct: collect, then enqueue once
Set<Id> idsToProcess = new Set<Id>();
for (Account acc : (List<Account>) Trigger.new) {
    if (acc.Needs_Sync__c) {
        idsToProcess.add(acc.Id);
    }
}
if (!idsToProcess.isEmpty()) {
    System.enqueueJob(new AccountSyncQueueable(idsToProcess));
}

// ❌ Wrong: enqueuing inside a loop
for (Account acc : (List<Account>) Trigger.new) {
    System.enqueueJob(new AccountSyncQueueable(new Set<Id>{acc.Id}));
}
```

## Chaining Queueables

```apex
public void execute(QueueableContext context) {
    // Do step 1 work...

    // Chain step 2 if more work remains
    if (!remainingIds.isEmpty()) {
        System.enqueueJob(new Step2Queueable(remainingIds));
    }
}
```
