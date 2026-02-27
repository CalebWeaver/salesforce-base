# Reference Repositories

This folder contains cloned git repositories used as reference structures for new projects.

## Setup

Add repositories to `repos.json`, then run:

```bash
./scripts/sync-references.sh
```

## Usage

When starting a new Salesforce project:
1. Check `repos.json` for available references
2. For **package-based** repos: use the `packageInstall` commands to install
3. For **copy-based** repos: copy from `copyPaths` into the target project

## Repo Types

### Package-Based (installMethod: "package")
Install via Salesforce CLI rather than copying files. Reference the cloned repo for patterns and examples.

**Example**: NebulaLogger - install the unlocked package, reference the source for logging patterns.

### Copy-Based (installMethod: "copy" or not specified)
Copy files/folders directly into new projects from `copyPaths`.

## Repo Configuration

Repos in `repos.json` support:
- `url`: Git clone URL
- `branch`: Branch to checkout (default: main)
- `description`: What this repo is for
- `installMethod`: "package" or "copy" (default: copy)
- `packageInstall`: Install commands for package-based repos
- `copyPaths`: Paths to copy for copy-based repos
- `referencePaths`: Paths to reference for patterns/examples
