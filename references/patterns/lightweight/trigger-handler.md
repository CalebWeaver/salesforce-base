# Lightweight Trigger Handler Pattern

One trigger per object. Handler extends `TriggerHandler` base class. Logic lives directly in the handler — no service or domain layers.

Check for existing `TriggerHandler` in project. If none exists, copy from `templates/salesforce/classes/TriggerHandler.cls`.

## Trigger File

```apex
trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    new AccountTriggerHandler().run();
}
```

## Handler File

```apex
public class AccountTriggerHandler extends TriggerHandler {
    protected override void beforeInsert() {
        // Logic goes here, directly in the handler
        for (Account acc : (List<Account>) Trigger.new) {
            if (acc.Name == null) {
                acc.addError('Name is required');
            }
        }
    }
}
```

## Rules

- Never put logic directly in triggers
- One trigger per object — register all events in the trigger, handle them in the handler
- If a handler grows beyond ~200 lines, extract logic into a focused utility class
- Don't pre-create service/domain/selector layers "just in case"
