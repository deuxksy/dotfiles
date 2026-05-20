# eve (Mac mini M4, macOS 26) Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mac mini M4 개발 워크스테이션을 위한 stow 패키지 및 Homebrew 설정 구축

**Architecture:** Homebrew (CLI) + mise (SDK) + stow (dotfiles) + Oh My Zsh + Powerlevel10k

**Tech Stack:** macOS 26, Homebrew, mise, zsh, stow

---

## File Structure

```
Brewfile                          # Homebrew 패키지 정의 (신규)
eve/.path                         # macOS 환경변수 (수정)
eve/.zshrc                        # Oh My Zsh 설정 (수정)
```

---

## Task 1: Brewfile 생성

**Files:**
- Create: `Brewfile`

- [ ] **Step 1: Brewfile 작성**

```ruby
# Core CLI
brew "git"
brew "neovim"
brew "tmux"
brew "ripgrep"
brew "fd"
brew "fzf"
brew "jq"
brew "yq"
brew "bat"
brew "eza"
brew "zoxide"
brew "atuin"
brew "direnv"
brew "gnupg"
brew "sops"
brew "age"
brew "curlie"
brew "glow"
brew "tealdeer"
brew "fastfetch"
brew "stow"

# Development
brew "mise"
brew "kubectl"
brew "opentofu"
brew "awscli2"
brew "pipx"
brew "aria2"

# Shell
brew "zsh"
brew "zsh-completions"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# Fonts
cask "font-jetbrains-mono-nerd-font"
```

- [ ] **Step 2: Brewfile 검증**

Run: `cat Brewfile`
Expected: 위 내용이 정확히 포함

- [ ] **Step 3: Commit**

```bash
git add Brewfile
git commit -m "feat: eve 호스트용 Brewfile 추가"
```

---

## Task 2: eve/.path 수정 (macOS 경로 대응)

**Files:**
- Modify: `eve/.path`

- [ ] **Step 1: walle 기준으로 .path 재작성**

walle(`.path`)와 동일한 구조 유지 + macOS 변경사항:
- `linuxbrew` → `/opt/homebrew`
- `OLLAMA_VULKAN`, `GOG_KEYRING_PASSWORD`, `DOCKER_HOST` 제거 (Linux 전용)
- `HISTFILESIZE` → `SAVEHIST` (zsh 네이티브)

```bash
export TIME_STYLE='long-iso'
export EDITOR='nvim'
export HISTSIZE=50000
export SAVEHIST=50000
export PNPM_HOME="$HOME/.local/share/pnpm"

PATH="/opt/homebrew/bin:${PATH}"
PATH="${HOME}/.opencode/bin:${PATH}"
PATH="${PNPM_HOME}:${PATH}"
PATH="${HOME}/.local/bin:${PATH}"

fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fpath=(~/.zsh/completions $fpath)
fpath=(~/.zfunc $fpath)

export PATH
export fpath
```

- [ ] **Step 2: 변경사항 확인**

Run: `diff -u eve/.path ~/.path 2>/dev/null || echo "비교 대상 없음"`
Expected: 위 변경사항 반영

- [ ] **Step 3: Commit**

```bash
git add eve/.path
git commit -m "fix(eve): .path를 walle 기준으로 정리 및 macOS 경로 대응"
```

---

## Task 3: eve/.zshrc 수정 (설계 문서 기준 정리)

**Files:**
- Modify: `eve/.zshrc`

- [ ] **Step 1: walle 기준으로 .zshrc 재작성**

walle(`.zshrc`)와 동일한 구조 유지 + macOS 변경사항:
- `export SHORT_HOST="eve"` 추가
- linuxbrew 관련 라인 제거
- `compinit -C` 플래그로 시작 속도 개선
- 개별 도구별 completion (OpenClaw, iTerm2, LM Studio, NVM) 제거

