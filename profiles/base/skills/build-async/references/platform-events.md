# Platform Events Pattern

## Publishing

```apex
List<Order_Event__e> events = new List<Order_Event__e>();
for (Order ord : orders) {
    events.add(new Order_Event__e(
        Order_Id__c = ord.Id,
        Action__c = 'Created'
    ));
}
List<Database.SaveResult> results = EventBus.publish(events);
```

## Subscribing (trigger on the platform event)

```apex
trigger OrderEventTrigger on Order_Event__e (after insert) {
    new OrderEventHandler().run();
}
```

## Platform Event Conventions

- Use `EventBus.publish()` instead of `insert` for better error handling
- Set `Publish Behavior` to "Publish After Commit" unless immediate publishing is required
- Platform event triggers run in their own transaction — they can't roll back the publisher
- Use replay ID for subscriber recovery after failures
