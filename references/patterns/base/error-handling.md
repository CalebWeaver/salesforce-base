# Error Handling

## Partial Success with Database Methods

Use `Database.insert(records, false)` for partial success. The second parameter (`false`) means allOrNothing is disabled — some records can succeed while others fail.

```apex
List<Database.SaveResult> results = Database.insert(accounts, false);
for (Integer i = 0; i < results.size(); i++) {
    if (!results[i].isSuccess()) {
        for (Database.Error err : results[i].getErrors()) {
            System.debug(LoggingLevel.ERROR, 'Error: ' + err.getMessage());
        }
    }
}
```

## When to Use

- **`Database.insert(records, false)`** — when processing a batch and some failures are acceptable
- **`insert records`** (allOrNothing) — when all records must succeed or none should

## Logging Errors

Use `System.debug()` with appropriate `LoggingLevel` for basic logging:

```apex
System.debug(LoggingLevel.ERROR, 'Error processing record: ' + record.Id);
System.debug(LoggingLevel.WARN, 'Unexpected state: ' + detail);
System.debug(LoggingLevel.INFO, 'Processing complete: ' + count + ' records');
System.debug(LoggingLevel.DEBUG, 'Variable value: ' + value);
```

See profile-specific rules for enterprise logging options (NebulaLogger).
