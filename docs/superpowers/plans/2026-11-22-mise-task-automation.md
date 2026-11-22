# Dotfiles `mise.toml` Task Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add repo-level verification tools (`gitleaks`, `shellcheck`) and 10 declarative `mise` tasks (verify, diagnostics, repair) to the root `mise.toml` while preserving the existing `enter` hook, and document the standard commands in `.ai/RULES.md`.

**Architecture:** All configuration lives in the repo root `mise.toml` (leaving host-specific `<host>/.config/mise/config.toml` untouched to avoid GNU Stow conflicts). Tasks are grouped into 3 functional namespaces (`lint:*`/`stow:*`/`test:*`/`verify`, `doctor`/`sops:*`, `hooks:*`/`apm:*`) and run deterministically in both interactive and non-interactive (AI Agent / CI) shells.

**Tech Stack:** `mise` (TOML tasks, `aqua:` backend), `shellcheck`, `gitleaks`, `stow`, `sops`, `pwsh` (optional), GNU Bash.

**Spec:** `docs/superpowers/specs/2026-11-22-mise-task-automation-design.md`

## Global Constraints

- Keep existing `[hooks] enter = "git pull --ff-only"` intact in `mise.toml`.
- Do NOT create `base/.config/mise/config.toml` or modify any `<host>/.config/mise/config.toml` (7 hosts already own it).
- Do NOT modify `install.sh`, `windows/install.ps1`, or `.githooks/`.
- All `stow` invocations MUST pass `--no-folding`.
- All verification/diagnostic tasks must work in non-interactive shells and return meaningful exit codes.
- `test:windows` MUST exit 0 with a clear skip message when `pwsh` is not installed.

## Review Focus

- **Unrecognized hostname in `stow:check`**: On a host whose `hostname -s` does not match a repo directory (e.g., CI or new host), `stow:check` should fall back to checking `base` only rather than failing with a missing package error; if an explicit host arg is passed and does not exist as a directory, it should fail fast with a clear error.
- **Pre-existing `SC2034` warnings in `.githooks/pre-push`**: `shellcheck` flags unused `local_ref`/`remote_ref` in `while read` on `.githooks/pre-push:19`; `lint:shell` must pass `-e SC2034` so real warnings still fail without modifying `.githooks/pre-push`.
- **Missing argument or invalid profile in `sops:edit`**: Running `mise run sops:edit` without a profile name (or with a nonexistent profile) must print usage and exit non-zero instead of passing a broken path to `sops`.
- **Missing `~/.key` or age key in `sops:check` / `doctor`**: When `~/.key` does not exist on a fresh host, `doctor` and `sops:check` must report a clear failure message without crashing with an unhandled shell error.
- **No-op safety in `apm:repair`**: When `~/.apm/apm.yml` and `~/.apm/apm.lock.yaml` are already valid symlinks, `apm:repair` must be a safe idempotent no-op without creating backup files.

---

### Task 1: Verification Tools & Verify DAG Tasks in `mise.toml`

**Files:**
- Modify: `mise.toml:1-2`

**Interfaces:**
- Consumes: Existing `mise.toml` (`[hooks] enter = "git pull --ff-only"`).
- Produces: `[tools]` (`aqua:gitleaks/gitleaks`, `aqua:koalaman/shellcheck`) and tasks `lint:shell`, `lint:secrets`, `stow:check`, `test:windows`, `verify` in `mise.toml`.

- [ ] **Step 1: Verify baseline state of `mise.toml`**

Run: `cat mise.toml`
Expected: Only `[hooks]` with `enter = "git pull --ff-only"`.

- [ ] **Step 2: Add `[tools]` and the 5 verification tasks to `mise.toml`**

Preserve `[hooks]` at the top of `mise.toml`, then add:
- `[tools]`:
  - `"aqua:gitleaks/gitleaks" = "latest"`
  - `"aqua:koalaman/shellcheck" = "latest"`
- `[tasks."lint:shell"]`:
  - `description = "Lint repository shell scripts with shellcheck"`
  - `sources = ["install.sh", ".githooks/pre-push", "*/scripts/install_nvtools.sh"]`
  - `run = "shellcheck -e SC2034 install.sh .githooks/pre-push */scripts/install_nvtools.sh"`
