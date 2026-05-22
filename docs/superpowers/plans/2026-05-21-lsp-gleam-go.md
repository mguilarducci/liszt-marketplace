# LSP Gleam + Go Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Populate `plugins/insurance/.lsp.json` with Gleam and Go LSP server configs plus resilience fields.

**Architecture:** Single JSON file at the plugin root. Top level is a map of server-key → config (`command`, `extensionToLanguage`, optional `args`, `restartOnCrash`, `maxRestarts`, `startupTimeout`). Claude Code reads it when the plugin is enabled.

**Tech Stack:** Claude Code plugin `.lsp.json`; `gopls` (Go), `gleam lsp` (Gleam). Binaries installed separately, must be in `$PATH`.

Spec: `docs/superpowers/specs/2026-05-21-lsp-gleam-go-design.md`

---

### Task 1: Write `.lsp.json`

**Files:**
- Modify: `plugins/insurance/.lsp.json` (currently `{}`)

- [ ] **Step 1: Replace file contents**

Write `plugins/insurance/.lsp.json`:

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

- [ ] **Step 2: Verify valid JSON**

Run: `python3 -m json.tool plugins/insurance/.lsp.json`
Expected: pretty-printed JSON, exit 0, no parse error.

- [ ] **Step 3: Commit**

```bash
git add plugins/insurance/.lsp.json
git commit -m "feat(insurance): add gleam + go LSP servers to .lsp.json"
```

---

## Self-Review

- **Spec coverage:** Schema (command/extensionToLanguage/args/restartOnCrash/maxRestarts/startupTimeout) → Task 1 content. gopls no-args + gleam `["lsp"]` decisions → Task 1. Out-of-scope items (binary install, liszt.toml) correctly absent. Covered.
- **Placeholder scan:** None.
- **Type consistency:** Field names match spec table and example. Extension keys include dot.
