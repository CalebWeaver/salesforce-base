/**
 * Base class for data access - abstracts SOQL queries for testability.
 * Extend this class and override methods to inject mock data in tests.
 * 
 * Usage in production code:
 *   public class AccountService {
 *       private AccountDataAccessor dataAccessor;
 *       
 *       public AccountService() {
 *           this(new AccountDataAccessor());
 *       }
 *       
 *       @TestVisible
 *       private AccountService(AccountDataAccessor dataAccessor) {
 *           this.dataAccessor = dataAccessor;
 *       }
 *       
 *       public List<Account> getActiveAccounts() {
 *           return dataAccessor.getActiveAccounts();
 *       }
 *   }
 * 
 * Usage in tests:
 *   AccountDataAccessor mockAccessor = (AccountDataAccessor) Test.createStub(
 *       AccountDataAccessor.class, 
 *       new UniversalMocker(AccountDataAccessor.class)
 *           .when('getActiveAccounts').thenReturn(mockAccounts)
 *   );
 *   AccountService service = new AccountService(mockAccessor);
 */
public virtual with sharing class DataAccessor {
    
    @TestVisible
    protected virtual List<SObject> query(String queryString) {
        return Database.query(queryString);
    }
    
    @TestVisible
    protected virtual List<SObject> queryWithBinds(String queryString, Map<String, Object> bindMap, AccessLevel accessLevel) {
        return Database.queryWithBinds(queryString, bindMap, accessLevel);
    }
    
    @TestVisible
    protected virtual SObject querySingle(String queryString) {
        List<SObject> results = Database.query(queryString);
        return results.isEmpty() ? null : results[0];
    }
}
