# Aimpoint Salesforce Baseline

This is a **project initializer**, not a Salesforce project. It generates Salesforce projects with pre-configured AI agent guidance, templates, and reference repos.

## What This Repo Does

`scripts/init-project.sh` creates new Salesforce projects by assembling CLAUDE.md, Cursor rules, Apex templates, and reference configurations based on a chosen profile. The output is a ready-to-develop SFDX project in a separate directory.

## Project Structure

```
profiles/           AI rules and manifests, organized by profile
  base/             Shared rules composed into lightweight + enterprise
  lightweight/      Simple trigger handler architecture
  enterprise/       FFLib Domain-Service-Selector-UoW architecture
  poc/              Standalone POC/demo rules (not composed from base)
templates/          Apex classes and docs copied into target projects
  docs/             Project documentation templates (architecture.md, modules/)
  salesforce/classes/
    enterprise/     Enterprise-only templates (Application.cls, etc.)
    testsupport/    Test data framework (builders, fixtures, TestDataGraph)
references/         Reference repos config + implementation pattern files
  patterns/         Apex code examples organized by profile
  repos.json        External repo definitions (NebulaLogger, FFLib, etc.)
scripts/            Shell scripts for init and reference syncing
```

## Profile System

There are three profiles: `poc`, `lightweight`, and `enterprise`.

**Composed profiles** (lightweight, enterprise): The init script concatenates `profiles/base/rules-base.md` + `profiles/{profile}/rules-overlay.md` to produce the target project's CLAUDE.md. Same for Cursor rules. This means shared standards live in `base/` and profile-specific patterns live in the overlay.

**Standalone profile** (poc): The init script copies `profiles/poc/rules-standalone.md` directly — no composition with base. POC is too different from development profiles to share a base. The manifest has `"standalone": true` to signal this.

### Manifests

Each profile has a `manifest.json` that controls what gets copied to target projects: which template files, which reference repos (required vs optional), and which rules files. The init script reads the manifest to drive all assembly decisions.

### How to Tell If a Profile Is Standalone

Check `manifest.json` for the `"standalone": true` key. If present, the profile uses `rules.standalone` and `cursorRules.standalone` paths instead of `rules.base`/`rules.overlay`.

## Rules Files

Rules files are the AI agent instructions that get assembled into the target project's `.claude/CLAUDE.md` and `.cursor/rules/salesforce-development.mdc`.

**Important conventions:**

- Keep rules files lean — describe patterns and point to `references/patterns/` for code examples rather than embedding Apex code blocks inline. This way the LLM only loads implementation details when it goes to implement a specific pattern.
- Bash deployment commands are OK to keep inline since they're short and frequently referenced.
- Cursor rules (`.mdc`) are more condensed than CLAUDE.md rules — small inline code snippets (under ~10 lines) are acceptable because cursor rules are `alwaysApply: true` and always loaded.
- Tables and decision flows are fine in rules files — they're compact and convey a lot of information.

## Reference Pattern Files

`references/patterns/{base|lightweight|enterprise|poc}/` contains Apex code examples that the rules files point to. These exist so AI agents only pull implementation details into context when needed.

When adding a new pattern file:
1. Create it in the appropriate profile subdirectory under `references/patterns/`
2. Add a pointer in the corresponding rules file: `See references/patterns/{profile}/{filename}.md for examples.`
3. If the pattern applies to composed profiles, put it in `references/patterns/base/` and reference it from `profiles/base/rules-base.md`

Shared reference docs (`references/async-patterns.md`, `references/lwc-patterns.md`) are top-level in `references/` and available to all composed profiles.

## Templates

Apex classes in `templates/salesforce/classes/` are copied into target projects. Each `.cls` file must have a corresponding `-meta.xml` file.

The manifest's `templates.copy` array lists exactly which files/directories to copy for each profile. When adding a new template class:
1. Create both the `.cls` and `.cls-meta.xml` files
2. Add the paths to the appropriate profile manifest(s)

## Project Documentation Templates

`templates/docs/` contains starter documentation that gets scaffolded into every target project's `docs/` directory:

- `templates/docs/architecture.md` — Template with commented sections for project overview, org topology, data model, integrations, and architectural decisions
- `templates/docs/modules/README.md` — Instructions and an example for per-module documentation files
- `templates/docs/user-stories/README.md` — Instructions and an example for per-story files with acceptance criteria, technical notes, and dependencies

The init script copies these into `docs/` in the target project. The rules files (both base and POC standalone) include a "Project Documentation" section pointing agents to `docs/` and reminders to keep docs current.

The docs are designed to be the source of truth for project-specific context that AI agents need — architecture, module boundaries, integration details — as opposed to the CLAUDE.md which covers *how* to write Salesforce code (patterns, conventions, standards).

## Init Script (`scripts/init-project.sh`)

The init script supports both interactive and non-interactive (CLI flags) modes. Key functions:

- `assemble_claude_md()` — checks manifest for `standalone` key, then either copies standalone file or concatenates base + overlay
- `assemble_cursor_rules()` — same logic for Cursor `.mdc` files, strips YAML frontmatter from overlays before appending
- `copy_templates()` — reads `templates.copy` from manifest
- `setup_references()` — filters `repos.json` by profile, copies shared reference docs and profile-appropriate pattern files
- `scaffold_docs()` — copies `templates/docs/` into the target project's `docs/` directory (skips existing files)
- `scaffold_sfdx_project()` — runs `sf project generate` if Salesforce CLI is available

When modifying the init script, test all three profiles: `--profile poc`, `--profile lightweight`, `--profile enterprise`.

## Editing Guidelines

### Changing Shared Standards

If a standard applies to both lightweight and enterprise (but not POC), edit `profiles/base/rules-base.md` and `profiles/base/cursor-base.mdc`. Changes automatically flow into both composed profiles.

### Changing Profile-Specific Standards

Edit the overlay file for that profile (`profiles/{profile}/rules-overlay.md`). For POC, edit `profiles/poc/rules-standalone.md` — remember it's self-contained and doesn't inherit from base.

### Adding a New Profile

1. Create `profiles/{name}/manifest.json` — set `"standalone": true` if it shouldn't compose from base
2. Create rules and cursor files (overlay or standalone depending on manifest)
3. Create pattern files in `references/patterns/{name}/` if the profile needs code examples
4. Add the profile option to `init-project.sh` in both the interactive menu and `--profile` validation
5. Update the README

### Updating the README

The README is currently out of date — it only describes lightweight and enterprise, not POC. It also doesn't mention the `references/patterns/` directory or the standalone profile concept. Update it when making structural changes.

## Gotchas

- `references/.gitignore` ignores `*/` to exclude cloned repos, with explicit exceptions for `patterns/` and `patterns/**`. If you add a new tracked subdirectory under `references/`, add a negation rule.
- The `.claude/CLAUDE.md` and `.cursor/rules/salesforce-development.mdc` at the repo root are for *this* baseline project, not templates. The template rules live under `profiles/`.
- POC standalone files must be fully self-contained — they don't get any content from base.
- Cursor overlay frontmatter (`---` YAML block) is stripped by `sed` during composition. Don't put content before the closing `---` that you want included.
- The init script copies itself into target projects (`scripts/init-project.sh`) so users can re-run it.

## Dependencies

The init script requires `jq` for JSON parsing and optionally `sf` (Salesforce CLI) for SFDX project scaffolding. Both are checked at startup with user-friendly error messages.
