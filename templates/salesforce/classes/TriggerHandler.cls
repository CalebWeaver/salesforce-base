/**
 * Base trigger handler class - extend this for all trigger handlers.
 * 
 * Usage:
 *   1. Create a handler: public class AccountTriggerHandler extends TriggerHandler
 *   2. Override needed methods: protected override void beforeInsert() { ... }
 *   3. Call from trigger: new AccountTriggerHandler().run();
 */
public virtual class TriggerHandler {
    
    @TestVisible
    private static Set<String> disabledHandlers = new Set<String>();
    
    public void run() {
        if (isDisabled()) {
            return;
        }
        
        if (Trigger.isBefore) {
            if (Trigger.isInsert) beforeInsert();
            else if (Trigger.isUpdate) beforeUpdate();
            else if (Trigger.isDelete) beforeDelete();
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) afterInsert();
            else if (Trigger.isUpdate) afterUpdate();
            else if (Trigger.isDelete) afterDelete();
            else if (Trigger.isUndelete) afterUndelete();
        }
    }
    
    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}
    
    public static void disable(String handlerName) {
        disabledHandlers.add(handlerName);
    }
    
    public static void enable(String handlerName) {
        disabledHandlers.remove(handlerName);
    }
    
    private Boolean isDisabled() {
        return disabledHandlers.contains(getHandlerName());
    }
    
    private String getHandlerName() {
        return String.valueOf(this).split(':')[0];
    }
}
