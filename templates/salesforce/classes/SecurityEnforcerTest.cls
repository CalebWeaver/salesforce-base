@IsTest
private class SecurityEnforcerTest {
    
    @IsTest
    static void testCheckReadable_Success() {
        // Standard user should have read access to Account
        List<SObjectField> fields = new List<SObjectField>{
            Account.Name,
            Account.Industry
        };
        
        Test.startTest();
        SecurityEnforcer.checkReadable(Account.SObjectType, fields);
        Test.stopTest();
        
        // No exception means success
        System.assert(true, 'Should have read access to Account fields');
    }
    
    @IsTest
    static void testCheckCreatable_Success() {
        List<SObjectField> fields = new List<SObjectField>{
            Account.Name
        };
        
        Test.startTest();
        SecurityEnforcer.checkCreatable(Account.SObjectType, fields);
        Test.stopTest();
        
        System.assert(true, 'Should have create access to Account.Name');
    }
    
    @IsTest
    static void testCheckUpdateable_Success() {
        List<SObjectField> fields = new List<SObjectField>{
            Account.Name
        };
        
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
    
    @IsTest
    static void testStripInaccessible_WithRecords() {
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test 1'),
            new Account(Name = 'Test 2')
        };
        
        Test.startTest();
        List<SObject> result = SecurityEnforcer.stripInaccessible(AccessType.CREATABLE, accounts);
        Test.stopTest();
        
        System.assertEquals(2, result.size(), 'Should return same number of records');
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
}
