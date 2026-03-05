/**
 * Application factory - central registry for FFLib dependency injection.
 *
 * Register all Domain, Selector, Service, and UnitOfWork bindings here.
 * This is the single source of truth for layer wiring in the application.
 *
 * Usage:
 *   - UnitOfWork: Application.UnitOfWork.newInstance()
 *   - Selector:   Application.Selector.newInstance(Account.SObjectType)
 *   - Domain:     Application.Domain.newInstance(records)
 *   - Service:    Application.Service.newInstance(IAccountService.class)
 *
 * When adding a new object:
 *   1. Add SObjectType to UnitOfWork list (in DML dependency order)
 *   2. Register Selector in Selector factory map
 *   3. Register Domain Constructor in Domain factory map
 *   4. Register Service implementation in Service factory map (if applicable)
 */
public class Application {

    /**
     * Unit of Work factory.
     * List SObjectTypes in DML dependency order (parents before children).
     */
    public static final fflib_Application.UnitOfWorkFactory UnitOfWork =
        new fflib_Application.UnitOfWorkFactory(
            new List<SObjectType>{
                Account.SObjectType,
                Contact.SObjectType
                // Add SObjectTypes in dependency order as project grows
            }
        );

    /**
     * Selector factory.
     * Maps SObjectType to its Selector class.
     */
    public static final fflib_Application.SelectorFactory Selector =
        new fflib_Application.SelectorFactory(
            new Map<SObjectType, Type>{
                // Account.SObjectType => AccountsSelector.class
                // Add selectors as they are created
            }
        );

    /**
     * Domain factory.
     * Maps SObjectType to its Domain Constructor class.
     */
    public static final fflib_Application.DomainFactory Domain =
        new fflib_Application.DomainFactory(
            Application.Selector,
            new Map<SObjectType, Type>{
                // Account.SObjectType => Accounts.Constructor.class
                // Add domain constructors as they are created
            }
        );

    /**
     * Service factory.
     * Maps Service interface to its implementation class.
     */
    public static final fflib_Application.ServiceFactory Service =
        new fflib_Application.ServiceFactory(
            new Map<Type, Type>{
                // IAccountService.class => AccountService.class
                // Add service bindings as they are created
            }
        );
}
