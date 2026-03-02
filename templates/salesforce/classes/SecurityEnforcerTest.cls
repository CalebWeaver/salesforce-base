@IsTest
private class SecurityEnforcerTest {
    
    // ============================================================================
    // PATTERN: MockSObjectBuilder for complex test data
    // Use when you need formula fields, read-only fields, or complex relationships
    // ============================================================================
    
    @IsTest
    static void testCheckReadable_Success() {
        List<SObjectField> fields = new List<SObjectField>{
            Account.Name,
            Account.Industry
        };
        
        Test.startTest();
        SecurityEnforcer.checkReadable(Account.SObjectType, fields);
        Test.stopTest();
        
        System.assert(true, 'Should have read access to Account fields');
    }
    
    @IsTest
    static void testCheckCreatable_Success() {
        List<SObjectField> fields = new List<SObjectField>{ Account.Name };
        
        Test.startTest();
        SecurityEnforcer.checkCreatable(Account.SObjectType, fields);
        Test.stopTest();
        
        System.assert(true, 'Should have create access to Account.Name');
    }
    
    @IsTest
    static void testCheckUpdateable_Success() {
        List<SObjectField> fields = new List<SObjectField>{ Account.Name };
        
        Test.startTest();
        SecurityEnforcer.checkUpdateable(Account.SObjectType, fields);
        Test.stopTest();
        
        System.assert(true, 'Should have update access to Account.Name');
    }
    
    @IsTest
    static void testCheckDeletable_Success() {
        Test.startTest();
        SecurityEnforcer.checkDeletable(Account.SObjectType);
        Test.stopTest();
        
        System.assert(true, 'Should have delete access to Account');
    }
    
    // ============================================================================
    // PATTERN: MockSObjectBuilder for records with relationships and read-only fields
    // No DML required - builds mock records with parent/child relationships
    // ============================================================================
    
    @IsTest
    static void testStripInaccessible_WithMockBuilder() {
        // Use MockSObjectBuilder when you need:
        // - Formula field values
        // - Parent relationship data (e.g., Account.Owner.Name)
        // - Child relationships (e.g., Account with Contacts)
        // - Read-only system fields (CreatedDate, LastModifiedBy, etc.)
        
        Account mockAccount = (Account) new MockSObjectBuilder(Account.SObjectType)
            .setField('Name', 'Test Account')
            .setField('Industry', 'Technology')
            .setId()
            .build();
        
        List<Account> accounts = new List<Account>{ mockAccount };
        
        Test.startTest();
        List<SObject> result = SecurityEnforcer.stripInaccessible(AccessType.READABLE, accounts);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should return the mock record');
    }
    
    @IsTest
    static void testStripInaccessible_WithParentRelationship() {
        // Mock an Account with its Parent Account relationship populated
        Account parentAccount = (Account) new MockSObjectBuilder(Account.SObjectType)
            .setField('Name', 'Parent Corp')
            .setId()
            .build();
        
        Account childAccount = (Account) new MockSObjectBuilder(Account.SObjectType)
            .setField('Name', 'Child Division')
            .setId()
            .setParent('Parent', parentAccount)
            .build();
        
        Test.startTest();
        List<SObject> result = SecurityEnforcer.stripInaccessible(AccessType.READABLE, new List<Account>{ childAccount });
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should process record with parent relationship');
    }
    
    @IsTest
    static void testStripInaccessible_NullList() {
        Test.startTest();
        List<SObject> result = SecurityEnforcer.stripInaccessible(AccessType.READABLE, null);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null for null input');
    }
    
    @IsTest
    static void testStripInaccessible_EmptyList() {
        Test.startTest();
        List<SObject> result = SecurityEnforcer.stripInaccessible(AccessType.READABLE, new List<Account>());
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list');
    }
    
    @IsTest
    static void testIsAccessible() {
        Test.startTest();
        Boolean result = SecurityEnforcer.isAccessible(Account.SObjectType);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Account should be accessible');
    }
    
    @IsTest
    static void testIsCreateable() {
        Test.startTest();
        Boolean result = SecurityEnforcer.isCreateable(Account.SObjectType);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Account should be createable');
    }
    
    @IsTest
    static void testIsUpdateable() {
        Test.startTest();
        Boolean result = SecurityEnforcer.isUpdateable(Account.SObjectType);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Account should be updateable');
    }
    
    @IsTest
    static void testIsDeletable() {
        Test.startTest();
        Boolean result = SecurityEnforcer.isDeletable(Account.SObjectType);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Account should be deletable');
    }
    
    // ============================================================================
    // PATTERN: DataAccessor for mocking queries
    // Use when your service class queries data - inject mock accessor in tests
    // 
    // Example service using DataAccessor pattern:
    //
    //   public class AccountService {
    //       private AccountDataAccessor accessor;
    //       
    //       public AccountService() { this(new AccountDataAccessor()); }
    //       
    //       @TestVisible
    //       private AccountService(AccountDataAccessor accessor) {
    //           this.accessor = accessor;
    //       }
    //       
    //       public List<Account> processAccounts() {
    //           List<Account> accounts = accessor.getActiveAccounts();
    //           // Process accounts...
    //           return accounts;
    //       }
    //   }
    //
    // In test, use UniversalMocker to mock the accessor:
    //
    //   UniversalMocker mockAccessor = UniversalMocker.mock(AccountDataAccessor.class);
    //   mockAccessor.when('getActiveAccounts').thenReturn(mockAccounts);
    //   AccountService service = new AccountService(
    //       (AccountDataAccessor) mockAccessor.createStub()
    //   );
    // ============================================================================
}
