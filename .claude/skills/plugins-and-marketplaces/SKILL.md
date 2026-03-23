---
name: plugins-and-marketplaces
description: How to discover, install, and manage Claude Code plugins and marketplaces — including public, team-shared, and private marketplaces, installation scopes, and enterprise restrictions.
---

## What Plugins Are

Plugins extend Claude Code with **skills**, **agents**, **hooks**, **MCP servers**, and **LSP servers**. A **marketplace** is a catalog of plugins — it provides discovery and versioning but installs nothing by itself.

Plugin structure:
```
my-plugin/
├── .claude-plugin/
│   └── plugin.json       # plugin metadata
├── skills/               # skill SKILL.md files
├── agents/               # agent .md files
├── commands/             # slash command .md files
└── hooks/                # hooks.json
```

## Installation Scopes

| Scope | Who it applies to | Stored in |
|-------|------------------|-----------|
| **User** (default) | You, across all projects | `~/.claude/settings.json` |
| **Project** | All collaborators on this repo | `.claude/settings.json` (committed) |
| **Local** | You, in this repo only | `.claude/settings.local.json` (not committed) |
| **Managed** | Set by admins — cannot be changed by users | `managed-settings.json` |

## Essential Commands

```shell
# Browse and manage everything interactively
/plugin

# Reload after changes without restarting
/reload-plugins

# Validate a marketplace or plugin
/plugin validate .
```

### Marketplace commands
```shell
/plugin marketplace add owner/repo          # GitHub
/plugin marketplace add https://gitlab.com/org/repo.git
/plugin marketplace add ./local-path
/plugin marketplace list
/plugin marketplace update marketplace-name
/plugin marketplace remove marketplace-name
```

### Plugin commands
```shell
/plugin install plugin-name@marketplace-name
/plugin install formatter@your-org --scope project   # CLI flag for scope
/plugin disable plugin-name@marketplace-name
/plugin enable plugin-name@marketplace-name
/plugin uninstall plugin-name@marketplace-name
```

## Official Anthropic Marketplace

The `claude-plugins-official` marketplace is available automatically. No setup needed.

```shell
/plugin install github@claude-plugins-official
```

Notable official plugins:
- **LSP plugins**: `pyright-lsp`, `typescript-lsp`, `gopls-lsp`, etc. — give Claude type-error feedback after every edit
- **Integrations**: `github`, `gitlab`, `slack`, `figma`, `linear`, `notion`
- **Workflows**: `commit-commands`, `pr-review-toolkit`

## Creating a Marketplace

Minimum structure:
```
my-marketplace/
└── .claude-plugin/
    └── marketplace.json
```

Minimum `marketplace.json`:
```json
{
  "name": "my-tools",
  "owner": { "name": "Your Name" },
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./plugins/my-plugin",
      "description": "What this plugin does"
    }
  ]
}
```

For full schema details, read `references/marketplace-schema.md` in this skill.

### Plugin sources

| Source type | Example |
|-------------|---------|
| Relative path | `"./plugins/my-plugin"` |
| GitHub repo | `{ "source": "github", "repo": "owner/repo" }` |
| Git URL | `{ "source": "url", "url": "https://gitlab.com/..." }` |
| Monorepo subdir | `{ "source": "git-subdir", "url": "...", "path": "tools/plugin" }` |
| npm package | `{ "source": "npm", "package": "@org/plugin" }` |

Pin to a specific version by adding `"ref": "v2.0.0"` and/or `"sha": "a1b2c3..."` to any git-based source.

**Note**: relative paths only work when the marketplace is added via Git, not via a direct URL to `marketplace.json`.

## Hosting Options

| Option | Add command | Best for |
|--------|-------------|----------|
| GitHub (recommended) | `/plugin marketplace add owner/repo` | Teams, version control |
| GitLab / other git | `/plugin marketplace add https://...` | Self-hosted |
| Private git | Same, auth via `GITHUB_TOKEN` / `GITLAB_TOKEN` | Private team repos |
| Local path | `/plugin marketplace add ./my-marketplace` | Development / testing |
| Remote URL | `/plugin marketplace add https://example.com/marketplace.json` | Simple hosting |

## Three Marketplace Scenarios

### 1. Personal / Public
Host on GitHub, add manually. No config needed.

### 2. Team-shared
Commit marketplace config to `.claude/settings.json` so teammates get prompted to install when they trust the project:

```json
{
  "extraKnownMarketplaces": {
    "team-tools": {
      "source": { "source": "github", "repo": "your-org/claude-plugins" }
    }
  },
  "enabledPlugins": {
    "code-formatter@team-tools": true
  }
}
```

### 3. Enterprise (managed / restricted)
Use `managed-settings.json` to push plugins to everyone and lock down which marketplaces are allowed. For full enterprise configuration, read `references/enterprise-setup.md` in this skill.

## Auto-Updates

- Official Anthropic marketplaces: auto-update **enabled** by default
- Third-party / local marketplaces: auto-update **disabled** by default
- Toggle per-marketplace in `/plugin` → Marketplaces tab
- Override env vars:
  ```bash
  export DISABLE_AUTOUPDATER=true          # disable Claude Code + plugin updates
  export FORCE_AUTOUPDATE_PLUGINS=true     # re-enable plugin updates only
  ```

## Common Troubleshooting

| Symptom | Fix |
|---------|-----|
| `/plugin` not recognized | Requires Claude Code v1.0.33+. Run `brew upgrade claude-code` or `npm update -g @anthropic-ai/claude-code` |
| Plugin skills not appearing | `/reload-plugins`, or clear cache: `rm -rf ~/.claude/plugins/cache` then reinstall |
| Private repo auth fails | `gh auth login` for manual; set `GITHUB_TOKEN` for auto-updates |
| Relative paths not found | Only works with git-based marketplace adds, not URL adds |
| Git clone timeout | `export CLAUDE_CODE_PLUGIN_GIT_TIMEOUT_MS=300000` |
