# `plugins/insurance/.lsp.json` — LSP Servers (Gleam + Go)

Add Gleam and Go language-server configuration to the `insurance` plugin. The file
`plugins/insurance/.lsp.json` is currently `{}`; this design populates it.

## Goal

Wire two LSP servers into the plugin so Claude Code connects to them when the plugin
is enabled, with resilience fields so a crashed server auto-recovers.

## File

`plugins/insurance/.lsp.json` (plugin root, next to `.mcp.json`). Claude Code reads it
automatically when the plugin is enabled; `/reload-plugins` picks up changes.

## Schema

Top level is a map of arbitrary server-key → server config.

| Field | Type | Required | Meaning |
|-------|------|----------|---------|
| `command` | string | yes | LSP binary name; must be in `$PATH`. |
| `extensionToLanguage` | object | yes | Maps file extension (dot included) → LSP language id. |
| `args` | string[] | no | Arguments passed to the binary. |
| `restartOnCrash` | boolean | no | Auto-restart server if it crashes. |
| `maxRestarts` | number | no | Max restart attempts before giving up. |
| `startupTimeout` | number | no | Max milliseconds to wait for startup. |

## Content

```json
{
  "go": {
    "command": "gopls",
    "extensionToLanguage": {
      ".go": "go"
    },
    "restartOnCrash": true,
    "maxRestarts": 5,
    "startupTimeout": 10000
  },
  "gleam": {
    "command": "gleam",
    "args": ["lsp"],
    "extensionToLanguage": {
      ".gleam": "gleam"
    },
    "restartOnCrash": true,
    "maxRestarts": 5,
    "startupTimeout": 10000
  }
}
```

### Decisions

- **gopls invocation**: no `args`. Modern `gopls` starts the LSP over stdio when run
  as a subprocess with no arguments; `serve` is the legacy explicit form.
- **gleam invocation**: `args = ["lsp"]` is required — the `gleam` binary multiplexes
  subcommands and only speaks LSP under `gleam lsp`.
- **Resilience values**: `maxRestarts = 5`, `startupTimeout = 10000` (10s). Both
  servers can take a moment to index on first start.

## Constraints / Out of scope

- Binaries (`gopls`, `gleam`) are installed separately by the developer. The plugin only
  configures the connection. A missing binary surfaces as `Executable not found in $PATH`
  (visible via `/plugin` → Errors tab or `claude --debug`).
- No binary install or presence verification is added.
- No change to `.liszt/liszt.toml` pre-commit checks (Go is not added there).

## Verification

1. `.lsp.json` is valid JSON.
2. With `gopls` and `gleam` in `$PATH`, enabling the plugin (or `/reload-plugins`) starts
   both servers with no errors in `/plugin` → Errors.