- `[tasks."lint:secrets"]`:
  - `description = "Scan repository for leaked secrets with gitleaks"`
  - `run = "gitleaks detect --no-banner"`
- `[tasks."stow:check"]`:
  - `description = "Dry-run GNU Stow symlink check (--no-folding)"`
  - `run`: Bash script that accepts optional `$1` host override:
    - If `$1` is given: verify `-d "$1"` (else print error and exit 1), then run `stow --no-folding -n -v -t ~ base "$1"`.
    - If `$1` is omitted: derive `HOST=$(hostname -s | tr '[:upper:]' '[:lower:]')`; if `-d "$HOST"`, check `base "$HOST"`, else print fallback notice and check `base` only.
- `[tasks."test:windows"]`:
  - `description = "Run Windows install.ps1 Pester regression tests"`
  - `run`: If `command -v pwsh >/dev/null 2>&1`, run `pwsh -NoProfile -Command 'Invoke-Pester -CI windows/tests/*.Tests.ps1'`; otherwise print `[skip] pwsh not installed — skipping Windows Pester tests` and exit 0.
- `[tasks.verify]`:
  - `description = "Run all repository verification checks in parallel"`
  - `depends = ["lint:shell", "lint:secrets", "stow:check", "test:windows"]`

- [ ] **Step 3: Run verification tasks and edge-case checks**

Run:
```bash
mise tasks
mise run verify
mise run stow:check nonexistent-host && echo "UNEXPECTED_PASS" || echo "EXPECTED_FAIL"
```
Expected:
- `mise tasks` lists `lint:shell`, `lint:secrets`, `stow:check`, `test:windows`, `verify`.
- `mise run verify` exits 0 (`lint:shell`, `lint:secrets`, `stow:check` pass; `test:windows` passes or skips cleanly if `pwsh` is absent).
- `mise run stow:check nonexistent-host` exits non-zero and prints `EXPECTED_FAIL`.

- [ ] **Step 4: Commit Task 1**

```bash
git add docs/superpowers/specs/2026-11-22-mise-task-automation-design.md mise.toml
git commit -m "feat(mise): add repo verification tools and verify task DAG"
```

---

### Task 2: Diagnostics & Repair Tasks in `mise.toml`

**Files:**
- Modify: `mise.toml` (append after `[tasks.verify]`)

**Interfaces:**
- Consumes: `mise.toml` from Task 1.
- Produces: Tasks `doctor`, `sops:check`, `hooks:install`, `apm:repair`, `sops:edit` in `mise.toml`.

- [ ] **Step 1: Add the 5 diagnostic and repair tasks to `mise.toml`**

Append to `mise.toml`:
- `[tasks.doctor]`:
  - `description = "Check host dotfiles invariants (hooksPath, symlinks, sops, binaries)"`
  - `run`: Bash script (`set -uo pipefail`, accumulating `FAIL=0`) that checks and prints `[OK]`/`[FAIL]` for:
    1. `git config --get core.hooksPath` equals `.githooks`
    2. `~/.apm/apm.yml` is a symlink (`-L`)
    3. `~/.claude/settings.json` is a symlink (`-L`)
    4. `~/.key` exists and `sops -d ~/.key >/dev/null 2>&1` succeeds
    5. Required binaries exist in `PATH`: `stow`, `sops`, `age`, `gitleaks`, `shellcheck`
    - Exits `1` if `FAIL -gt 0`, else `0`.
- `[tasks."sops:check"]`:
  - `description = "Verify decryption of ~/.key and Claude sops profiles"`
  - `run`: Bash script (`set -euo pipefail`) checking `-f "$HOME/.key"` + `sops -d "$HOME/.key" >/dev/null`, then iterating `base/.config/claude/profiles/*.env.sops` with `sops -d --input-type dotenv --output-type dotenv "$f" >/dev/null`. Prints each file's status and fails cleanly if `~/.key` is missing or any decryption fails.
