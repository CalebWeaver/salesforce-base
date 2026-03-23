# Profile-Specific Async Patterns

## Lightweight: Enqueue from Trigger Handlers

Async classes are standalone — query, process, and DML directly. Enqueue from trigger handlers:

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

## Enterprise: Delegate to Service Layer

Async classes delegate to Service methods and use Unit of Work. Enqueue from Domain or Service — never from Selectors:

```apex
public class OrderSyncQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> orderIds;

    public OrderSyncQueueable(Set<Id> orderIds) {
        this.orderIds = orderIds;
    }

    public void execute(QueueableContext context) {
        try {
            OrderService.syncToExternalSystem(orderIds);
        } catch (Exception ex) {
            Logger.error('OrderSync failed', ex);
            Logger.saveLog();
        }
    }
}
```

Enqueue after `commitWork()` in a Service method:

```apex
public static void activateOrders(Set<Id> orderIds) {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    // ... activate logic ...
    uow.commitWork();

    System.enqueueJob(new OrderSyncQueueable(orderIds));
}
```

## Testing Async

```apex
@IsTest
static void testQueueableProcessesRecords() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
        accounts.add(new AccountBuilder().withName('Test ' + i).build());
    }
    insert accounts;

    Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

    Test.startTest();
    System.enqueueJob(new AccountSyncQueueable(accountIds));
    Test.stopTest();  // Executes async job synchronously

    List<Account> updated = [SELECT Id, Sync_Status__c FROM Account WHERE Id IN :accountIds];
    for (Account acc : updated) {
        System.assertEquals('Synced', acc.Sync_Status__c);
    }
}
```
