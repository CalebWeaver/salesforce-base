# Enterprise Plugin Marketplace Setup

## Architecture overview

Three settings files interact:

| File | Scope | Who controls it |
|------|-------|-----------------|
| `~/.claude/settings.json` | User (all projects) | Individual user |
| `.claude/settings.json` | Project (committed) | Repo maintainer |
| `managed-settings.json` | Managed (org-wide) | Administrator |

Managed settings cannot be overridden by users or project settings.

## Push marketplaces to your team (project-level)

Commit to `.claude/settings.json` in your repo. When teammates trust the folder, Claude Code prompts them to install:

```json
{
  "extraKnownMarketplaces": {
    "team-tools": {
      "source": {
        "source": "github",
        "repo": "your-org/claude-plugins"
      }
    }
  },
  "enabledPlugins": {
    "code-formatter@team-tools": true,
    "deployment-tools@team-tools": true
  }
}
```

## Org-wide managed marketplaces

In `managed-settings.json`, combine `extraKnownMarketplaces` (registers the marketplace) with `strictKnownMarketplaces` (restricts what users can add):

```json
{
  "extraKnownMarketplaces": {
    "approved-tools": {
      "source": {
        "source": "github",
        "repo": "acme-corp/approved-plugins"
      }
    }
  },
  "strictKnownMarketplaces": [
    {
      "source": "github",
      "repo": "acme-corp/approved-plugins"
    }
  ]
}
```

`extraKnownMarketplaces` alone registers — it doesn't restrict. You need `strictKnownMarketplaces` to lock things down.

## strictKnownMarketplaces configurations

### Complete lockdown (no user additions)
```json
{ "strictKnownMarketplaces": [] }
```

### Allowlist specific repos
```json
{
  "strictKnownMarketplaces": [
    { "source": "github", "repo": "acme-corp/approved-plugins" },
    { "source": "github", "repo": "acme-corp/security-tools", "ref": "v2.0" }
  ]
}
```

### Allow all internal git server
```json
{
  "strictKnownMarketplaces": [
    { "source": "hostPattern", "hostPattern": "^github\\.internal\\.example\\.com$" }
  ]
}
```

### Allow filesystem path prefix
```json
{
  "strictKnownMarketplaces": [
    { "source": "pathPattern", "pathPattern": "^/opt/approved/" }
  ]
}
```
Use `".*"` as `pathPattern` to allow any local path while still controlling network sources.

### Matching rules
- `github`: `repo` required; `ref` or `path` must also match if specified in allowlist
- `url`: full URL must match exactly
- `hostPattern`: regex matched against the marketplace host
- `pathPattern`: regex matched against the filesystem path
- Restrictions apply before any network requests

## Release channels (stable vs. latest)

Point two separate marketplaces at different `ref`s of the same repo, then assign via managed settings:

**stable-marketplace.json**:
```json
{
  "name": "stable-tools",
  "plugins": [{
    "name": "code-formatter",
    "source": { "source": "github", "repo": "acme/formatter", "ref": "stable" }
  }]
}
```

**latest-marketplace.json**:
```json
{
  "name": "latest-tools",
  "plugins": [{
    "name": "code-formatter",
    "source": { "source": "github", "repo": "acme/formatter", "ref": "latest" }
  }]
}
```

Assign to user groups via separate managed settings files. The plugin's `plugin.json` must have a different `version` at each ref — otherwise Claude Code skips the update.

## Private repository authentication

For **manual** installs and updates: uses existing git credential helpers. If `git clone` works in terminal, it works in Claude Code.

For **auto-updates** (background, at startup): credential helpers can't prompt interactively. Set tokens in shell config:

```bash
export GITHUB_TOKEN=ghp_xxxx      # GitHub
export GITLAB_TOKEN=glpat-xxxx    # GitLab
export BITBUCKET_TOKEN=xxxx       # Bitbucket
```

For CI/CD: set as secret environment variables. GitHub Actions provides `GITHUB_TOKEN` automatically for same-org repos.

## Container / CI pre-population

Pre-populate a seed directory at image build time so Claude Code starts with plugins already installed:

```bash
# During image build: install plugins, then copy the cache
cp -r ~/.claude/plugins /opt/claude-plugin-seed

# At runtime, point Claude Code at the seed
export CLAUDE_CODE_PLUGIN_SEED_DIR=/opt/claude-plugin-seed
```

Seed directory structure:
```
$CLAUDE_CODE_PLUGIN_SEED_DIR/
  known_marketplaces.json
  marketplaces/<name>/...
  cache/<marketplace>/<plugin>/<version>/...
```

Seed behavior:
- Read-only — never written to; auto-updates disabled for seed marketplaces
- Seed entries overwrite matching entries in user config on each startup
- To opt out of a seed plugin, use `/plugin disable` (don't remove the marketplace)
- Composes with `extraKnownMarketplaces` — seed copy takes precedence over cloning
- Layer multiple seeds: `CLAUDE_CODE_PLUGIN_SEED_DIR=/path1:/path2` (`:` on Unix)
