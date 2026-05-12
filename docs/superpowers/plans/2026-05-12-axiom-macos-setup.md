# axiom Mac Studio Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `axiom` stow package for Mac Studio M1 Max setup, based on existing `eve` package

**Architecture:** Copy `eve/` package to `axiom/`, update host-specific references, document new host in project README

**Tech Stack:** GNU Stow, Homebrew, mise, zsh

---

## File Structure

```
axiom/                            # NEW - Stow package (copied from eve)
├── .stow-local-ignore            # NEW - Copied from eve
├── .alias                        # NEW - Copied from eve
├── .path                         # NEW - Copied from eve
├── .zshrc                        # NEW - Copied from eve
├── .config/mise/config.toml      # NEW - Copied from eve
├── .ssh/config                   # NEW - Copied from eve
└── .key                          # NEW - Copied from eve

README.md                         # MODIFY - Add axiom to hosts table
CLAUDE.md                         # MODIFY - Add axiom to hosts table
```

---

### Task 1: Create axiom package directory

**Files:**
- Create: `axiom/`
- Create: `axiom/.stow-local-ignore`

- [ ] **Step 1: Copy eve package to axiom**

```bash
cd /Users/crong/git/dotfiles
cp -r eve axiom
```

Expected: New `axiom/` directory created with all eve contents

- [ ] **Step 2: Verify axiom package structure**

```bash
ls -la axiom/
```

Expected output:
```
total 56
drwxr-xr-x  11 crong  staff   352 May 12 XX:XX .
drwxr-xr-x  27 crong  staff   864 May 12 XX:XX ..
-rw-r--r--   1 crong  staff   441 May 12 XX:XX .alias
drwxr-xr-x   3 crong  staff    96 May 12 XX:XX .config
-rw-r--r--   1 crong  staff  1908 May 12 XX:XX .function
-rw-r--r--   1 crong  staff  2821 May 12 XX:XX .key
-rw-r--r--   1 crong  staff   413 May 12 XX:XX .path
drwxr-xr-x   3 crong  staff    96 May 12 XX:XX .ssh
-rw-r--r--   1 crong  staff    57 May 12 XX:XX .stow-local-ignore
-rw-r--r--   1 crong  staff  5406 May 12 XX:XX .zshrc
drwxr-xr-x   3 crong  staff    96 May 12 XX:XX scripts
```

- [ ] **Step 3: Commit**

```bash
git add axiom/
git commit -m "feat: add axiom stow package (copied from eve)"
```

---

### Task 2: Update project documentation

**Files:**
- Modify: `README.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update README.md hosts table**

```bash
# Find the hosts table in README.md and add axiom entry
# Current structure has Mac mini (M4) entry, add Mac Studio (M1 Max) after it
```

Edit `README.md` hosts table:

```markdown
| Host | OS | Stow Packages |
| :--- | :--- | :--- |
| Mac Studio (M1 Max, 64GB, 512GB) | MacOS 26 | `base` + `axiom` |
| Mac mini (M4, 16GB, 256GB) | MacOS 26 | `base` + `eve` |
```

- [ ] **Step 2: Update CLAUDE.md hosts table**

Edit `CLAUDE.md` (which is symlinked to `.ai/AGENTS.md`):

Find the hosts table and add:

```markdown
| Mac Studio (M1 Max, 64GB, 512GB) | MacOS 26 | `base` + `axiom` |
```

Update Mac Studio entry from "수리중" to active:

```markdown
### Other Devices

- Mac Studio (M1 Max, 64GB, 512GB) — `base` + `axiom` — Local LLM 서버 + 개발
```

- [ ] **Step 3: Verify documentation changes**

```bash
git diff README.md CLAUDE.md
```

Expected: Shows axiom added to hosts table in both files

- [ ] **Step 4: Commit**

```bash
git add README.md CLAUDE.md
git commit -m "docs: add axiom host to documentation"
```

---

### Task 3: Verify stow package correctness

**Files:**
- Test: `axiom/` directory structure

- [ ] **Step 1: Check .stow-local-ignore exists**

```bash
cat axiom/.stow-local-ignore
```

Expected output:
```
README.md
```

- [ ] **Step 2: Verify key configuration files**

```bash
head -5 axiom/.zshrc
echo "---"
head -5 axiom/.path
echo "---"
cat axiom/.config/mise/config.toml
```

Expected: Valid zsh, path, and mise configuration

- [ ] **Step 3: Dry-run stow to verify no conflicts**

```bash
stow -n -t ~ base axiom 2>&1 || true
```

Expected: No conflicts reported (warnings about existing files are OK)

---

### Task 4: Final verification and cleanup

**Files:**
- None (verification only)

- [ ] **Step 1: Check git status**

```bash
git status
```

Expected: Shows axiom/ directory added, README.md and CLAUDE.md modified

- [ ] **Step 2: Review all changes**

```bash
git diff --stat HEAD
```

Expected output similar to:
```
 README.md                                    |  2 +-
 CLAUDE.md                                    |  4 ++--
 docs/superpowers/specs/2026-05-12-axiom-macos-setup-design.md |  1 +
 axiom/.alias                                 |  1 +
 axiom/.config/mise/config.toml               | 10 ++
 axiom/.function                              | 50 +++++++
 axiom/.key                                   | 72 ++++++++++
 axiom/.path                                  | 30 +++++
 axiom/.ssh/config                            | 30 +++++
 axiom/.stow-local-ignore                     |  1 +
 axiom/.zshrc                                 | 80 +++++++++++
 axiom/scripts                                |  1 +
```

- [ ] **Step 3: Final summary**

Verify:
- [ ] `axiom/` package created with all necessary files
- [ ] `README.md` updated with axiom host
- [ ] `CLAUDE.md` updated with axiom host
- [ ] Mac Studio status changed from "수리중" to active
- [ ] All changes committed

---

## Deployment Instructions (for axiom machine)

Once the plan is executed, deploy on axiom Mac Studio:

```bash
# 1. Xcode Command Line Tools
xcode-select --install

# 2. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. dotfiles clone
git clone git@github.com:deuxksy/dotfiles.git ~/git/dotfiles

# 4. Brewfile 패키지 설치
cd ~/git/dotfiles && brew bundle

# 5. Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 6. Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# 7. stow 배포
cd ~/git/dotfiles && stow -t ~ base axiom

# 8. mise로 런타임 설치
cd ~ && mise install

# 9. 셸 재시작
exec zsh
```
