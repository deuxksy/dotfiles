# auxo Raspberry Pi 3B Stow 패키지 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Raspberry Pi 3B (auxo)용 stow 패키지 `auxo/`를 생성하고, README.md Hosts 테이블을 업데이트한다.

**Architecture:** `base` + `auxo` 패턴 사용. `base`는 공통 설정(git, nvim, tmux, AI rules), `auxo`는 호스트 특정 쉘 설정(zshrc, alias, path)만 가지는 최소 구조.

**Tech Stack:** GNU Stow, Zsh, Starship prompt

---

## Global Constraints

- 기존 패키지(girl, walle)의 파일 구조와 스타일 일관성 유지
- YAGNI: labwc, kanshi, Raspberry Pi Connect 등 현재 필요없는 것은 제외
- KISS: 최소한의 파일만 생성
- stow `--no-folding` 필수: Git은 symlink 디렉토리 내 변경을 추적하지 않음

---

## File Structure

| 파일 | 설명 | 소스 패턴 |
| :--- | :--- | :--- |
| `auxo/.stow-local-ignore` | Stow 배포 제외 패턴 | `girl/.stow-local-ignore` |
| `auxo/.gitconfig.local` | 호스트별 Git credential helper | `girl/.gitconfig.local` |
| `auxo/.alias` | 최소 alias 모음 | spec에 정의된 최소 버전 |
| `auxo/.path` | PATH/XDG 환경변수 | spec에 정의된 최소 버전 |
| `auxo/.zshenv` | Zsh 초기화 | `walle/.zshenv` 스타일 |
| `auxo/.zshrc` | Zsh 메인 설정 + starship | spec에 정의된 최소 버전 |
| `README.md` | Hosts 테이블에 auxo 추가, Install 섹션 업데이트 | 기존 패턴 따름 |

---

### Task 1: auxo 디렉토리 및 .stow-local-ignore 생성

**Files:**
- Create: `auxo/.stow-local-ignore`

**Interfaces:**
- Produces: `auxo/` 패키지 루트 + stow 제외 규칙

- [ ] **Step 1: 디렉토리 생성**

```bash
mkdir -p /home/deck/git/dotfiles/auxo
```

- [ ] **Step 2: .stow-local-ignore 작성**

girl 패키지와 동일한 패턴 사용:

```text
# Stow 제외 항목
README\.md$
\.bak$
\.orig$
\.\d{6}$
```

- [ ] **Step 3: 파일 생성 확인**

Run: `ls -la /home/deck/git/dotfiles/auxo/`
Expected: `.stow-local-ignore` 파일 존재

- [ ] **Step 4: Commit**

```bash
git add auxo/.stow-local-ignore
git commit -m "feat(auxo): stow 패키지 루트 및 .stow-local-ignore 추가"
```

---

### Task 2: .gitconfig.local 생성

**Files:**
- Create: `auxo/.gitconfig.local`

**Interfaces:**
- Consumes: `base/.gitconfig`의 includeIf 규칙 (호스트별 로컬 설정 로드)
- Produces: Git credential helper 설정

- [ ] **Step 1: 파일 작성**

girl과 동일한 최소 설정:

```ini
[credential]
	helper = store
```

- [ ] **Step 2: 문법 확인**

Run: `git config --file=/home/deck/git/dotfiles/auxo/.gitconfig.local --get credential.helper`
Expected: `store`

- [ ] **Step 3: Commit**

```bash
git add auxo/.gitconfig.local
git commit -m "feat(auxo): gitconfig.local (credential helper) 추가"
```

---

### Task 3: .alias 생성 (최소 버전)

**Files:**
- Create: `auxo/.alias`

**Interfaces:**
- Produces: `.zshrc`에서 source할 alias 모음

- [ ] **Step 1: 파일 작성**

spec에 정의된 최소 버전:

```bash
# 최소 aliases — 자주 쓰는 것만

# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias l='ls -lah'
alias ll='ls -lh'
alias la='ls -A'

# git
alias g='git'
alias gs='git status'
alias gp='git push'
alias gl='git log --oneline -10'

# safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
```

- [ ] **Step 2: 문법 검증**

Run: `zsh -n /home/deck/git/dotfiles/auxo/.alias`
Expected: exit code 0 (문법 오류 없음)

- [ ] **Step 3: Commit**

```bash
git add auxo/.alias
git commit -m "feat(auxo): 최소 alias 추가"
```

---

### Task 4: .path 생성 (최소 버전)

**Files:**
- Create: `auxo/.path`

**Interfaces:**
- Produces: `.zshenv`에서 source할 PATH/XDG 환경변수

- [ ] **Step 1: 파일 작성**

spec에 정의된 최소 버전:

```bash
# XDG basedir 우선
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# PATH 구성
path=(
  "$HOME/.local/bin"
  /usr/local/sbin
  /usr/local/bin
  /usr/sbin
  /usr/bin
  /sbin
  /bin
  $path
)

# mise (나중에 설치할 경우를 위해)
if [ -f "$HOME/.local/share/mise/shims" ]; then
  path=("$HOME/.local/share/mise/shims" $path)
fi
```

- [ ] **Step 2: 문법 검증**

Run: `zsh -n /home/deck/git/dotfiles/auxo/.path`
Expected: exit code 0

