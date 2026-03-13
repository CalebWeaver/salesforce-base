# Experience Cloud Metadata — POC Quick Setup

Get an Experience Cloud site running in a scratch org fast. Skip granular permissions and sharing rules — use the POC catch-all permission set and fix it during promotion.

## Scratch Org Definition

Enable Experience Cloud features in `config/project-scratch-def.json`:

```json
{
  "orgName": "POC Scratch Org",
  "edition": "Developer",
  "features": ["Communities", "Sites"],
  "settings": {
    "experienceBundle": {
      "enableExperienceBundleMetadata": true
    },
    "communities": {
      "enableNetworkSettings": true
    }
  }
}
```

**`enableExperienceBundleMetadata`** is required — without it, you can't retrieve or deploy ExperienceBundles via metadata API.

## Quick Site Creation

Use the CLI to create a site without hand-writing Network/CustomSite metadata:

```bash
# Create a site from a template
sf community create --name "Demo Portal" --template-name "Build Your Own (LWR)" --url-path-prefix demo

# Wait for it to complete (async operation)
sf community publish --name "Demo Portal"
```

Available templates: `Build Your Own (LWR)`, `Customer Service`, `Help Center`. Use `Build Your Own (LWR)` for POCs — it's the most flexible.

After creation, retrieve the generated metadata to have it in source:

```bash
sf project retrieve start --metadata ExperienceBundle:Demo_Portal --metadata Network:Demo_Portal
```

## Guest User Setup (POC Shortcut)

Instead of creating granular permission sets and sharing rules, assign the POC's catch-all permission set directly to the guest user profile:

1. Find the guest user profile name — it's `{Site Label} Profile` (e.g., `Demo Portal Profile`)
2. Add object and field permissions to the guest profile metadata, or add them through Setup UI
3. Add Apex class access for any `@AuraEnabled` controllers guest users will invoke

```xml
<!-- In Profile: Demo_Portal_Profile -->
<classAccesses>
    <apexClass>FR_ArticleController</apexClass>
    <enabled>true</enabled>
</classAccesses>
<objectPermissions>
    <allowRead>true</allowRead>
    <object>Knowledge__kav</object>
</objectPermissions>
```

**Shortcut for object access**: In Setup, go to **Digital Experiences → All Sites → Workspaces → Administration → Pages → Go to Force.com → Public Access Settings**. Check the boxes for objects and fields the guest user needs.

## Deploying a Minimal ExperienceBundle

If you're building the site in Experience Builder (the UI), you don't need to deploy an ExperienceBundle from source. Just:

1. Create the site via CLI or Setup
2. Configure pages in Experience Builder
3. Publish from Experience Builder or CLI
4. Retrieve to source when you want to capture the state

If you do need to deploy from source, the minimum required files are:

```
experiences/Demo_Portal/
├── Demo_Portal.site              # Required — site definition
├── routes/
│   └── home.json                 # At least one route
└── views/
    └── home.json                 # Matching view for the route
```

Deploy with:

```bash
sf project deploy start --source-dir force-app --test-level NoTestRun
```

## Common Scratch Org Pitfalls

| Issue | Fix |
|-------|-----|
| `sf community create` fails with "Communities not enabled" | Add `"Communities"` to `features` array in scratch org definition |
| Site URL returns 404 | Publish the site: `sf community publish --name "Demo Portal"` |
| Guest user can't see any data | Add object permissions to guest profile + check sharing (or just enable "View All" for POC) |
| `Cannot retrieve ExperienceBundle` | Enable `experienceBundle.enableExperienceBundleMetadata` in scratch def |
| LWC doesn't appear in Experience Builder | Add `lightning__CommunityPage` to component's `targets` in `.js-meta.xml` |
| Site shows "Under Maintenance" | Network `status` is `DownForMaintenance` — change to `Live` or publish the site |

## Site URL in Scratch Orgs

Scratch org Experience Cloud sites use this URL pattern:

```
https://{domain}.scratch.my.site.com/{urlPathPrefix}/s/
```

The `/s/` suffix is required for LWR sites. If your links are breaking, make sure you're including it.

Get the site URL:

```bash
sf org open --path /demo/s/
```
