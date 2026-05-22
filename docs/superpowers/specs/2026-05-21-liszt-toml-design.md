# `.liszt/liszt.toml` — Specification

Configuration format consumed by `plugins/insurance/scripts/pre-commit.sh`. Declares the set of pre-commit checks to run.

## Location

Default path: `.liszt/liszt.toml`, resolved relative to the current working directory (the project being checked). An alternate path may be passed as the first argument to `pre-commit.sh`.

## Top-level structure

The file contains zero or more **check tables**, one per check, named:

```
[pre-commit.<name>]
```

`<name>` matches `[A-Za-z0-9_-]+`. The order of tables in the file is the execution order. Tables outside the `pre-commit.*` namespace are ignored.

## Check table keys

| Key | Type | Required | Default | Meaning |
|-----|------|----------|---------|---------|
| `cmd` | array of strings | **yes** | — | Shell commands to run, in order. |
| `fail_hint` | string | no | (none) | Message printed as the last line if the check fails. |
| `enabled` | boolean | no | `true` | When `false`, the check is skipped silently. |

### `cmd`

An array of shell command strings. Each element is executed via `bash -c` in array order.

- Must be an array. A bare string (`cmd = "..."`) is **not** supported — the check is skipped with a warning.
- Inline and multiline array forms are both accepted:

  ```toml
  cmd = ["gleam format --check src test", "gleam check"]
  ```

  ```toml
  cmd = [
    "gleam format --check src test",
    "gleam check",
  ]
  ```

- A trailing comma after the last element is allowed.
- Items are extracted by matching quoted strings (`"..."` or `'...'`). Commas **inside** a quoted command are preserved; commas between items are separators.
- An empty array (`cmd = []`) skips the check with a warning.

**Limitations** (pure-bash parser): escaped quotes (`\"`) inside a command string are not handled. Keep commands free of embedded escaped quotes.

### `fail_hint`

Optional string. Printed as the **final line** of output when the check fails — intended as a remediation hint (e.g. how to auto-fix). If omitted, nothing extra is printed beyond the per-command failure lines.

### `enabled`

Optional boolean, defaults to `true`. `enabled = false` skips the check without running any of its commands and without output.

## Execution semantics

For each enabled check, in file order:

1. Every command in `cmd` runs in order. Execution does **not** stop at the first failing command within a check — all commands in the check run.
2. If any command exits non-zero, the check is marked failed; the exit code of the **first** failing command is retained.
3. After all of the check's commands have run, if the check failed: `fail_hint` (if set) is printed as the last line, and the run aborts with the retained exit code.
4. If the check passed, execution continues to the next check.

Checks are **fail-fast at the check level**: the first failing check aborts the whole run; subsequent checks do not execute. (Within a single check, all commands run regardless — see step 1.)

When all enabled checks pass, the run exits `0`.

## Complete example

```toml
# liszt pre-commit config
# Each [pre-commit.<name>] declares one check.
#   cmd       = array of shell commands, run in order (all run, even on failure)
#   fail_hint = string printed last if the check fails (optional)
#   enabled   = true|false (optional, defaults to true)

[pre-commit.gleam]
cmd = [
  "gleam format --check src test",
  "gleam check",
]
fail_hint = "run `gleam format src test` to fix formatting"
enabled = true
```