- [ ] **Step 3: Commit**

```bash
git add auxo/.path
git commit -m "feat(auxo): PATH/XDG 환경변수 추가"
```

---

### Task 5: .zshenv 생성

**Files:**
- Create: `auxo/.zshenv`

**Interfaces:**
- Consumes: `auxo/.path`
- Produces: 모든 zsh 세션에서 로드되는 초기화 스크립트

- [ ] **Step 1: 파일 작성**

walle 패턴 + spec 정의 기반:

```zsh
# ~/.zshenv - 모든 zsh 세션(interactive/non-interactive)에서 로드

# 기본 PATH와 env
source "$HOME/.path"
```

- [ ] **Step 2: 문법 검증**

Run: `zsh -n /home/deck/git/dotfiles/auxo/.zshenv`
Expected: exit code 0

- [ ] **Step 3: Commit**

```bash
git add auxo/.zshenv
git commit -m "feat(auxo): .zshenv 초기화 스크립트 추가"
```

---

### Task 6: .zshrc 생성 (최소 + starship)

**Files:**
- Create: `auxo/.zshrc`

**Interfaces:**
- Consumes: `auxo/.alias`, starship prompt
- Produces: interactive zsh 세션 메인 설정

- [ ] **Step 1: 파일 작성**

spec에 정의된 최소 버전:

```zsh
# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory extendedhistory hist_ignore_space

# Completion
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zcompdump"

# Prompt: starship
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# Aliases
source "$HOME/.alias"

# Editor
export EDITOR="nvim"
export VISUAL="nvim"

# Key bindings (emacs 모드)
bindkey -e
```

- [ ] **Step 2: 문법 검증**

Run: `zsh -n /home/deck/git/dotfiles/auxo/.zshrc`
Expected: exit code 0

- [ ] **Step 3: 디렉토리 구조 최종 확인**

Run: `ls -la /home/deck/git/dotfiles/auxo/`
Expected:
- `.alias`
- `.gitconfig.local`
- `.path`
- `.stow-local-ignore`
- `.zshenv`
- `.zshrc`

- [ ] **Step 4: Commit**

```bash
git add auxo/.zshrc
git commit -m "feat(auxo): .zshrc (starship 포함) 추가"
```

---

### Task 7: README.md Hosts 테이블 업데이트

**Files:**
- Modify: `README.md:9-18` (Hosts 테이블)
- Modify: `README.md:129-134` (Install 섹션 stow 명령)
- Modify: `README.md:171-178` (디렉토리 설명 테이블)
- Modify: `README.md:25-29` (Host Roles)

**Interfaces:**
- Produces: auxo가 명시된 프로젝트 인덱스

- [ ] **Step 1: Hosts 테이블에 auxo 행 추가**

`girl` 다음 `ava` 앞에 추가:

```markdown
| Host | Model | OS | Config |
| :--- | :--- | :--- | :--- |
| axiom | Mac Studio | macOS | stow: `base` + `axiom` |
| eve | Mac mini | macOS | stow: `base` + `eve` |
| mo | AyaNEO AM02 | NixOS | stow: `base` + `mo` / flake |
| walle | AOOSTAR WTR R1 | Proxmox (Debian) | stow: `base` + `walle` |
| girl | Steam Deck | SteamOS | stow: `base` + `girl` |
| **auxo** | **Raspberry Pi 3 Model B** | **Debian 13 (trixie)** | **stow: `base` + `auxo`** |
| ava | Surface Pro 6 | Windows 10 | pwsh |
```

- [ ] **Step 2: Host Roles에 auxo 추가**

`girl` 다음에 추가:

```markdown
- **girl**: 휴대용 서버
- **auxo**: 휴대용 헤드리스 서버 (Raspberry Pi)
```

- [ ] **Step 3: Install 섹션에 auxo stow 명령 추가**

```bash
stow -t ~ base auxo     # Raspberry Pi (Debian)
```

- [ ] **Step 4: 디렉토리 설명 테이블에 auxo 추가**

`girl` 다음에 추가:

```markdown
| `auxo/` | Raspberry Pi | 헤드리스 서버 (Debian) |
```

- [ ] **Step 5: 변경 사항 검증**

Run: `git diff README.md`
Expected: 위 4군데 변경 내용만 포함

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: README에 auxo 호스트 추가"
```

---

## Self-Review Checklist

작성 완료 후 아래 항목 직접 확인:

**1. Spec coverage:**
- [x] `auxo/` 디렉토리 구조 → Task 1
- [x] 6개 파일(.stow-local-ignore, .gitconfig.local, .alias, .path, .zshenv, .zshrc) → Task 1-6
- [x] README.md Hosts 테이블 업데이트 → Task 7
- [x] KISS/YAGNI: labwc, kanshi 등 제외 → 모든 Task에서 최소 버전만

**2. Placeholder scan:**
- [x] "TBD", "TODO" 없음
- [x] 모든 코드 블록에 실제 내용 있음
- [x] 모든 Step에 실행 명령과 Expected 결과 있음

**3. Type consistency:**
- [x] 파일명 일관: `.alias`, `.path`, `.zshenv`, `.zshrc` (girl/walle와 동일)
- [x] Git config 패턴: `credential.helper = store` (girl과 동일)
