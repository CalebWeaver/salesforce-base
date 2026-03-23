---
name: init-script
description: How scripts/init-project.sh works — key functions, composition logic, testing all three profiles, and dependencies.
---

## What the Script Does

`scripts/init-project.sh` supports both interactive and non-interactive (CLI flags) modes. It:

1. `scaffold_sfdx_project()` — runs `sf project generate` if Salesforce CLI is available
2. `assemble_claude_md()` — prepends `profiles/{profile}/claude.md` (behavior instruction), then appends rules files (base + overlay, or standalone) into `.claude/CLAUDE.md`
3. `copy_skills()` — copies `skills.base` dir (composed profiles) + `skills.profile` dir → `.claude/skills/`
4. `copy_agents()` — copies `agents.profile` dir → `.claude/agents/`
5. `copy_templates()` — reads `templates.copy` from manifest and copies Apex classes
6. `setup_references()` — filters `repos.json` by profile and copies supporting files (README, .gitignore)
7. `copy_scripts()` — copies `sync-references.sh` and `init-project.sh` to target project
8. `scaffold_docs()` — copies `templates/docs/` into `docs/` (skips existing files)
9. `copy_gitignore()` — copies gitignore template if not present
10. `write_profile_marker()` — writes `.sf-profile` with project name and profile

## CLI Usage

```bash
# Interactive
./scripts/init-project.sh

# Non-interactive
./scripts/init-project.sh --profile <poc|lightweight|enterprise> --name <project-name> [--target <dir>]
```

## Testing Changes

When modifying the init script, test all three profiles:

```bash
./scripts/init-project.sh --profile poc --name test-poc --target /tmp/test-poc
./scripts/init-project.sh --profile lightweight --name test-lw --target /tmp/test-lw
./scripts/init-project.sh --profile enterprise --name test-ent --target /tmp/test-ent
```

Check that:
- `.claude/CLAUDE.md` contains the behavior preamble followed by the full standards
- `.claude/skills/` contains the expected skill directories
- `.claude/agents/` contains the expected agent files
- `references/` and `templates/` are populated correctly

## Composition Logic

**Composed profiles** (lightweight, enterprise):
- CLAUDE.md: `profiles/{profile}/claude.md` (preamble) + `profiles/base/rules-base.md` + `profiles/{profile}/rules-overlay.md`
- Skills: copy `profiles/base/skills/*` then `profiles/{profile}/skills/*` (profile overwrites base if same name)
- Agents: copy `profiles/{profile}/agents/*`

**Standalone profile** (poc):
- CLAUDE.md: `profiles/poc/claude.md` (preamble) + `profiles/poc/rules-standalone.md`
- Skills: copy `profiles/poc/skills/*` only (no base)
- Agents: copy `profiles/poc/agents/*` only

## Dependencies

- `jq` — required for JSON parsing. Checked at startup with friendly error.
- `sf` (Salesforce CLI) — optional. SFDX scaffolding skipped if not available.
