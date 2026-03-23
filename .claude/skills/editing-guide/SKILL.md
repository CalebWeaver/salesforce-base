---
name: editing-guide
description: How to change standards, add new profiles, update skills and agents, and update templates in this baseline repo.
---

## Changing Shared Standards

If a standard applies to both lightweight and enterprise (but not POC), edit the relevant skill in `profiles/base/skills/`. Changes automatically flow into both composed profiles.

## Changing Profile-Specific Standards

Edit the relevant skill in `profiles/{profile}/skills/`. For POC, edit skills in `profiles/poc/skills/` — POC is standalone and doesn't inherit from base.

## Adding a New Skill

1. Create `profiles/{base|profile}/skills/{skill-name}/SKILL.md`
2. Add a good `description` in the frontmatter — Claude uses it to decide when to auto-invoke
3. Keep `SKILL.md` concise (under ~500 lines) — core rules, decision flows, short examples. Put long code examples in a `references/` subdirectory and point to them from `SKILL.md`. See `/skill-builder` for the full structure.
4. Update the relevant agent `.md` files to preload the skill if it should be part of a developer's context
5. Update `manifest.json` — skills are copied by directory, so no manifest change needed if the dir is already under `skills.base` or `skills.profile`

## Adding or Updating an Agent

Agent files live in `profiles/{profile}/agents/{agent-name}.md`.

YAML frontmatter fields:
- `name` — used by Claude to identify the agent
- `description` — when Claude should delegate to this agent (be specific)
- `tools` — allowlist; `disallowedTools` for denylist
- `skills` — list of skill names to preload (full content injected at startup)

Keep agent body content to 1-3 lines — the preloaded skills carry the detail.

## Adding a New Profile

1. Create `profiles/{name}/manifest.json`
   - Set `"standalone": true` if it shouldn't compose from base
   - Add `claude.template`, `skills.profile`, `agents.profile` keys
2. Create `profiles/{name}/claude.md` — thin CLAUDE.md template (3-5 lines)
3. Create skills in `profiles/{name}/skills/`
4. Create agents in `profiles/{name}/agents/`
5. Add the profile option to `init-project.sh` in both the interactive menu and `--profile` validation
7. Update the README

## Adding a New Template Class

1. Create both `{ClassName}.cls` and `{ClassName}.cls-meta.xml` in the appropriate `templates/salesforce/classes/` subdirectory
2. Add the paths to the relevant `manifest.json` under `templates.copy`

## Updating the README

The README is currently out of date — it only describes lightweight and enterprise, not POC. It also doesn't describe the skills/agents structure. Update it when making structural changes.
