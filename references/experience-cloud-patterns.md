# Experience Cloud — LWC and Apex Patterns

Patterns for building Lightning Web Components and Apex controllers that work in Experience Cloud (Digital Experiences). This covers component exposure, guest user controller considerations, and navigation.

## Exposing LWCs to Experience Cloud

Every LWC that should appear in Experience Builder needs `lightning__CommunityPage` in its targets:

```xml
<!-- myComponent.js-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>My Component</masterLabel>
    <targets>
        <target>lightning__CommunityPage</target>
        <target>lightning__RecordPage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__CommunityPage">
            <property name="title" type="String" label="Title" default="Welcome"/>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

### Key Points

- `isExposed` must be `true` for the component to appear in Experience Builder
- `lightning__CommunityPage` — makes it available on custom Experience Cloud pages
- `lightning__CommunityPage` properties appear as configurable options in Experience Builder
- Components can target both `lightning__CommunityPage` and internal targets (`lightning__RecordPage`, `lightning__AppPage`) simultaneously
- `masterLabel` controls the display name in Experience Builder's component palette

### Guest-Accessible Components

Components intended for guest (unauthenticated) users must ensure their Apex controllers don't require authentication:

1. The Apex controller class must be added to the guest user profile's `classAccesses`
2. The controller should not assume a running user context (no `UserInfo.getUserId()` for real user data)
3. Data queries must account for sharing — guest users have no sharing rules by default unless you create them

## Apex Controllers for Guest Users

### Controller Pattern

Guest-facing controllers typically need `without sharing` because the guest user has no sharing rules granting record access. Use criteria-based sharing rules or `without sharing` with explicit SOQL filters.

```apex
public without sharing class PublicArticleController {

    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> getPublishedArticles(String category) {
        // Explicit filters replace sharing-based security
        return [
            SELECT Id, Title, Summary, LastPublishedDate
            FROM Knowledge__kav
            WHERE PublishStatus = 'Online'
            AND Category__c = :category
            ORDER BY LastPublishedDate DESC
            LIMIT 20
        ];
    }

    @AuraEnabled
    public static Id submitCase(String subject, String description, String email) {
        // Validate inputs — guest users are unauthenticated, treat all input as untrusted
        if (String.isBlank(subject) || String.isBlank(email)) {
            throw new AuraHandledException('Subject and email are required.');
        }

        Case newCase = new Case(
            Subject = subject,
            Description = description,
            SuppliedEmail = email,
            Origin = 'Web',
            Status = 'New'
        );
        insert newCase;
        return newCase.Id;
    }
}
```

### Security Considerations for Guest Controllers

| Rule | Rationale |
|------|-----------|
| **Validate all input** | Guest users are anonymous — treat all parameters as untrusted |
| **Use explicit SOQL filters** | Don't rely on sharing rules alone; filter on status, visibility fields, etc. |
| **Limit query results** | Always use `LIMIT` — prevent data harvesting via large result sets |
| **Don't expose internal IDs** | Avoid returning record IDs that reveal org structure unless necessary |
| **Never expose PII** | Guest controllers should never return other users' personal data |
| **Use `without sharing` deliberately** | Document why each guest controller needs `without sharing` |
| **Add to guest profile `classAccesses`** | Controller won't work for guest users without this |

### Authenticated Community User Controllers

For logged-in community users (Customer Community Login, Partner Community licenses), standard `with sharing` works because these users have sharing rules and role hierarchy access. Use the same patterns as internal LWC controllers.

```apex
public with sharing class CommunityAccountController {

    @AuraEnabled(cacheable=true)
    public static Account getMyAccount() {
        // Sharing rules limit this to the community user's account
        Id contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        Id accountId = [SELECT AccountId FROM Contact WHERE Id = :contactId].AccountId;

        return [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState
            FROM Account
            WHERE Id = :accountId
            WITH SECURITY_ENFORCED
        ];
    }
}
```

## Community Context in Apex

Access the current community/network context:

```apex
// Get current Network (community) Id
Id networkId = Network.getNetworkId();

// Get Network details
ConnectApi.Community community = ConnectApi.Communities.getCommunity(networkId);
String communityName = community.name;
String communityUrl = community.siteUrl;

// Check if running in a community context (vs internal Salesforce)
Boolean isCommunityContext = networkId != null;
```

Use `Network.getNetworkId()` to branch behavior between internal Salesforce and Experience Cloud contexts. This is useful for controllers shared between internal and external users.

## Navigation in Experience Cloud

### NavigationMixin Differences

LWCs in Experience Cloud use the same `NavigationMixin` as internal pages, but with community-specific page references:

```javascript
import { NavigationMixin } from 'lightning/navigation';

export default class CommunityNav extends NavigationMixin(LightningElement) {

    navigateToCustomPage() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',       // Community named page
            attributes: {
                name: 'Contact_Support__c'  // Page API name from Experience Builder
            }
        });
    }

    navigateToRecordPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }

    navigateToObjectList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'list'
            }
        });
    }

    navigateToExternalUrl() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://example.com'
            }
        });
    }
}
```

### Community-Specific Page Types

| Page Reference Type | Use Case |
|---------------------|----------|
| `comm__namedPage` | Custom pages created in Experience Builder |
| `standard__recordPage` | Record detail pages (works same as internal) |
| `standard__objectPage` | Object list pages |
| `standard__webPage` | External URLs |
| `comm__loginPage` | Redirect to login page |

### Standard Community Pages

These pages exist by default in Experience Cloud sites and can be navigated to:

- `Home` — site home page
- `Login` — login page
- `Forgot_Password` — password reset
- `Self_Register` — self-registration (if enabled)
- `Check_Password` — password verification
- `Error` — error page

```javascript
// Navigate to login
this[NavigationMixin.Navigate]({
    type: 'comm__namedPage',
    attributes: {
        name: 'Login'
    }
});
```

## Base Path Awareness

Experience Cloud sites have a base path (`/prefix/s/`). When constructing URLs manually (rare, but sometimes needed for integrations):

```javascript
import communityBasePath from '@salesforce/community/basePath';

// communityBasePath returns something like "/customers/s"
const fullUrl = `${window.location.origin}${communityBasePath}/custom-page`;
```

Prefer `NavigationMixin` over manual URL construction whenever possible.
