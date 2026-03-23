---
name: build-for-experience-cloud
description: How to build and deploy Experience Cloud sites — deployment order, guest user configuration, LWR vs Aura metadata, and common pitfalls.
---

## Critical Rules

Experience Cloud metadata is among the most complex in Salesforce — deployment order matters, ExperienceBundles are large and conflict-prone, and guest user configuration requires coordinating profiles, sharing rules, and permission sets. Always retrieve before modifying.

| Rule | Details |
|------|---------|
| **Deploy order** | Network + CustomSite must deploy before ExperienceBundle. Full source deploys handle ordering automatically. |
| **Retrieve by name** | Use `--metadata ExperienceBundle:SiteName` — source tracking is unreliable for experience bundles. |
| **Publish after deploy** | Run `sf community publish --name "Site Name"` after deploying to make changes live. |
| **Guest user profile** | Auto-named `{Site Label} Profile`. Add object permissions, field-level security, and Apex class access for guest-facing controllers. |
| **Guest user limits** | Guest license only allows Create + Read — no Edit, Delete, View All. Field perms must be `editable: false`. Use `without sharing` Apex for DML. |
| **Sharing for guests** | Guest users belong to `{SiteApiName}_Site_Guest_User` public group. Create criteria-based sharing rules to expose records. |
| **LWR guest access** | Site-level `authenticationType` can't be changed via deploy. Set `"pageAccess": "Public"` on individual route `content.json` files instead. |
| **ExperienceBundle noise** | Add `**/experiences/**/config/**` to `.forceignore` to avoid constant diffs from auto-generated files. |
| **LWR vs Aura metadata** | LWR (Build Your Own) sites use `DigitalExperienceBundle` and `digitalExperiences/` directory. Aura sites use `ExperienceBundle` and `experiences/`. |

## Metadata Types Overview

| Metadata Type | What It Controls | Deploy Order |
|---------------|-----------------|--------------|
| **Network** | Site configuration, member profiles, self-registration, guest user profile | 1st — must exist before ExperienceBundle |
| **CustomSite** | URL path, site type, site admin | 1st (alongside Network) |
| **ExperienceBundle** | Pages, routes, views, theme, branding, components | 2nd — requires Network |
| **NavigationMenu** | Site navigation menus | 2nd — references pages in ExperienceBundle |
| **Profile** (Guest User) | Object/field permissions for unauthenticated users | Any time, but must align with Network config |

For full implementation details, read the relevant file in `references/` for this skill: `deploy-commands.md` (retrieve/deploy commands, directory structure, network metadata, errors), `guest-user-config.md` (profile XML, sharing rules, guest Apex controllers), `lwc-and-navigation.md`, or `lwr-sites.md`.
