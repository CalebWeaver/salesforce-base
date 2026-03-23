# Salesforce Development Baseline

A baseline for Salesforce development projects with Claude Code AI guidance, reusable templates, and reference repositories. Supports three profiles to match your project's complexity.

## Quick Start

```bash
# Interactive — prompts for project name, profile, and target directory
./scripts/init-project.sh

# Non-interactive
./scripts/init-project.sh --profile poc --name field-routing-demo
./scripts/init-project.sh --profile lightweight --name client-portal
./scripts/init-project.sh --profile enterprise --name crm-overhaul --target ~/projects/crm-overhaul
```

The init script scaffolds an SFDX project (`sf project generate`), assembles CLAUDE.md with the full development standards, copies skills and agents, and drops in the right templates and reference configs for the chosen profile. Requires Salesforce CLI (`sf`) for project scaffolding — if not installed, it skips that step and tells you the command to run manually.

## Profiles

### POC / Demo
Best for proofs of concept, demos, and throwaway explorations.

- `TriggerHandler` only — no SecurityEnforcer, no test data framework
- No test coverage enforced
- Includes a promotion checklist for hardening into a real project

### Lightweight
Best for small-to-medium projects that need proper structure without complexity.

- Simple `TriggerHandler` base class (logic directly in handlers)
- `SecurityEnforcer` for CRUD/FLS
- Test data framework (builders, fixtures, TestDataGraph)
- No FFLib, no service/domain/selector layers

### Enterprise (FFLib)
Best for large, long-lived projects with multiple developers.

- Full FFLib Domain-Service-Selector-UnitOfWork architecture
- `Application.cls` factory for dependency injection
- `fflib_ApexMocks` for isolated layer testing
- All SOQL in Selectors, all DML through Unit of Work
- Plus everything from lightweight (SecurityEnforcer, test data framework)

## Structure

```
├── profiles/
│   ├── base/                          # Shared rules + skills (lightweight + enterprise)
│   │   ├── rules-base.md             # Shared Salesforce standards
│   │   └── skills/                   # Skills copied into all composed-profile projects
│   ├── lightweight/
│   │   ├── manifest.json             # Template/reference config
│   │   ├── rules-overlay.md          # Lightweight-specific standards
│   │   ├── claude.md                 # Behavior instruction preamble
│   │   ├── skills/                   # trigger-handler skill
│   │   └── agents/                   # developer, reviewer, experience-cloud-developer
│   ├── enterprise/
│   │   ├── manifest.json
│   │   ├── rules-overlay.md          # FFLib-specific standards
│   │   ├── claude.md
│   │   ├── skills/                   # fflib-architecture, fflib-testing, nebula-logger
│   │   └── agents/
│   └── poc/
│       ├── manifest.json
│       ├── rules-standalone.md       # Self-contained POC standards (no base composition)
│       ├── claude.md
│       ├── skills/                   # poc-approach, poc-promotion
│       └── agents/                   # developer, promoter
├── templates/
│   └── salesforce/classes/
│       ├── TriggerHandler.cls
│       ├── SecurityEnforcer.cls
│       ├── MockSObjectBuilder.cls
│       ├── DataAccessor.cls
│       ├── SecurityEnforcerTest.cls
│       ├── testsupport/               # Test data framework
│       └── enterprise/                # Enterprise-only templates
│           └── Application.cls
├── references/
│   ├── repos.json                     # Reference repos with profile tags
│   └── README.md
└── scripts/
    ├── init-project.sh                # Interactive project initializer
    └── sync-references.sh             # Clone/update reference repos
```

## How Profiles Work

The init script assembles each project from composable pieces:

**Composed profiles** (lightweight, enterprise):
- `.claude/CLAUDE.md` = `profiles/{profile}/claude.md` + `profiles/base/rules-base.md` + `profiles/{profile}/rules-overlay.md`
- `.claude/skills/` = base skills + profile skills
- `.claude/agents/` = profile agents

**Standalone profile** (poc):
- `.claude/CLAUDE.md` = `profiles/poc/claude.md` + `profiles/poc/rules-standalone.md`
- `.claude/skills/` = poc skills only
- `.claude/agents/` = poc agents only

Templates and references are always driven by the profile's `manifest.json`.

## Reference Repositories

Configured in `repos.json` with profile tags:

| Repo | Profiles | Type | Purpose |
|------|----------|------|---------|
| [NebulaLogger](https://github.com/jongpie/NebulaLogger) | Enterprise | Package | Enterprise logging framework |
| [UniversalMock](https://github.com/surajp/universalmock) | Lightweight, POC | Copy | Apex test mocking utility |
| [fflib-apex-common](https://github.com/apex-enterprise-patterns/fflib-apex-common) | Enterprise | Package | Domain, Selector, Service, UnitOfWork |
| [fflib-apex-mocks](https://github.com/apex-enterprise-patterns/fflib-apex-mocks) | Enterprise | Package | ApexMocks test framework |

## Adding a New Profile

1. Create `profiles/{name}/manifest.json` — set `"standalone": true` if it shouldn't compose from base
2. Create `rules-overlay.md` (or `rules-standalone.md` for standalone) and `claude.md`
3. Create `skills/` and `agents/` directories with profile-specific content
4. Add the profile choice to `scripts/init-project.sh`

## License

MIT
