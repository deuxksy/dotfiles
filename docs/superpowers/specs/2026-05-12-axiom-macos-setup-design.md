# macOS 26 (M1 Max Mac Studio) axiom 호스트 설정 설계

- **Date**: 2026-05-12
- **Host**: axiom (Mac Studio M1 Max, 64GB, 512GB, macOS 26)
- **Role**: 개발 워크스테이션 + Local LLM 서버

## 아키텍처 결정

| 항목 | 선택 |
| :--- | :--- |
| 패키지 관리 | Homebrew (Brewfile) |
| SDK/런타임 | mise |
| Dotfiles | stow (base + axiom 패키지) |
| 셸 | Oh My Zsh + Powerlevel10k |
| Nix | 사용 안 함 |
| LLM | 사용자 직접 설정 (LM Studio, MLX) |

## 디렉토리 구조

```
axiom/                            # Stow 패키지 (eve 복사 기반)
├── .stow-local-ignore
├── .alias                        # eve와 동일
├── .path                         # eve와 동일 (/opt/homebrew)
├── .zshrc                        # eve와 동일
├── .config/mise/config.toml      # eve와 동일
├── .ssh/config                   # eve와 동일
└── .key                          # sops 암호화 (eve에서 복사)

base/                             # 공통 stow (기존, 변경 없음)
Brewfile                          # 프로젝트 루트에 배치
```

## 셸 설정

### `.path`, `.zshrc`, `.alias`, `.ssh/config`, `mise/config.toml`

eve와 동일. (자세한 내용은 `2026-05-11-eve-macos-setup-design.md` 참조)

## Brewfile

eve와 동일한 구성. (자세한 내용은 eve 문서 참조)

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
- LM Studio (LLM용)
- MLX (LLM용)

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
cd ~/git/dotfiles && stow -t ~ base axiom

# 8. mise로 런타임 설치
cd ~ && mise install

# 9. 셸 재시작
exec zsh
```

## 호스트 차이점

| 항목 | eve (Mac mini M4) | axiom (Mac Studio M1 Max) |
| :--- | :--- | :--- |
| 메모리 | 16GB | 64GB |
| 주 역할 | iOS/AOS 개발 | Local LLM + 개발 |
| LLM | - | LM Studio, MLX (사용자 설정) |

## 검증 항목

- `eza` → ls 대체 동작
- `nvim` → LazyVim 플러그인 로드
- `mise list` → go, node, python 등 설치 확인
- `p10k configure` → 프롬프트 커스터마이징
