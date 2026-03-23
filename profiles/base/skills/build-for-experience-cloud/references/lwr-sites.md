# LWR Sites (Build Your Own)

LWR sites use `DigitalExperienceBundle` (not `ExperienceBundle`) and `digitalExperiences/` directory.

```bash
sf community create --name "Site Name" --template-name "Build Your Own (LWR)" --url-path-prefix myprefix
sf project retrieve start --metadata "DigitalExperienceBundle"
sf community publish --name "Site Name"
```

## Route-Level Guest Access

Site-level `authenticationType` cannot be changed via deploy. Set `"pageAccess": "Public"` on individual routes:

```json
{
  "type": "sfdc_cms__route",
  "contentBody": {
    "pageAccess": "Public",
    "routeType": "home"
  }
}
```

## LWR-Specific Gotchas

- `geoBotsAllowed` field is rejected on deploy — remove if present
- Digital Experiences must be enabled via Setup UI before `sf community create` works
- LWR components need `lightningCommunity__Page` and `lightningCommunity__Default` targets (not `lightning__CommunityPage`)
