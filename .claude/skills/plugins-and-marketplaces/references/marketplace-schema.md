# Marketplace Schema Reference

## marketplace.json — Required fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Kebab-case identifier. Users see this in `/plugin install my-plugin@<name>`. Reserved names (anthropic-*, claude-plugins-official, etc.) are blocked. |
| `owner.name` | string | Maintainer name |
| `plugins` | array | List of plugin entries |

## marketplace.json — Optional metadata

| Field | Description |
|-------|-------------|
| `owner.email` | Contact email |
| `metadata.description` | Marketplace description |
| `metadata.version` | Marketplace version |
| `metadata.pluginRoot` | Base path prepended to relative plugin sources — lets you write `"source": "formatter"` instead of `"source": "./plugins/formatter"` |

## Plugin entry fields

Each item in the `plugins` array:

```json
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin",
  "description": "What this does",
  "version": "1.0.0",
  "author": { "name": "Team", "email": "team@example.com" },
  "homepage": "https://docs.example.com/my-plugin",
  "repository": "https://github.com/org/my-plugin",
  "license": "MIT",
  "keywords": ["tag1", "tag2"],
  "category": "productivity",
  "strict": true
}
```

### Component path overrides (optional)

```json
{
  "commands": ["./commands/core/", "./commands/extras/"],
  "agents":   ["./agents/reviewer.md"],
  "hooks":    { "PostToolUse": [...] },
  "mcpServers": {
    "my-server": {
      "command": "${CLAUDE_PLUGIN_ROOT}/server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
    }
  }
}
```

Use `${CLAUDE_PLUGIN_ROOT}` to reference files inside the installed plugin cache.
Use `${CLAUDE_PLUGIN_DATA}` for state that should survive plugin updates.

### strict mode

| Value | Behavior |
|-------|----------|
| `true` (default) | `plugin.json` is authoritative; marketplace entry can supplement it |
| `false` | Marketplace entry is the entire definition; plugin must not have its own `plugin.json` with components |

Use `strict: false` when the marketplace operator wants full control over which files are exposed.

## Plugin sources — full reference

### Relative path
```json
{ "source": "./plugins/my-plugin" }
```
Must start with `./`. Resolves relative to marketplace root (the directory containing `.claude-plugin/`). Only works with git-based marketplace adds.

### GitHub
```json
{
  "source": "github",
  "repo": "owner/repo",
  "ref": "v2.0.0",
  "sha": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0"
}
```

### Git URL (GitLab, Bitbucket, self-hosted)
```json
{
  "source": "url",
  "url": "https://gitlab.com/team/plugin.git",
  "ref": "main",
  "sha": "a1b2c3..."
}
```
Also accepts `git@` SSH URLs. `.git` suffix is optional.

### Git subdirectory (monorepo)
```json
{
  "source": "git-subdir",
  "url": "https://github.com/acme/monorepo.git",
  "path": "tools/claude-plugin",
  "ref": "v2.0.0",
  "sha": "a1b2c3..."
}
```
Uses sparse clone — only fetches the subdirectory. `url` also accepts `owner/repo` GitHub shorthand.

### npm package
```json
{
  "source": "npm",
  "package": "@acme/claude-plugin",
  "version": "^2.0.0",
  "registry": "https://npm.example.com"
}
```
`registry` is optional — defaults to system npm registry. Use for private registries.

## Version resolution

- Plugin manifest (`plugin.json`) always wins over marketplace entry if both specify `version`
- For relative-path plugins: set version in marketplace entry
- For all other sources: set version in `plugin.json`
- Two refs/commits must have different `version` values or Claude Code treats them as identical and skips updates

## Validation errors reference

| Error | Cause | Fix |
|-------|-------|-----|
| `File not found: .claude-plugin/marketplace.json` | Missing manifest | Create it |
| `Duplicate plugin name "x"` | Two plugins share the same name | Use unique `name` values |
| `plugins[0].source: Path contains ".."` | Source path escapes marketplace root | Remove `..` from path |
| `YAML frontmatter failed to parse` | Invalid YAML in a skill/agent/command file | Fix YAML syntax |
| Plugin name not kebab-case (warning) | Uppercase or special chars in name | Use lowercase, digits, hyphens only |
