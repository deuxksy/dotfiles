# auxo Raspberry Pi 3B Stow 패키지 설계

> **Date**: 2026-07-27  
> **Status**: Completed  
> **Target**: Raspberry Pi 3 Model B Rev 1.2 (auxo)

---

## 1. 배경

### 1.1 auxo 현황 (fastfetch)

| 항목 | 내용 |
|:---|:---|
| Host | Raspberry Pi 3 Model B Rev 1.2 |
| OS | Debian GNU/Linux 13 (trixie) aarch64 |
| Kernel | 6.18.34+rpt-rpi-v8 |
| WM | labwc (Wayland) — 헤드리스로 사용 예정 |
| Memory | 289 MiB / 905 MiB (32%) |
| Swap | 56 MiB / 905 MiB (6%) |
| Disk | 5.7 GiB / 29 GiB (20%) |
| Local IP | 192.168.221.199 (wlan0) |
| Shell | bash (zsh/starship 미설치 상태) |
| Secrets | `.key` 없음 |
| SSH | `authorized_keys`만 있음, `.ssh/config` 없음 |

### 1.2 설계 원칙

- **KISS**: 최소한의 설정만 가져온다
- **YAGNI**: labwc, kanshi, Raspberry Pi Connect 등 나중에 필요할 때 추가
- **일관성**: 기존 `base` + `<host>` 패턴을 따른다
- **쉘 통합**: bash → zsh + starship로 통일

---

## 2. 아키텍처

### 2.1 패키지 구조

```
dotfiles/
├── base/              # 공통 설정 (모든 호스트)
│   ├── .claude/
│   ├── .gemini/
│   ├── .codex/
│   ├── .config/nvim/
│   ├── .gitconfig
│   ├── .tmux.conf
│   └── .wezterm.lua
└── auxo/              # auxo 특정 설정 (새로 생성)
    ├── .stow-local-ignore
    ├── .gitconfig.local
    ├── .alias
    ├── .path
    ├── .zshenv
    └── .zshrc
```

### 2.2 호스트 테이블 (README.md 업데이트 대상)

| Host | OS | Role | 패키지 관리 | stow 패키지 |
|:---|:---|:---|:---|:---|
| mo | NixOS | 개발 워크스테이션 | nix, flake | `base` + `mo` |
| axiom | macOS | 개발/일상 | Brewfile | `base` + `axiom` |
| eve | macOS | 개발/일상 | Brewfile | `base` + `eve` |
| girl | SteamOS | 게임/개발 | mise | `base` + `girl` |
| **auxo** | **Debian 13 (trixie)** | **헤드리스 서버** | **apt** | **`base` + `auxo`** |
| walle | Proxmox (Debian) | Homelab 서버 | apt | `base` + `walle` + `walle-sudo` |
| ava | Windows 10 | SSH 클라이언트 | pwsh | (stow 미사용) |
| kyolim | Windows 11 | 개발/일상 | pwsh | (stow 미사용) |
| arv | OpenWrt | 라우터 | - | (stow 미사용) |
| steward | OpenWrt | 라우터 | - | (stow 미사용) |

---

## 3. 컴포넌트 상세

### 3.1 base에서 가져오는 것

| 파일/디렉토리 | 용도 |
|:---|:---|
| `.claude/` | Claude Code 규칙 및 설정 |
| `.gemini/` | Gemini/Antigravity 규칙 |
| `.codex/` | Codex 규칙 및 에이전트 설정 |
| `.config/nvim/` | Neovim 설정 |
| `.gitconfig` | 공통 Git 설정 |
| `.tmux.conf` | tmux 설정 |
| `.wezterm.lua` | 터미널 설정 (헤드리스지만 일관성) |

### 3.2 auxo 특정

#### `.stow-local-ignore` (필수)

