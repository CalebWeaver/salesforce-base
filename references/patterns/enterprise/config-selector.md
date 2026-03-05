# Configuration Selector (FFLib-Integrated)

All Custom Metadata Type access goes through dedicated Selectors registered in `Application.cls`, keeping configuration reads mockable and testable.

**Template**: `AppConfigSelector.cls` in `templates/salesforce/classes/enterprise/` provides the base pattern.

## Registering Config Selectors

```apex
// Register in Application.cls Selector factory
App_Config__mdt.SObjectType => AppConfigSelector.class,
Feature_Flag__mdt.SObjectType => FeatureFlagSelector.class,
Integration_Config__mdt.SObjectType => IntegrationConfigSelector.class
```

## Consuming Configuration in Services

```apex
public class AccountService {

    public static void processAccounts(Set<Id> accountIds) {
        // Config access through selector — mockable in tests
        AppConfigSelector configSelector = AppConfigSelector.newInstance();
        String threshold = configSelector.getValue('Approval_Threshold', '10000');

        // Feature flag check
        FeatureFlagSelector flagSelector = FeatureFlagSelector.newInstance();
        if (!flagSelector.isEnabled('Enhanced_Validation')) {
            return;
        }

        // Custom Labels for user-facing messages
        String errorMsg = System.Label.Error_AccountNameRequired;

        // Hierarchy Custom Settings for per-user overrides
        My_Settings__c settings = My_Settings__c.getInstance();
        if (settings.Debug_Mode__c) {
            Logger.debug('Processing with threshold: ' + threshold);
        }

        // ... business logic
    }
}
```

## Testing Configuration

Mock the config selector like any other selector:

```apex
@IsTest
static void testWithCustomConfig() {
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    AppConfigSelector mockConfig = (AppConfigSelector) mocks.mock(AppConfigSelector.class);

    mocks.startStubbing();
    mocks.when(mockConfig.sObjectType()).thenReturn(App_Config__mdt.SObjectType);
    mocks.when(mockConfig.getValue('Approval_Threshold', '10000')).thenReturn('5000');
    mocks.stopStubbing();

    Application.Selector.setMock(mockConfig);

    // Test now uses threshold of 5000 without needing real CMDT records
    Test.startTest();
    AccountService.processAccounts(testAccountIds);
    Test.stopTest();
}
```

## Naming

| Custom Metadata Type | Selector Class |
|---------------------|----------------|
| `App_Config__mdt` | `AppConfigSelector` |
| `Feature_Flag__mdt` | `FeatureFlagSelector` |
| `Integration_Config__mdt` | `IntegrationConfigSelector` |
| `Field_Mapping__mdt` | `FieldMappingSelector` |

## Rules

- Don't query CMDTs inline in service/domain code — always go through a selector
- Don't skip the selector "because it's just config" — testability matters
- Don't use Custom Settings when Custom Metadata Types work — CMDTs are deployable and versionable
- Don't create a single "god config" CMDT — group by domain (integration, features, mappings)
