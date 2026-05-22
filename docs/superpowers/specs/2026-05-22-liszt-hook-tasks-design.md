# `.liszt/liszt.toml` git-hook tasks — Specification

Declares the commands to run for each git hook, per language, in this repo's
`.liszt/liszt.toml`. This is **not** git's hook format — it is a set of named
task tables consumed by the `liszt run <name>` command. Wiring a git hook to a
task (e.g. `.git/hooks/pre-commit` calling `liszt run gleam-pre-commit`) is out
of scope here; this spec covers the config only.

## Schema

Adopts the generic `[tasks.<name>]` schema used by the `liszt` CLI
(`internal/runner/runner.go`), replacing the older repo-local `[pre-commit.*]`
format and its bash parser (`plugins/insurance/scripts/pre-commit.sh`).

| Key | Type | Required | Default | Meaning |
|-----|------|----------|---------|---------|
| `run` | array of strings | **yes** | — | Shell commands, run in order via `bash -c`. |
| `fail_hint` | string | no | (none) | Printed after a failure as a remediation hint. |
| `enabled` | boolean | no | `true` | When `false`, the task is skipped (exit 0). |

### Execution semantics (from the CLI runner)

- All commands in `run` execute even if an earlier one fails.
- The exit code of the **first** failing command is retained and returned.
- On failure, `fail_hint` (if set) is printed last.
- A disabled task exits 0 without output. An enabled task with empty `run`
  exits 1 (error). Therefore every task here has at least one command.

## Naming

Task names are `<language>-<hook>`:

- `gleam-pre-commit`, `gleam-pre-push`
- `golang-pre-commit`, `golang-pre-push`

`pre-commit` runs format + static checks (fast); `pre-push` runs tests (heavier).

## Task contents

```toml
[tasks.gleam-pre-commit]
run = [
  "gleam format --check src test",
  "gleam check",
]
fail_hint = "run `gleam format src test` to fix formatting"
enabled = true

[tasks.gleam-pre-push]
run = ["gleam test"]
enabled = true

[tasks.golang-pre-commit]
run = [
  'test -z "$(gofmt -l .)"',
  "go vet ./...",
]
fail_hint = "run `gofmt -w .` to fix formatting"
enabled = true

[tasks.golang-pre-push]
run = ["go test -race ./..."]
enabled = true
```

### Notes

- **golang format check**: `gofmt -l .` lists unformatted files but always
  exits 0, so it cannot fail a hook on its own. Wrapping it in
  `test -z "$(gofmt -l .)"` fails when the file list is non-empty. The command
  is a single-quoted TOML literal string so the inner `"` need no escaping; the
  CLI's go-toml parser handles it.
- **gleam has no race detector**: gleam targets BEAM (isolated processes,
  message passing, immutable data — no shared-memory data races) or JS
  (single-threaded). Only the Go target gets `-race`.