```text
# Git은 symlink 디렉토리 내 변경을 추적하지 않으므로 no-folding 필요
\.git
\.github
README\.md
LICENSE
\.gitignore
\.gitattributes
\.gitleaks\.toml
\.sops\.yaml
\.stow-local-ignore
\.serena
\.ai
\.omc
\.remember
CLAUDE\.md
AGENTS\.md
GEMINI\.md

# 호스트별 디렉토리 (여기 내용만 stow 배포)
^axiom/
^eve/
^girl/
^mo/
^walle/
^walle-sudo/
^auxo/
^ava/
^ava-sudo/
^nix/
^docs/
^scripts/
^windows/
```

#### `.gitconfig.local`

```ini
# auxo 특정 Git 설정
# base의 .gitconfig가 includeIf로 이 파일을 참조
[user]
  email =  # 필요시 추가 (공통 email 사용시 비워둠)
```

#### `.alias` (최소)

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

#### `.path` (최소)

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

#### `.zshenv`

```zsh
# ZDOTDIR 설정 (선택 사항 — 홈 깨끗하게 유지하려면)
# export ZDOTDIR="$HOME/.config/zsh"

# 기본 PATH와 env
source "$HOME/.path"
```

#### `.zshrc` (최소 + starship)

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

### 3.3 제외하는 것

| 항목 | 이유 |
|:---|:---|
| `labwc/`, `kanshi/`, `wf-panel-pi/` | 헤드리스 서버로 사용, 나중에 필요시 추가 |
| `com.raspberrypi.connect/` | Raspberry Pi Connect — 나중에 |
| `systemd/` user services | 별도 관리가 필요한 경우 추가 |
| `.ansible/` | 나중에 사용 패턴이 명확해지면 |
| `Brewfile` | macOS 전용, Debian은 apt/mise 사용 |
| `.wakatime.cfg` | 필요시 개별 추가 |
| `.ssh/config` | auxo에는 현재 없음, 필요시 나중에 |
| `.key` | 현재 없음, sops 암호화 필요시 추가 |

---

## 4. 배포 절차

### 4.1 auxo 에서 실행할 것

```bash
# 1. dotfiles clone (이미 git 디렉토리 있을 수 있음)
cd ~/git
git clone git@github.com:deuxksy/dotfiles.git  # 또는 HTTPS

# 2. zsh + starship 설치 (Debian)
sudo apt update
sudo apt install -y zsh starship

# 3. 기존 bash 설정 백업 (필요시)
cd ~
mkdir -p ~/.bash-backup
mv .bashrc .bash_logout .profile .bash-backup/ 2>/dev/null || true

# 4. stow 배포
cd ~/git/dotfiles
stow --no-folding -t ~ base auxo

# 5. 기본 쉘 변경 (선택 사항)
chsh -s $(which zsh)

# 6. 재접속 또는 zsh 실행
exec zsh
```

### 4.2 stow 충돌시

```bash
# 기존 파일을 repo로 adopt (주: 기존 설정이 덮어씌워짐)
stow --adopt -t ~ base auxo

# 또는 충돌 파일 개별 백업 후 제거
```

---

## 5. 구현 계획

### Phase 1: 로컬 패키지 생성 (girl 호스트에서)

1. `auxo/` 디렉토리 생성
2. `.stow-local-ignore` 생성 (walle/girl 패턴 참고)
3. `.gitconfig.local` 생성
4. `.alias`, `.path` 최소 버전 작성
5. `.zshenv`, `.zshrc` 작성 (starship 포함)
6. `README.md` Hosts 테이블 업데이트
7. 커밋

### Phase 2: auxo 에서 배포

1. zsh + starship 설치 확인
2. dotfiles pull 최신화
3. stow 배포 테스트
4. 기본 쉘 변경 (선택)
5. 정상 동작 확인

---

## 6. 검증 항목

- [x] `stow -t ~ base auxo` 실행시 충돌 없음
- [x] `zsh` 실행시 starship prompt 정상 출력
- [x] `nvim`, `git`, `tmux` 정상 동작
- [x] `.zsh_history`, `.cache` 등 홈에 깨끗하게 생성
- [x] SSH authorized_keys 유지 (삭제되지 않음)

---

## 7. 변경 로그

| 날짜 | 변경 내용 |
|:---|:---|
| 2026-07-27 | 초기 설계 문서 작성 |
