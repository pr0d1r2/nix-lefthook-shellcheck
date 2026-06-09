# SPEC — nix-lefthook-shellcheck

## §D — Description

A Nix flake that packages a lefthook-compatible ShellCheck wrapper (`lefthook-shellcheck`). The wrapper filters its arguments to only `.sh` and `.bats` files, skipping everything else, and delegates to `shellcheck`. It is designed for Nix-based projects that use lefthook for git hooks, providing two consumption paths: as a lefthook remote config (recommended) or as a flake input added to a devShell. Target users are Nix developers who want automated shell linting in their pre-commit and pre-push hooks.

## §V — Invariants

1. `lefthook-shellcheck` with no arguments exits 0.
2. `lefthook-shellcheck` with non-existent file paths exits 0 (files silently skipped).
3. `lefthook-shellcheck` with non-`.sh`/`.bats` files exits 0 (extensions silently skipped).
4. `lefthook-shellcheck` with a clean `.sh` or `.bats` file exits 0.
5. `lefthook-shellcheck` with a shellcheck-failing file exits non-zero.
6. Mixed inputs: one bad shell file among good files or non-shell files causes failure.
7. `dev.sh` sets `BATS_LIB_PATH` from the `@BATS_LIB_PATH@` placeholder injected by `flake.nix`.
8. `dev.sh` runs `lefthook install` only when `.git/hooks/pre-commit` is absent.
9. `dev.sh` skips `lefthook install` when hooks already exist.
10. The flake builds on all four supported systems: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`.
11. CI runs on both Linux (`ubuntu-latest`) and macOS (`macos-latest`).
12. All lefthook commands have a timeout (default 30s via `$LEFTHOOK_SHELLCHECK_TIMEOUT`).
13. Every shell script has a corresponding bats test file under `tests/unit/`.
14. Lefthook checks run in parallel and apply to both `pre-commit` and `pre-push`.

## §I — Interfaces

### CLI: `lefthook-shellcheck`

```
lefthook-shellcheck [file ...]
```

- Accepts zero or more file paths.
- Filters to existing files with `.sh` or `.bats` extensions.
- Runs `shellcheck` on matching files; exits with shellcheck's exit code.
- Exits 0 when no matching files remain.

### Nix flake outputs

| Output | Description |
|---|---|
| `packages.<system>.default` | `writeShellApplication` wrapping `lefthook-shellcheck.sh` with `shellcheck` in `runtimeInputs` |
| `devShells.<system>.default` | Full dev shell with all linter wrappers, bats, lefthook; runs `dev.sh` as shellHook |
| `devShells.<system>.ci` | CI-oriented shell (same packages, no shellHook, `BATS_LIB_PATH` set as env var) |

### Config files

| File | Format | Purpose |
|---|---|---|
| `lefthook.yml` | YAML | Local lefthook config; defines shellcheck commands and pulls 15 remote linter configs |
| `lefthook-remote.yml` | YAML | Config consumed by other repos via lefthook remotes; uses the wrapped `lefthook-shellcheck` binary |
| `config/lefthook/file_size_limits.yml` | YAML | Per-extension file size limits for the file-size-check linter |
| `.yamllint.yml` | YAML | yamllint config (extends default, disables line-length and truthy key check) |
| `.markdownlint.yml` | YAML | markdownlint config (disables MD013 line length) |
| `.editorconfig` | INI | Editor settings (UTF-8, LF, 2-space indent, trim trailing whitespace) |
| `.envrc` | Shell | direnv config; loads the flake devShell via `use flake` |

### Environment variables

| Variable | Default | Description |
|---|---|---|
| `LEFTHOOK_SHELLCHECK_TIMEOUT` | `30` | Timeout in seconds for shellcheck lefthook commands |
| `BATS_LIB_PATH` | Set by `dev.sh` / `ci` shell | Path to bats helper libraries (bats-support, bats-assert, bats-file) |

## §T — Tasks

| status | id | goal |
|---|---|---|
| `.` | T1 | Add `watch_file` entries to `.envrc` for `flake.nix`, `flake.lock`, and `dev.sh` per direnv skill |
| `.` | T2 | Upgrade `actions/checkout` in `update-pins.yml` from v4 to v6 to match `ci.yml` |
| `.` | T3 | Add bats test for timeout behavior (`LEFTHOOK_SHELLCHECK_TIMEOUT` integration) |
| `.` | T4 | Extract `lefthookWrappersFor` from `flake.nix` into a separate nix module per nix/modularity skill |
| `.` | T5 | Add bats test for symlinked files passed to `lefthook-shellcheck` |
| `.` | T6 | Add bats test for files with spaces in their paths |
| `.` | T7 | Add a markdownlint lefthook check (`.markdownlint.yml` exists but no lefthook command references it) |
| `.` | T8 | Pin the `nix-lefthook-ci-action` in `ci.yml` to a tagged release instead of a bare commit SHA for readability |

## §B — Bugs / Known Issues

1. **`.envrc` missing `watch_file` entries.** The `.envrc` contains only `use flake`. Per the project's own direnv skill, it should watch `flake.nix`, `flake.lock`, `dev.sh`, and nix modules so direnv reloads when they change. Currently, editing `dev.sh` or `flake.nix` does not trigger a direnv reload.

2. **`actions/checkout` version mismatch.** `ci.yml` uses `actions/checkout@v6` while `update-pins.yml` uses `actions/checkout@v4`. Both should use the same version.

3. **No markdownlint lefthook command.** The repo has a `.markdownlint.yml` config and `.md` files tracked in git, but the linter skill requires every tracked file type to have an assigned linter in lefthook. No markdownlint command exists in `lefthook.yml`.

4. **`ci` devShell `BATS_LIB_PATH` differs from `default` shell.** The `ci` shell sets `BATS_LIB_PATH` as a plain environment variable (`"${batsWithLibs}/share/bats"`), while `default` uses `builtins.replaceStrings` in `dev.sh` to set `"@BATS_LIB_PATH@/share/bats"`. Both resolve correctly, but the divergent mechanisms could drift.

5. **No edge-case tests for filenames with spaces or special characters.** The bats tests cover basic happy and sad paths but do not exercise filenames containing spaces, glob characters, or unicode — all valid in lefthook `{staged_files}` expansion.