- `[tasks."hooks:install"]`:
  - `description = "Configure repository Git hooksPath to .githooks"`
  - `run = "git config core.hooksPath .githooks && echo 'core.hooksPath set to .githooks'"`
- `[tasks."apm:repair"]`:
  - `description = "Repair R8 broken ~/.apm/apm.yml symlink and migrate apm.lock.yaml"`
  - `run`: Bash script (`set -euo pipefail`):
    - If `[[ -e "$HOME/.apm/apm.yml" && ! -L "$HOME/.apm/apm.yml" ]]`: back up to `$HOME/.apm/apm.yml.bak-$(date +%Y%m%d%H%M%S)`, `rm -f "$HOME/.apm/apm.yml"`, `stow --no-folding -R -t ~ base`.
    - If `[[ -f "$HOME/.apm/apm.lock.yaml" && ! -L "$HOME/.apm/apm.lock.yaml" ]]`: copy to `base/.apm/apm.lock.yaml`, `rm -f "$HOME/.apm/apm.lock.yaml"`, `stow --no-folding -R -t ~ base`, print reminder to commit `base/.apm/apm.lock.yaml`.
    - If both are already symlinks: print `apm symlinks OK (no-op)`.
- `[tasks."sops:edit"]`:
  - `description = "Edit an encrypted Claude dotenv profile with sops (usage: mise run sops:edit <zai|kimi|aperture|mcp>)"`
  - `run`: Bash script (`set -euo pipefail`) taking `PROFILE="${1:-}"`; if empty or `base/.config/claude/profiles/${PROFILE}.env.sops` does not exist, print usage with available profile names and exit 1; else `exec sops --input-type dotenv --output-type dotenv "base/.config/claude/profiles/${PROFILE}.env.sops"`.

- [ ] **Step 2: Run diagnostic, repair, and edge-case checks**

Run:
```bash
mise tasks
mise run hooks:install
mise run doctor
mise run sops:check
mise run apm:repair
mise run sops:edit && echo "UNEXPECTED_PASS" || echo "EXPECTED_FAIL"
```
Expected:
- `mise tasks` lists all 10 tasks.
- `mise run hooks:install` sets `core.hooksPath` to `.githooks`.
- `mise run doctor` and `mise run sops:check` report clear `[OK]`/`[FAIL]` diagnostics.
- `mise run apm:repair` prints `apm symlinks OK (no-op)` (or repairs if broken) without creating unnecessary backups.
- `mise run sops:edit` without args prints usage and exits non-zero (`EXPECTED_FAIL`).

- [ ] **Step 3: Commit Task 2**

```bash
git add mise.toml
git commit -m "feat(mise): add doctor, sops, hooks, and apm repair tasks"
```

---

### Task 3: Document Standard `mise run` Commands in `.ai/RULES.md`

**Files:**
- Modify: `.ai/RULES.md:20-50`

**Interfaces:**
- Consumes: Task names defined in Tasks 1 & 2 (`verify`, `doctor`, `sops:check`, `hooks:install`, `apm:repair`, `sops:edit`).
- Produces: Updated `## Commands` section in `.ai/RULES.md`.

- [ ] **Step 1: Add `mise run` commands to `## Commands` in `.ai/RULES.md`**

In `.ai/RULES.md` under `## Commands`, add a compact block inside the bash fence:
```bash
# mise tasks (검증 / 진단 / 복구)
mise run verify          # lint:shell + lint:secrets + stow:check + test:windows
mise run doctor          # hooksPath, symlink, sops, 필수 바이너리 점검
mise run hooks:install   # git config core.hooksPath .githooks
mise run apm:repair      # R8 ~/.apm/apm.yml symlink 복구 + lock 이관
mise run sops:edit <name> # base/.config/claude/profiles/<name>.env.sops 편집
```

- [ ] **Step 2: Verify diff and run final `mise run verify`**

Run:
```bash
git diff .ai/RULES.md
mise run verify
```
Expected: Clean minimal diff in `.ai/RULES.md` and `mise run verify` exits 0.

- [ ] **Step 3: Commit Task 3**

```bash
git add .ai/RULES.md
git commit -m "docs(rules): document mise run verification and repair tasks"
```
