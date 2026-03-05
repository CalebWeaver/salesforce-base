# Trigger Handler (POC)

Only use when the demo requires backend automation (e.g., auto-assignment, field updates on save). Skip entirely for UI-only demos.

```apex
// Trigger file (one per object)
trigger FR_CaseTrigger on Case (before insert, before update, after insert, after update) {
    new FR_CaseTriggerHandler().run();
}

// Handler file — without sharing is fine for POC
public without sharing class FR_CaseTriggerHandler extends TriggerHandler {
    protected override void beforeInsert() {
        for (Case c : (List<Case>) Trigger.new) {
            if (c.Priority == null) {
                c.Priority = 'Medium';
            }
        }
    }
}
```

## Rules

- Only create triggers if the demo needs backend automation
- `without sharing` is fine — scratch orgs have one user
- Use the POC prefix on trigger and handler class names
- One trigger per object still applies (avoids trigger conflicts)
