# Scheduled Apex Pattern

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

## Scheduling Conventions

- Scheduled classes should be thin — just kick off a Batch or Queueable
- Store cron expressions in Custom Metadata if they need to be configurable
- Name scheduled jobs descriptively: `'Weekly Account Cleanup'`, not `'Job1'`
