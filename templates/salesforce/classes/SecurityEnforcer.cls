/**
 * Utility class for CRUD/FLS security enforcement.
 * 
 * Usage:
 *   SecurityEnforcer.checkReadable(Account.SObjectType, new List<SObjectField>{Account.Name});
 *   SecurityEnforcer.checkCreatable(Account.SObjectType, new List<SObjectField>{Account.Name});
 *   List<Account> safe = SecurityEnforcer.stripInaccessible(AccessType.READABLE, accounts);
 */
public with sharing class SecurityEnforcer {
    
    public class SecurityException extends Exception {}
    
    public static void checkReadable(SObjectType objType, List<SObjectField> fields) {
        if (!objType.getDescribe().isAccessible()) {
            throw new SecurityException('No read access to ' + objType);
        }
        for (SObjectField field : fields) {
            if (!field.getDescribe().isAccessible()) {
                throw new SecurityException('No read access to field ' + field);
            }
        }
    }
    
    public static void checkCreatable(SObjectType objType, List<SObjectField> fields) {
        if (!objType.getDescribe().isCreateable()) {
            throw new SecurityException('No create access to ' + objType);
        }
        for (SObjectField field : fields) {
            if (!field.getDescribe().isCreateable()) {
                throw new SecurityException('No create access to field ' + field);
            }
        }
    }
    
    public static void checkUpdateable(SObjectType objType, List<SObjectField> fields) {
        if (!objType.getDescribe().isUpdateable()) {
            throw new SecurityException('No update access to ' + objType);
        }
        for (SObjectField field : fields) {
            if (!field.getDescribe().isUpdateable()) {
                throw new SecurityException('No update access to field ' + field);
            }
        }
    }
    
    public static void checkDeletable(SObjectType objType) {
        if (!objType.getDescribe().isDeletable()) {
            throw new SecurityException('No delete access to ' + objType);
        }
    }
    
    public static List<SObject> stripInaccessible(AccessType accessType, List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return records;
        }
        SObjectAccessDecision decision = Security.stripInaccessible(accessType, records);
        return decision.getRecords();
    }
    
    public static Boolean isAccessible(SObjectType objType) {
        return objType.getDescribe().isAccessible();
    }
    
    public static Boolean isCreateable(SObjectType objType) {
        return objType.getDescribe().isCreateable();
    }
    
    public static Boolean isUpdateable(SObjectType objType) {
        return objType.getDescribe().isUpdateable();
    }
    
    public static Boolean isDeletable(SObjectType objType) {
        return objType.getDescribe().isDeletable();
    }
}
