# NebulaLogger

Enterprise logging using [NebulaLogger](https://github.com/jongpie/NebulaLogger) instead of `System.debug()`.

**Install**: See `references/repos.json` for package install commands.

## Usage

```apex
Logger.error('Error message', record).addTag('MyFeature');
Logger.warn('Warning message');
Logger.info('Info message');
Logger.debug('Debug message');
Logger.saveLog();
```

## Features

- Persistent logs stored in `Log__c` / `LogEntry__c` custom objects
- Tagging with `.addTag('FeatureName')` for log categorization and filtering
- Flow support for declarative logging
- LWC support for client-side logging
- Configurable log retention policies

## Rules

- Always call `Logger.saveLog()` to persist — logs are buffered until this call
- Use `.addTag()` consistently to categorize by feature area
- Use appropriate log levels: `error` for failures, `warn` for unexpected states, `info` for milestones, `debug` for development details
- Reference `references/NebulaLogger/` for full patterns after syncing
