# Configuration Access (Lightweight)

Query Custom Metadata Types directly in Apex — no accessor class needed. Cache results in static variables when a method is called multiple times in the same transaction.

## Direct CMDT Query with Static Cache

```apex
private static Map<String, Integration_Config__mdt> integrationConfigs;

public static Integration_Config__mdt getIntegrationConfig(String developerName) {
    if (integrationConfigs == null) {
        integrationConfigs = new Map<String, Integration_Config__mdt>();
        for (Integration_Config__mdt config : Integration_Config__mdt.getAll().values()) {
            integrationConfigs.put(config.DeveloperName, config);
        }
    }
    return integrationConfigs.get(developerName);
}
```

## Custom Labels

```apex
String errorMsg = System.Label.Error_AccountNameRequired;
```

## Hierarchy Custom Settings

```apex
My_Settings__c settings = My_Settings__c.getInstance();
if (settings.Debug_Mode__c) {
    System.debug('Debug info...');
}
```

## Rules

- Keep configuration access simple
- If you find yourself creating a dedicated configuration class, make it a single static utility
- Don't create a service/selector pattern for configuration in lightweight projects
