# Async Processing Patterns

Detailed patterns and examples for Salesforce async processing. Referenced from the base rules.

## Decision Flow

1. **Need to process > 2,000 records?** → Batch Apex
2. **Need to chain multiple async steps?** → Queueable
3. **Need to run on a schedule?** → Scheduled Apex (kicks off Batch or Queueable)
4. **Need to decouple producer from consumer?** → Platform Events
5. **Simple one-off async with only primitives?** → Future (but prefer Queueable)

## Queueable Pattern

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

### Enqueuing from Triggers

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
    System.enqueueJob(new AccountSyncQueueable(new Set<Id>{acc.Id})); // Don't do this
}
```

### Chaining Queueables

```apex
public void execute(QueueableContext context) {
    // Do step 1 work...

    // Chain step 2 if more work remains
    if (!remainingIds.isEmpty()) {
        System.enqueueJob(new Step2Queueable(remainingIds));
    }
}
```

## Batch Apex Pattern

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

### Batch Conventions

- Use `Database.Stateful` when you need to track state across `execute()` calls (counts, error lists)
- Use `Database.AllowsCallouts` when making HTTP callouts in `execute()`
- Keep scope size reasonable (100–200) for complex processing; up to 2,000 for simple updates
- Pull scope sizes from Custom Metadata for configurability
- Use `Database.getQueryLocator` (not iterable) unless you need custom iteration

## Scheduled Apex Pattern

```apex
public class WeeklyCleanupScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AccountCleanupBatch(), 200);
    }
}

// Schedule from developer console or script
// Every Sunday at 2 AM
System.schedule('Weekly Account Cleanup', '0 0 2 ? * SUN', new WeeklyCleanupScheduler());
```

### Scheduling Conventions

- Scheduled classes should be thin — just kick off a Batch or Queueable
- Store cron expressions in Custom Metadata if they need to be configurable
- Name scheduled jobs descriptively: `'Weekly Account Cleanup'`, not `'Job1'`

## Platform Events Pattern

```apex
// Publishing
List<Order_Event__e> events = new List<Order_Event__e>();
for (Order ord : orders) {
    events.add(new Order_Event__e(
        Order_Id__c = ord.Id,
        Action__c = 'Created'
    ));
}
List<Database.SaveResult> results = EventBus.publish(events);

// Subscribing (trigger on the platform event)
trigger OrderEventTrigger on Order_Event__e (after insert) {
    new OrderEventHandler().run();
}
```

### Platform Event Conventions

- Use `EventBus.publish()` instead of `insert` for better error handling
- Set `Publish Behavior` to "Publish After Commit" unless immediate publishing is required
- Platform event triggers run in their own transaction — they can't roll back the publisher
- Use replay ID for subscriber recovery after failures

## Lightweight Profile: Async Integration

In lightweight projects, async classes are standalone — they query, process, and DML directly. Enqueue from trigger handlers:

```apex
public class OrderTriggerHandler extends TriggerHandler {
    protected override void afterUpdate() {
        Set<Id> syncIds = new Set<Id>();
        for (Order ord : (List<Order>) Trigger.new) {
            Order old = (Order) Trigger.oldMap.get(ord.Id);
            if (ord.Status != old.Status && ord.Status == 'Activated') {
                syncIds.add(ord.Id);
            }
        }
        if (!syncIds.isEmpty()) {
            System.enqueueJob(new OrderSyncQueueable(syncIds));
        }
    }
}
```

## Enterprise Profile: Async Integration

In enterprise projects, async classes should delegate to Service methods and use Unit of Work:

```apex
public class OrderSyncQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> orderIds;

    public OrderSyncQueueable(Set<Id> orderIds) {
        this.orderIds = orderIds;
    }

    public void execute(QueueableContext context) {
        try {
            // Delegate to the service layer
            OrderService.syncToExternalSystem(orderIds);
        } catch (Exception ex) {
            Logger.error('OrderSync failed', ex);
            Logger.saveLog();
        }
    }
}
```

Service methods called from async context follow the same UoW pattern:

```apex
public class OrderService {
    public static void syncToExternalSystem(Set<Id> orderIds) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        List<Order> orders = OrdersSelector.newInstance().selectById(orderIds);

        for (Order ord : orders) {
            // Callout and processing...
            ord.Sync_Status__c = 'Synced';
            uow.registerDirty(ord);
        }

        uow.commitWork();
    }
}
```

Enqueue from Domain classes or Service methods — never from Selectors:

```apex
// In a Service method
public static void activateOrders(Set<Id> orderIds) {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    // ... activate logic ...
    uow.commitWork();

    // Enqueue async sync after commit
    System.enqueueJob(new OrderSyncQueueable(orderIds));
}
```

## Testing Async

```apex
@IsTest
static void testQueueableProcessesRecords() {
    // Setup test data
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
        accounts.add(new AccountBuilder().withName('Test ' + i).build());
    }
    insert accounts;

    Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

    // Async executes synchronously between startTest/stopTest
    Test.startTest();
    System.enqueueJob(new AccountSyncQueueable(accountIds));
    Test.stopTest();

    // Assert results
    List<Account> updated = [SELECT Id, Sync_Status__c FROM Account WHERE Id IN :accountIds];
    for (Account acc : updated) {
        System.assertEquals('Synced', acc.Sync_Status__c);
    }
}
```
