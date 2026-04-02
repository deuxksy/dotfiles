# Environment Settings (env)

개인적으로 사용하는 플랫폼별 환경 설정 및 관리 스크립트 모음입니다.

## 📂 프로젝트 구조

### 💻 OS별 설정

- **[base](./base)**: 모든 환경 공통 설정 (Git, Vim)
- **[eve](./eve)**: macOS 설정
- **[walle](./walle)**: Fedora 설정
- **[girl](./girl)**: Steam Deck 설정

## 설치

```macOS
brew install stow
```

```SteamOS
brew install stow
```

```Fedora
sudo dnf install stow
```

## 🚀 사용법

GNU Stow를 사용하여 설정 파일을 홈 디렉토리에 심볼릭 링크합니다.

```bash
# 1. 저장소 클론
git clone https://github.com/deuxksy/env.git ~/git/env
cd ~/git/env

# 또는 수동으로 Stow 패키지 적용

stow -t ~ --adopt base # local 에서 공통 설정 가지고 오기
stow -t ~ base         # 공통 설정 적용
stow -t ~ --adopt eve  # lcoal 에서 eve 설정 가지고 오기
stow -t ~ eve          # eve 설정 적용
stow -t ~ base eve     # 공통 과 eve 설정 같이 적용
```

## 📋 Stow 패키지 매핑

| 환경            | 적용 패키지                |
| :------------- | :---------------------- |
| Mac Mini M4    | `base` + `eve`          |
| AOOSTAR WTR R1 | `base` + `walle`        |
| Steam Deck     | `base` + `girl`         |


## Nix

```bash
sudo darwin-rebuild switch --flake ~/.config/nix-darwin#eve
```

---

_Last Updated: 2026-01-15_

## MCP Integration

Neovim에 CodeCompanion.nvim과 mcphub.nvim이 통합되어 있으며, 6개 MCP 서버를 사용할 수 있습니다:

- **Z.AI Vision**: 이미지 분석
- **Z.AI Web Search**: 웹 검색
- **Z.AI Web Reader**: 웹 페이지 읽기
- **Z.AI GitHub**: GitHub 저장소 분석
- **Context7**: 문서 검색
- **Brave Search**: 대체 검색 엔진

### 사용법

```vim
:MCPHub              # MCP Hub UI 열기
:CodeCompanionChat   # AI Chat 열기
```

### 환경변수 설정

~/.key 파일에 다음 환경변수가 필요합니다 (이미 ~/.zshrc에서 source됨):

```bash
export ZAI_API_KEY="sk-..."
export CONTEXT7_API_KEY="..."
export BRAVE_API_KEY="..."
export ANTHROPIC_API_KEY="sk-ant-..."
```

자세한 내용은 [Design Document](docs/superpowers/specs/2026-03-23-nvim-external-dependencies-design.md)와 [Implementation Plan](docs/superpowers/plans/2026-03-23-mcp-neovim-integration.md)를 참고하세요.

## External Dependencies

Neovim 플러그인이 사용하는 외부 도구들이 있습니다. 자세한 내용은 [`DEPENDENCIES.md`](base/.config/nvim/DEPENDENCIES.md)를 참고하세요.

### 빠른 설치

각 OS별로 설치 스크립트를 제공합니다:

```bash
# macOS (Homebrew)
eve/scripts/install_nvtools.sh

# Fedora (dnf)
walle/scripts/install_nvtools.sh

# SteamOS (brew for Linux)
girl/scripts/install_nvtools.sh

# Nix
nix-shell base/.config/nvim/nvim-tools.nix
```

### 포함된 도구

- **Linter:** eslint_d, flake8, hadolint, yamllint, shellcheck
- **Formatter:** stylua, prettier, black, rustfmt, gofmt, terraform_fmt, shfmt
- **LSP:** Mason 플러그인이 자동 설치
- **기타:** git
