# Guest User Configuration

## Guest User Profile

Every Experience Cloud site gets an auto-created guest user profile named `{Site Label} Profile`.

```xml
<!-- In Profile: Customer_Portal_Profile -->
<objectPermissions>
    <allowCreate>false</allowCreate>
    <allowDelete>false</allowDelete>
    <allowEdit>false</allowEdit>
    <allowRead>true</allowRead>
    <object>Knowledge__kav</object>
</objectPermissions>
<fieldPermissions>
    <editable>false</editable>
    <field>Knowledge__kav.Title</field>
    <readable>true</readable>
</fieldPermissions>
<classAccesses>
    <apexClass>KnowledgeArticleController</apexClass>
    <enabled>true</enabled>
</classAccesses>
```

Guest user security rules:
- Guest users run `without sharing` by default — they have no User record for sharing evaluation
- Always validate data access in Apex for guest-facing controllers
- Never grant guest users Modify All or View All on any object

## Sharing Rules for Guest Access

Guest users belong to public group `{SiteApiName}_Site_Guest_User`. Create criteria-based sharing rules to expose records:

```xml
<sharingCriteriaRules>
    <fullName>Knowledge__kav.Guest_Published_Articles</fullName>
    <accessLevel>Read</accessLevel>
    <sharedTo>
        <group>Customer_Portal_Site_Guest_User</group>
    </sharedTo>
    <criteriaItems>
        <field>PublishStatus</field>
        <operation>equals</operation>
        <value>Online</value>
    </criteriaItems>
</sharingCriteriaRules>
```

## Apex Controllers for Guest Users

```apex
public without sharing class PublicArticleController {

    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> getPublishedArticles(String category) {
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

| Rule | Rationale |
|------|-----------|
| **Validate all input** | Guest users are anonymous — treat all parameters as untrusted |
| **Use explicit SOQL filters** | Don't rely on sharing rules alone; filter on status, visibility fields, etc. |
| **Always use LIMIT** | Prevent data harvesting via large result sets |
| **Never expose PII** | Guest controllers should never return other users' personal data |
| **Add to guest profile `classAccesses`** | Controller won't work for guest users without this |
