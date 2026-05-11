# macOS 26 (M4 Mac mini) eve 호스트 설정 설계

- **Date**: 2026-05-11
- **Host**: eve (Mac mini M4, macOS 26 Tahoe)
- **Role**: 개발 워크스테이션 (iOS, Android, DevOps, CLI)

## 아키텍처 결정

| 항목 | 선택 |
| :--- | :--- |
| 패키지 관리 | Homebrew (Brewfile) |
| SDK/런타임 | mise |
| Dotfiles | stow (base + eve 패키지) |
| 셸 | Oh My Zsh + Powerlevel10k |
| Nix | 사용 안 함 (오버테크놀로지) |

## 디렉토리 구조

```
eve/                              # Stow 패키지 (신규)
├── .stow-local-ignore
├── .alias                        # walle과 동일
├── .path                         # macOS 경로 (/opt/homebrew)
├── .zshrc                        # linuxbrew 제거, macOS 26 대응
├── .config/mise/config.toml      # walle과 동일
└── .ssh/config                   # walle과 동일
├── .key                          # sops 암호화 (walle에서 복사)

base/                             # 공통 stow (기존, 변경 없음)
Brewfile                          # 프로젝트 루트에 배치
```

## 셸 설정

### `.path` (walle 대비 변경점)

- `linuxbrew` → `/opt/homebrew`
- podman socket, `OLLAMA_VULKAN`, `GOG_KEYRING_PASSWORD` 제거 (Linux 전용)
- `HISTFILESIZE` → `SAVEHIST` (zsh 네이티브)
- `DOCKER_HOST` 제거

### `.zshrc` (walle 대비 변경점)

- linuxbrew 라인 제거
- `compinit -C` 플래그로 시작 속도 개선
- 나머지 동일 (p10k, oh-my-zsh, zoxide, atuin, mise, sops)

### `.alias`, `.ssh/config`, `mise/config.toml`

walle과 동일.

## Brewfile

필수 CLI + 개발 도구만 포함. GUI 앱, Xcode는 수동 설치.

### Core CLI

git, neovim, tmux, ripgrep, fd, fzf, jq, yq, bat, eza, zoxide, atuin, direnv, gnupg, sops, age, curlie, glow, tealdeer, fastfetch, stow

### Development

mise, kubectl, opentofu, awscli2, pipx, aria2

### Shell

zsh, zsh-completions, zsh-autosuggestions, zsh-syntax-highlighting

### Fonts (Cask)

font-jetbrains-mono-nerd-font

### 수동 설치 항목

- Xcode (App Store)
- Oh My Zsh
- Powerlevel10k
- Claude Code
- Android Studio

## 초기 세팅 절차

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
cd ~/git/dotfiles && stow -t ~ base eve

# 8. mise로 런타임 설치
cd ~ && mise install

# 9. 셸 재시작
exec zsh
```

## 검증 항목

- `eza` → ls 대체 동작
- `nvim` → LazyVim 플러그인 로드
- `mise list` → go, node, python 등 설치 확인
- `p10k configure` → 프롬프트 커스터마이징
