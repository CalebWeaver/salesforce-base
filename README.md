# Salesforce Development Baseline

A baseline configuration for Salesforce development projects with AI agent guidance, reusable templates, and reference repositories.

## Quick Start

1. Clone this repo as a starting point for new Salesforce projects
2. Run `./scripts/sync-references.sh` to clone reference repositories
3. Copy templates and references into your project as needed

## Structure

```
├── .cursor/rules/
│   └── salesforce-development.mdc   # AI agent guidance for Salesforce dev
├── templates/
│   └── salesforce/classes/
│       ├── TriggerHandler.cls       # Base trigger handler pattern
│       ├── SecurityEnforcer.cls     # CRUD/FLS enforcement utility
│       └── SecurityEnforcerTest.cls # Test coverage
├── references/
│   ├── repos.json                   # Reference repo configuration
│   └── README.md                    # Usage instructions
└── scripts/
    └── sync-references.sh           # Clone/update reference repos
```

## Components

### Cursor Rules (`.cursor/rules/`)

AI agent guidance covering:
- Governor limits and bulkification
- Trigger handler patterns
- SOQL best practices
- CRUD/FLS security enforcement
- Test class standards
- Custom object and permission set creation
- Logging with NebulaLogger

### Templates (`templates/`)

Ready-to-copy Apex classes:

| Template | Purpose |
|----------|---------|
| `TriggerHandler.cls` | Base class for trigger handlers with enable/disable support |
| `SecurityEnforcer.cls` | Utility for CRUD/FLS checks and `stripInaccessible` |
| `SecurityEnforcerTest.cls` | Test coverage for SecurityEnforcer |

### Reference Repositories (`references/`)

Configured in `repos.json`:

| Repo | Type | Purpose |
|------|------|---------|
| [NebulaLogger](https://github.com/jongpie/NebulaLogger) | Package | Enterprise logging framework |
| [UniversalMock](https://github.com/surajp/universalmock) | Copy | Apex test mocking utility |

**Sync references:**
```bash
./scripts/sync-references.sh
```

**Install NebulaLogger (unlocked package):**
```bash
sf package install --wait 20 --security-type AdminsOnly --package 04tg70000001IMHAA2
```

**Copy UniversalMock into your project:**
```bash
cp references/UniversalMock/force-app/main/default/classes/UniversalMocker.* \
   your-project/force-app/main/default/classes/
```

## Usage

### Starting a New Project

1. Create your SFDX project: `sf project generate -n my-project`
2. Copy the `.cursor/rules/` folder into your project
3. Copy templates as needed from `templates/`
4. Install NebulaLogger package
5. Copy UniversalMock for testing

### Adding to Existing Projects

Cherry-pick what you need:
- Copy `.cursor/rules/salesforce-development.mdc` for AI guidance
- Copy individual templates from `templates/salesforce/classes/`
- Reference `repos.json` for useful packages/utilities

## License

MIT
