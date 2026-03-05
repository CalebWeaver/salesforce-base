/**
 * Selector for application configuration via Custom Metadata Types.
 *
 * Registered in Application.cls Selector factory so it can be mocked in tests.
 * Provides cached access to CMDT records by DeveloperName.
 *
 * Usage (production):
 *   AppConfigSelector selector = AppConfigSelector.newInstance();
 *   App_Config__mdt config = selector.selectByDeveloperName('My_Setting');
 *   Map<String, App_Config__mdt> all = selector.selectAll();
 *
 * Usage (test with mock):
 *   fflib_ApexMocks mocks = new fflib_ApexMocks();
 *   AppConfigSelector mockSelector = (AppConfigSelector) mocks.mock(AppConfigSelector.class);
 *   mocks.startStubbing();
 *   mocks.when(mockSelector.sObjectType()).thenReturn(App_Config__mdt.SObjectType);
 *   mocks.when(mockSelector.selectByDeveloperName('My_Setting')).thenReturn(myMockConfig);
 *   mocks.stopStubbing();
 *   Application.Selector.setMock(mockSelector);
 *
 * IMPORTANT: Replace App_Config__mdt with your actual Custom Metadata Type API name.
 * Create additional selectors for each distinct CMDT (e.g., FeatureFlagSelector,
 * IntegrationConfigSelector) following this same pattern.
 */
public class AppConfigSelector extends fflib_SObjectSelector {

    // ─── Transaction-level cache ────────────────────────────────
    private static Map<String, App_Config__mdt> cachedByDevName;

    // ─── Factory method ─────────────────────────────────────────
    public static AppConfigSelector newInstance() {
        return (AppConfigSelector) Application.Selector.newInstance(App_Config__mdt.SObjectType);
    }

    // ─── Required overrides ─────────────────────────────────────

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            App_Config__mdt.Id,
            App_Config__mdt.DeveloperName,
            App_Config__mdt.MasterLabel,
            App_Config__mdt.Value__c
            // Add additional fields as your CMDT grows
        };
    }

    public Schema.SObjectType getSObjectType() {
        return App_Config__mdt.SObjectType;
    }

    // ─── CMDT does not enforce CRUD/FLS ─────────────────────────
    public override Boolean isEnforcingFLS() {
        return false;
    }

    public override Boolean isEnforcingCRUD() {
        return false;
    }

    // ─── Query methods ──────────────────────────────────────────

    /**
     * Returns all config records keyed by DeveloperName.
     * Uses getAll() for zero-SOQL access; cached for the transaction.
     */
    public Map<String, App_Config__mdt> selectAll() {
        if (cachedByDevName == null) {
            cachedByDevName = new Map<String, App_Config__mdt>();
            for (App_Config__mdt record : App_Config__mdt.getAll().values()) {
                cachedByDevName.put(record.DeveloperName, record);
            }
        }
        return cachedByDevName;
    }

    /**
     * Returns a single config record by DeveloperName, or null if not found.
     */
    public App_Config__mdt selectByDeveloperName(String developerName) {
        return selectAll().get(developerName);
    }

    /**
     * Returns the Value__c field for a given DeveloperName, or a default if not found.
     */
    public String getValue(String developerName, String defaultValue) {
        App_Config__mdt config = selectByDeveloperName(developerName);
        return config != null && config.Value__c != null ? config.Value__c : defaultValue;
    }

    /**
     * Clears the transaction cache. Useful in tests after inserting CMDT records
     * or when switching mock configurations mid-test.
     */
    @TestVisible
    private static void clearCache() {
        cachedByDevName = null;
    }
}