```zsh
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export SHORT_HOST="eve"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

plugins=(git)
source $ZSH/oh-my-zsh.sh

export LANG=en_US.UTF-8

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
. ~/.path
. ~/.alias
eval "$(sops -d ~/.key)"

# initialise completions with ZSH's compinit (with -C flag for speed)
autoload -Uz compinit && compinit -C
autoload -Uz bashcompinit && bashcompinit

eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"
eval "$(mise activate zsh)"
```

- [ ] **Step 2: 변경사항 확인**

Run: `head -30 eve/.zshrc`
Expected: SHORT_HOST="eve", compinit -C 포함, 불필요한 completion 제거됨

- [ ] **Step 3: Commit**

```bash
git add eve/.zshrc
git commit -m "fix(eve): .zshrc를 walle 기준으로 정리 및 compinit 속도 개선"
```

---

## Task 4: 검증 및 정리

- [ ] **Step 1: eve 패키지 구조 검증**

Run: `tree eve/ -L 2 -a`
Expected:
```
eve/
├── .alias
├── .config/
│   └── mise/
│       └── config.toml
├── .function
├── .key
├── .path
├── .ssh/
│   └── config
├── .stow-local-ignore
├── .zshrc
└── scripts/
```

- [ ] **Step 2: 설계 문서 검증 항목 체크리스트 작성**

Create: `eve/SETUP.md`

```markdown
# eve 호스트 초기 세팅 절차

## 1. Xcode Command Line Tools
\`\`\`bash
xcode-select --install
\`\`\`

## 2. Homebrew 설치
\`\`\`bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
\`\`\`

## 3. dotfiles clone
\`\`\`bash
git clone git@github.com:deuxksy/dotfiles.git ~/git/dotfiles
\`\`\`

## 4. Brewfile 패키지 설치
\`\`\`bash
cd ~/git/dotfiles && brew bundle
\`\`\`

## 5. Oh My Zsh
\`\`\`bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
\`\`\`

## 6. Powerlevel10k
\`\`\`bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
\`\`\`

## 7. stow 배포
\`\`\`bash
cd ~/git/dotfiles && stow -t ~ base eve
\`\`\`

## 8. mise로 런타임 설치
\`\`\`bash
cd ~ && mise install
\`\`\`

## 9. 셸 재시작
\`\`\`bash
exec zsh
\`\`\`

## 검증 항목
- [ ] \`eza\` → ls 대체 동작
- [ ] \`nvim\` → LazyVim 플러그인 로드
- [ ] \`mise list\` → go, node, python 등 설치 확인
- [ ] \`p10k configure\` → 프롬프트 커스터마이징
\`\`\`

- [ ] **Step 3: Commit**

```bash
git add eve/SETUP.md
git commit -m "docs(eve): 초기 세팅 절차 문서 추가"
```

---

## Task 5: 설계 문서와의 일치성 최종 검증

- [ ] **Step 1: 설계 문서 대비 검증**

Run: `cat docs/superpowers/specs/2026-05-11-eve-macos-setup-design.md | grep -E "^- |^\|"`
Expected: 모든 항목이 구현되었는지 확인

체크리스트:
- [ ] Homebrew + mise + stow 조합 → Brewfile, mise config.toml 존재
- [ ] Oh My Zsh + Powerlevel10k → .zshrc에 설정
- [ ] Nix 사용 안 함 → Nix 관련 파일 없음
- [ ] .path macOS 경로 → /opt/homebrew 사용
- [ ] .zshrc compinit -C → 반영됨
- [ ] Brewfile 패키지 목록 → Core CLI, Development, Shell, Fonts 포함
- [ ] 초기 세팅 절차 → SETUP.md에 문서화

- [ ] **Step 2: 최종 commit (없으면 skip)**

```bash
# 추가 변경사항이 없으면 skip
```

---

## 완료 후

모든 task 완료 후 다음을 실행하여 Mac mini에 배포:

```bash
# 새 Mac mini에서
cd ~/git/dotfiles
stow -t ~ base eve
```
