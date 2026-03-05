# Salesforce Development Baseline

A baseline configuration for Salesforce development projects with AI agent guidance (Claude + Cursor), reusable templates, and reference repositories. Supports two project profiles to match your project's complexity.

## Quick Start

```bash
# Interactive — prompts for project name, profile, and target directory
./scripts/init-project.sh

# Non-interactive
./scripts/init-project.sh --profile lightweight --name client-portal
./scripts/init-project.sh --profile enterprise --name crm-overhaul --target ~/projects/crm-overhaul
```

The init script scaffolds an SFDX project (`sf project generate`), then assembles the right CLAUDE.md, Cursor rules, templates, and reference configs based on your chosen profile. Requires Salesforce CLI (`sf`) for project scaffolding — if not installed, it skips that step and tells you the command to run manually.

## Profiles

### Lightweight
Best for small projects, POCs, and quick builds.

- Simple `TriggerHandler` base class (logic directly in handlers)
- `SecurityEnforcer` for CRUD/FLS
- Test data framework (builders, fixtures, TestDataGraph)
- No FFLib, no service/domain/selector layers
- Flat architecture — extract utility classes only when handlers grow large

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
│   ├── base/                          # Shared rules (both profiles)
│   │   ├── rules-base.md             # Base CLAUDE.md content
│   │   └── cursor-base.mdc           # Base Cursor rules
│   ├── lightweight/
│   │   ├── manifest.json             # Template/reference config
│   │   ├── rules-overlay.md          # Lightweight-specific CLAUDE.md
│   │   └── cursor-overlay.mdc        # Lightweight-specific Cursor rules
│   └── enterprise/
│       ├── manifest.json             # Template/reference config
│       ├── rules-overlay.md          # FFLib-specific CLAUDE.md
│       └── cursor-overlay.mdc        # FFLib-specific Cursor rules
├── templates/
│   └── salesforce/classes/
│       ├── TriggerHandler.cls         # Base trigger handler (lightweight)
│       ├── SecurityEnforcer.cls       # CRUD/FLS enforcement utility
│       ├── MockSObjectBuilder.cls     # Mock SObjects without DML
│       ├── DataAccessor.cls           # Abstract query layer
│       ├── SecurityEnforcerTest.cls   # Test patterns
│       ├── testsupport/               # Test data framework
│       │   ├── TestIds.cls
│       │   ├── BaseFluentBuilder.cls
│       │   ├── TestDataGraph.cls
│       │   ├── builders/
│       │   └── fixtures/
│       └── enterprise/                # Enterprise-only templates
│           └── Application.cls        # FFLib Application factory
├── references/
│   ├── repos.json                     # Reference repos with profile tags
│   └── README.md
└── scripts/
    ├── init-project.sh                # Interactive project initializer
    └── sync-references.sh             # Clone/update reference repos
```

## How Profiles Work

The init script assembles your project from composable pieces:

1. **CLAUDE.md** = `profiles/base/rules-base.md` + `profiles/{profile}/rules-overlay.md`
2. **Cursor rules** = `profiles/base/cursor-base.mdc` + `profiles/{profile}/cursor-overlay.mdc`
3. **Templates** = files listed in `profiles/{profile}/manifest.json`
4. **References** = repos tagged for the profile in `repos.json`, filtered by your add-on choices

The assembled files are written to your target directory. The original composable pieces stay in the baseline repo for future use.

## Reference Repositories

Configured in `repos.json` with profile tags:

| Repo | Profiles | Type | Purpose |
|------|----------|------|---------|
| [NebulaLogger](https://github.com/jongpie/NebulaLogger) | Enterprise | Package | Enterprise logging framework |
| [UniversalMock](https://github.com/surajp/universalmock) | Both | Copy | Apex test mocking utility |
| [fflib-apex-common](https://github.com/apex-enterprise-patterns/fflib-apex-common) | Enterprise | Package | Domain, Selector, Service, UnitOfWork |
| [fflib-apex-mocks](https://github.com/apex-enterprise-patterns/fflib-apex-mocks) | Enterprise | Package | ApexMocks test framework |

## Templates

### Shared (Both Profiles)

| Template | Purpose |
|----------|---------|
| `TriggerHandler.cls` | Base class for trigger handlers with enable/disable support |
| `SecurityEnforcer.cls` | Utility for CRUD/FLS checks and `stripInaccessible` |
| `MockSObjectBuilder.cls` | Build mock SObjects with read-only fields and relationships |
| `DataAccessor.cls` | Base class for abstracting SOQL queries for testability |
| `testsupport/` | Test data framework (builders, fixtures, TestDataGraph) |

### Enterprise Only

| Template | Purpose |
|----------|---------|
| `Application.cls` | FFLib Application factory with UoW, Selector, Domain, Service registration |

## Adding a New Profile

1. Create `profiles/{name}/manifest.json` with template and reference config
2. Create `profiles/{name}/rules-overlay.md` with architecture-specific CLAUDE.md content
3. Create `profiles/{name}/cursor-overlay.mdc` with architecture-specific Cursor rules
4. Add the profile choice to `scripts/init-project.sh`

## License

MIT
