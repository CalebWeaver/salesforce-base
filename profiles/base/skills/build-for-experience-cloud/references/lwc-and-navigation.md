# LWC and Navigation in Experience Cloud

## Exposing LWCs to Experience Cloud

Add `lightning__CommunityPage` to component targets:

```xml
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

## Navigation

```javascript
import { NavigationMixin } from 'lightning/navigation';

export default class CommunityNav extends NavigationMixin(LightningElement) {

    navigateToCustomPage() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Contact_Support__c'
            }
        });
    }
}
```

| Page Reference Type | Use Case |
|---------------------|----------|
| `comm__namedPage` | Custom pages created in Experience Builder |
| `standard__recordPage` | Record detail pages |
| `standard__objectPage` | Object list pages |
| `standard__webPage` | External URLs |
| `comm__loginPage` | Redirect to login page |
