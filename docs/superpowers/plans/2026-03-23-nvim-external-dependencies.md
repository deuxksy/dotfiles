# Neovim External Dependencies Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Neovim 플러그인이 사용하는 외부 도구(Linter, Formatter, LSP)를 OS별로 체계적으로 관리

**Architecture:** 3-Layer 접근 방식 - (1) DEPENDENCIES.md로 공통 문서 관리, (2) nvim-tools.nix로 Nix 표현, (3) 각 OS별 install_nvtools.sh 스크립트로 패키지 자동 설치. 모든 스크립트는 멱등성(Idempotent)을 보장하며, 실패 시에도 계속 진행(Continue on Error)하는 안전한 설치 전략.

**Tech Stack:** Bash, Nix, apt/dnf/brew/pacman

---

## Task 1: 공통 문서 작성 (DEPENDENCIES.md)

**Files:**
- Create: `base/.config/nvim/DEPENDENCIES.md`

- [ ] **Step 1: DEPENDENCIES.md 파일 생성**

```bash
nvim ~/git/env/base/.config/nvim/DEPENDENCIES.md
```

- [ ] **Step 2: 개요 섹션 작성**

```markdown
# Neovim External Dependencies

## 개요
Neovim 플러그인이 사용하는外部 도구들

이 문서는 Neovim 플러그인(nvim-lint, conform.nvim, LSP 등)이 사용하는 외부 도구들을 체계적으로 관리하기 위한 가이드입니다.
```

- [ ] **Step 3: Linter 섹션 작성**

```markdown
## 카테고리별 도구

### Linter (nvim-lint)
| 도구 | 용도 | Fedora | macOS | SteamOS | Nix |
|------|------|--------|-------|---------|-----|
| eslint_d | JavaScript/TypeScript 린팅 | eslint + npm global | eslint + npm global | eslint + npm global | nodePackages.eslint |
| flake8 | Python 린팅 | python3-flake8 | flake8 | python-flake8 | python3Packages.flake8 |
| hadolint | Dockerfile 린팅 | hadolint | hadolint | hadolint | hadolint |
| yamllint | YAML 린팅 | yamllint | yamllint | yamllint | python3Packages.yamllint |
| shellcheck | Shell script 린팅 | shellcheck | shellcheck | shellcheck | shellcheck |

> **참고:** eslint_d는 pnpm global install 필요: `pnpm install -g eslint_d`
```

- [ ] **Step 4: Formatter 섹션 작성**

```markdown
### Formatter (conform.nvim)
| 도구 | 용도 | Fedora | macOS | SteamOS | Nix |
|------|------|--------|-------|---------|-----|
| stylua | Lua 포맷팅 | stylua | stylua | stylua | stylua |
| prettier | JS/TS/YAML 포맷팅 | prettier | prettier | prettier | nodePackages.prettier |
| black | Python 포맷팅 | python3-black | black | python-black | python3Packages.black |
| rustfmt | Rust 포맷팅 | rustfmt | rustfmt | rustfmt | rustfmt |
| gofmt | Go 포맷팅 | golang | go | go | go |
| terraform_fmt | Terraform 포맷팅 | terraform | terraform | terraform | terraform |
| shfmt | Shell script 포맷팅 | shfmt | shfmt | shfmt | shfmt |

> **참고:** gofmt는 Go 툴체인에 포함된 바이너리
```

- [ ] **Step 5: LSP 및 기타 섹션 작성**

```markdown
### LSP (Mason - 자동 설치)
lua_ls, ts_ls, pylsp, rust_analyzer, gopls, nil_ls, dockerls, yamlls, terraformls

> **참고:** Mason 플러그인이 `:Mason` 명령으로 자동 설치합니다.

### 기타
| 도구 | 용도 | 필수 여부 | 설치 확인 |
|------|------|----------|----------|
| git | 버전 관리 | 필수 | `git --version` |
```

- [ ] **Step 6: 설치 방법 섹션 작성**

```markdown
## 설치 방법

### Fedora (dnf)
```bash
# Linter
sudo dnf install -y eslint python3-flake8 hadolint yamllint shellcheck
# Formatter
sudo dnf install -y stylua prettier python3-black rustfmt golang terraform shfmt
# 기타
sudo dnf install -y git

# eslint_d는 pnpm global install 필요
pnpm install -g eslint_d
```

### macOS (Homebrew)
```bash
# Linter
brew install eslint flake8 hadolint yamllint shellcheck
# Formatter
brew install stylua prettier black rustfmt go terraform shfmt
# 기타
brew install git

# eslint_d는 pnpm global install 필요
pnpm install -g eslint_d
```

### SteamOS (pacman)
```bash
# Linter
sudo pacman -S --noconfirm eslint python-flake8 hadolint yamllint shellcheck
# Formatter
sudo pacman -S --noconfirm stylua prettier python-black rustfmt go terraform shfmt
# 기타
sudo pacman -S --noconfirm git

# eslint_d는 pnpm global install 필요
pnpm install -g eslint_d
```

### Nix
```bash
# nvim-tools.nix 사용
nix-shell ~/git/env/base/.config/nvim/nvim-tools.nix

# 또는 직접 패키지 지정
nix-shell -p eslint flake8 hadolint yamllint shellcheck \
             stylua prettier black rustfmt go terraform shfmt git
```
```

- [ ] **Step 7: 검증 섹션 작성**

```markdown
## 검증

설치 후 확인:

```bash
# nvim 내에서
:LspInfo
:Mason

# 명령행에서 바이너리 확인
which eslint_d flake8 hadolint yamllint shellcheck
which stylua prettier black rustfmt gofmt terraform shfmt
which git

# eslint_d는 npm global로 설치되므로 별도 확인
npm list -g eslint_d
```
```

- [ ] **Step 8: Commit**

```bash
git add base/.config/nvim/DEPENDENCIES.md
git commit -m "docs: Neovim 외부 의존성 문서 추가"
```

---

## Task 2: Nix Expression 작성 (nvim-tools.nix)

**Files:**
- Create: `base/.config/nvim/nvim-tools.nix`

- [ ] **Step 1: nvim-tools.nix 파일 생성**

```bash
nvim ~/git/env/base/.config/nvim/nvim-tools.nix
```

- [ ] **Step 2: Nix expression 작성**

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Linter
    nodePackages.eslint
    python3Packages.flake8
    hadolint
    python3Packages.yamllint
    shellcheck

    # Formatter
    stylua
    nodePackages.prettier
    python3Packages.black
    rustfmt
    go
    terraform
    shfmt

    # 기타
    git
  ];

  shellHook = ''
    echo "Neovim tools environment loaded"
    echo "Available tools: eslint_d, flake8, hadolint, yamllint, shellcheck"
    echo "                 stylua, prettier, black, rustfmt, gofmt, terraform_fmt, shfmt"
  '';
}
```

- [ ] **Step 3: Nix 문법 검증**

```bash
nix-instantiate --eval ~/git/env/base/.config/nvim/nvim-tools.nix
```

Expected: 문법 오류 없음

- [ ] **Step 4: Nix-shell 테스트**

```bash
cd ~/git/env
nix-shell base/.config/nvim/nvim-tools.nix
```

Expected: shell이 열리고 도구들이 PATH에 있음

- [ ] **Step 5: Commit**

```bash
git add base/.config/nvim/nvim-tools.nix
git commit -m "feat: Nix expression for Neovim tools 추가"
```

---

## Task 3: macOS 설치 스크립트 작성 (eve/scripts/install_nvtools.sh)

**Files:**
- Create: `eve/scripts/install_nvtools.sh`

- [ ] **Step 1: scripts 디렉토리 확인**

```bash
mkdir -p ~/git/env/eve/scripts
```

- [ ] **Step 2: install_nvtools.sh 파일 생성**

```bash
nvim ~/git/env/eve/scripts/install_nvtools.sh
chmod +x ~/git/env/eve/scripts/install_nvtools.sh
```

- [ ] **Step 3: 스크립트 헤더 및 공통 설정 작성**

```bash
#!/bin/bash
set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Dry-run 모드
DRY_RUN=false

# 상태 추적
INSTALLED=()
FAILED=()
SKIPPED=()
```

- [ ] **Step 4: 도구 목록 정의 (macOS Homebrew)**

```bash
# 도구 목록 (Homebrew 패키지명)
declare -A LINTERS=(
    [eslint]="eslint"
    [flake8]="flake8"
    [hadolint]="hadolint"
    [yamllint]="yamllint"
    [shellcheck]="shellcheck"
)

declare -A FORMATTERS=(
    [stylua]="stylua"
    [prettier]="prettier"
    [black]="black"
    [rustfmt]="rustfmt"
    [gofmt]="go"  # go 툴체인에 포함
    [terraform_fmt]="terraform"
    [shfmt]="shfmt"
)

declare -A OTHERS=(
    [git]="git"
)
```

- [ ] **Step 5: 함수 구현**

```bash
# 도움말 표시
show_help() {
    echo "Usage: $0 [--dry-run] [--help]"
    echo ""
    echo "Options:"
    echo "  --dry-run    설치 명령을 표시만 하고 실행하지 않음"
    echo "  --help       이 도움말 표시"
    echo ""
    echo "이 스크립트는 Neovim 플러그인이 사용하는 외부 도구들을 설치합니다."
    exit 0
}

# 인자 파싱
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage"
                exit 1
                ;;
        esac
    done
}

# 패키지 매니저 확인 (Homebrew + pnpm)
check_package_manager() {
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}Error: Homebrew not found${NC}"
        echo "Please install Homebrew: https://brew.sh"
        exit 1
    fi
    echo -e "${GREEN}✓ Homebrew detected${NC}"

    # pnpm 활성화 (corepack 사용)
    if ! command -v pnpm &> /dev/null; then
        echo -e "${YELLOW}pnpm not found, activating via corepack...${NC}"
        if corepack enable &>/dev/null && corepack prepare pnpm@latest --activate &>/dev/null; then
            echo -e "${GREEN}✓ pnpm activated${NC}"
        else
            echo -e "${YELLOW}✗ pnpm activation failed, npm fallback will be used${NC}"
        fi
    else
        echo -e "${GREEN}✓ pnpm detected${NC}"
    fi
}

# 패키지 설치 확인
check_installed() {
    local pkg=$1

    if brew list "$pkg" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 패키지 설치
install_package() {
    local pkg=$1

    if check_installed "$pkg"; then
        SKIPPED+=("$pkg")
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would install: $pkg"
        SKIPPED+=("$pkg (dry-run)")
        return 0
    fi

    echo -e "${YELLOW}Installing $pkg...${NC}"
    local logfile="/tmp/nvimtools_install.log"
    if brew install "$pkg" &>>"$logfile"; then
        INSTALLED+=("$pkg")
        echo -e "${GREEN}✓ $pkg installed${NC}"
    else
        FAILED+=("$pkg")
        echo -e "${RED}✗ $pkg failed (check $logfile)${NC}"
    fi
    return 0  # 항상 계속 진행
}

# 도구들 설치
install_tools() {
    echo ""
    echo "========================================="
    echo "Installing Neovim External Dependencies"
    echo "========================================="
    echo ""

    # Linter
    echo "Installing Linters..."
    for tool in "${!LINTERS[@]}"; do
        install_package "${LINTERS[$tool]}"
    done

    # Formatter
    echo ""
    echo "Installing Formatters..."
    for tool in "${!FORMATTERS[@]}"; do
        install_package "${FORMATTERS[$tool]}"
    done

    # 기타
    echo ""
    echo "Installing Other Tools..."
    for tool in "${!OTHERS[@]}"; do
        install_package "${OTHERS[$tool]}"
    done

    # eslint_d 별도 설치 (pnpm global)
    echo ""
    echo "Installing eslint_d via pnpm..."
    if command -v eslint_d &>/dev/null; then
        echo -e "${YELLOW}✓ eslint_d already installed${NC}"
    elif [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would install: eslint_d (via pnpm)"
    else
        local logfile="/tmp/nvimtools_install.log"
        if pnpm install -g eslint_d &>>"$logfile"; then
            INSTALLED+=("eslint_d (pnpm)")
            echo -e "${GREEN}✓ eslint_d installed${NC}"
        else
            FAILED+=("eslint_d (pnpm)")
            echo -e "${RED}✗ eslint_d failed (check $logfile)${NC}"
        fi
    fi
}

# 요약 출력
print_summary() {
    echo ""
    echo "========================================="
    echo "Install Summary"
    echo "========================================="

    echo -e "${GREEN}Installed (${#INSTALLED[@]}):${NC}"
    printf '  - %s\n' "${INSTALLED[@]:-None}"

    echo -e "${YELLOW}Skipped (${#SKIPPED[@]}):${NC}"
    printf '  - %s\n' "${SKIPPED[@]:-None}"

    if [ ${#FAILED[@]} -gt 0 ]; then
        echo -e "${RED}Failed (${#FAILED[@]}):${NC}"
        printf '  - %s\n' "${FAILED[@]}"
    fi

    echo "========================================="
}

# 메인
main() {
    parse_args "$@"
    check_package_manager
    install_tools
    print_summary
    exit ${#FAILED[@]}
}

main "$@"
```

- [ ] **Step 6: Bash 문법 검증**

```bash
shellcheck ~/git/env/eve/scripts/install_nvtools.sh
```

Expected: 문법 오류 없음

- [ ] **Step 7: Dry-run 테스트**

```bash
~/git/env/eve/scripts/install_nvtools.sh --dry-run
```

Expected: 설치 명령만 표시되고 실제 설치는 안 됨

- [ ] **Step 8: Commit**

```bash
git add eve/scripts/install_nvtools.sh
git commit -m "feat: macOS Homebrew 설치 스크립트 추가"
```

---

## Task 4: Fedora 설치 스크립트 작성 (walle/scripts/install_nvtools.sh)

**Files:**
- Create: `walle/scripts/install_nvtools.sh`

- [ ] **Step 1: 스크립트 생성 (macOS 버전 복사)**

```bash
mkdir -p ~/git/env/walle/scripts
cp ~/git/env/eve/scripts/install_nvtools.sh ~/git/env/walle/scripts/install_nvtools.sh
chmod +x ~/git/env/walle/scripts/install_nvtools.sh
```

- [ ] **Step 2: dnf로 패키지명 수정**

```bash
nvim ~/git/env/walle/scripts/install_nvtools.sh
```

다음 부분을 수정:

```bash
# 패키지 매니저 확인 (dnf)
check_package_manager() {
    if ! command -v dnf &> /dev/null; then
        echo -e "${RED}Error: dnf not found${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ dnf detected${NC}"

    # pnpm 활성화 (corepack 사용)
    if ! command -v pnpm &> /dev/null; then
        echo -e "${YELLOW}pnpm not found, activating via corepack...${NC}"
        if corepack enable &>/dev/null && corepack prepare pnpm@latest --activate &>/dev/null; then
            echo -e "${GREEN}✓ pnpm activated${NC}"
        else
            echo -e "${YELLOW}✗ pnpm activation failed, npm fallback will be used${NC}"
        fi
    else
        echo -e "${GREEN}✓ pnpm detected${NC}"
    fi
}

# 패키지 설치 확인
check_installed() {
    local pkg=$1

    if rpm -q "$pkg" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 패키지 설치
install_package() {
    local pkg=$1

    if check_installed "$pkg"; then
        SKIPPED+=("$pkg")
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would install: $pkg"
        SKIPPED+=("$pkg (dry-run)")
        return 0
    fi

    echo -e "${YELLOW}Installing $pkg...${NC}"
    local logfile="/tmp/nvimtools_install.log"
    if sudo dnf install -y "$pkg" &>>"$logfile"; then
        INSTALLED+=("$pkg")
        echo -e "${GREEN}✓ $pkg installed${NC}"
    else
        FAILED+=("$pkg")
        echo -e "${RED}✗ $pkg failed (check $logfile)${NC}"
    fi
    return 0
}
```

- [ ] **Step 3: Fedora 패키지명으로 업데이트**

```bash
# 도구 목록 (dnf 패키지명)
declare -A LINTERS=(
    [eslint]="eslint"
    [flake8]="python3-flake8"
    [hadolint]="hadolint"
    [yamllint]="yamllint"
    [shellcheck]="shellcheck"
)

declare -A FORMATTERS=(
    [stylua]="stylua"
    [prettier]="prettier"
    [black]="python3-black"
    [rustfmt]="rustfmt"
    [gofmt]="golang"  # golang 툴체인에 포함
    [terraform_fmt]="terraform"
    [shfmt]="shfmt"
)

declare -A OTHERS=(
    [git]="git"
)
```

- [ ] **Step 3.5: install_tools 함수에 eslint_d 설치 추가**

Task 3의 Step 5와 동일하게 install_tools 함수 마지막에 eslint_d 설치 로직을 추가합니다.

```bash
# install_tools 함수 끝에 추가:
    # eslint_d 별도 설치 (pnpm global)
    echo ""
    echo "Installing eslint_d via pnpm..."
    if command -v eslint_d &>/dev/null; then
        echo -e "${YELLOW}✓ eslint_d already installed${NC}"
    elif [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would install: eslint_d (via pnpm)"
    else
        local logfile="/tmp/nvimtools_install.log"
        if pnpm install -g eslint_d &>>"$logfile"; then
            INSTALLED+=("eslint_d (pnpm)")
            echo -e "${GREEN}✓ eslint_d installed${NC}"
        else
            FAILED+=("eslint_d (pnpm)")
            echo -e "${RED}✗ eslint_d failed (check $logfile)${NC}"
        fi
    fi
```

- [ ] **Step 4: Commit**

```bash
git add walle/scripts/install_nvtools.sh
git commit -m "feat: Fedora dnf 설치 스크립트 추가"
```

---

## Task 5: SteamOS 설치 스크립트 작성 (girl/scripts/install_nvtools.sh)

**Files:**
- Create: `girl/scripts/install_nvtools.sh`

- [ ] **Step 1: 스크립트 생성**

```bash
mkdir -p ~/git/env/girl/scripts
cp ~/git/env/eve/scripts/install_nvtools.sh ~/git/env/girl/scripts/install_nvtools.sh
chmod +x ~/git/env/girl/scripts/install_nvtools.sh
```

- [ ] **Step 2: brew(linux)으로 수정**

```bash
nvim ~/git/env/girl/scripts/install_nvtools.sh
```

다음 부분을 수정:

```bash
# 패키지 매니저 확인 (brew for Linux)
check_package_manager() {
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}Error: brew not found${NC}"
        echo "Please install Homebrew for Linux: https://brew.sh"
        exit 1
    fi
    echo -e "${GREEN}✓ brew detected${NC}"

    # pnpm 체크 및 설치
    if ! command -v pnpm &> /dev/null; then
        echo -e "${YELLOW}Warning: pnpm not found${NC}"
        echo "Installing pnpm via npm..."
        if npm install -g pnpm &>/dev/null; then
            echo -e "${GREEN}✓ pnpm installed${NC}"
        else
            echo -e "${RED}✗ pnpm installation failed${NC}"
            echo "Please install pnpm: npm install -g pnpm"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ pnpm detected${NC}"
    fi
}

# 패키지 설치 확인
check_installed() {
    local pkg=$1

    if brew list "$pkg" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 패키지 설치
install_package() {
    local pkg=$1

    if check_installed "$pkg"; then
        SKIPPED+=("$pkg")
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would install: $pkg"
        SKIPPED+=("$pkg (dry-run)")
        return 0
    fi

    echo -e "${YELLOW}Installing $pkg...${NC}"
    local logfile="/tmp/nvimtools_install.log"
    if brew install "$pkg" &>>"$logfile"; then
        INSTALLED+=("$pkg")
        echo -e "${GREEN}✓ $pkg installed${NC}"
    else
        FAILED+=("$pkg")
        echo -e "${RED}✗ $pkg failed (check $logfile)${NC}"
    fi
    return 0
}
```

- [ ] **Step 3: brew 패키지명으로 업데이트**

```bash
# 도구 목록 (brew 패키지명 - macOS와 동일)
declare -A LINTERS=(
    [eslint]="eslint"
    [flake8]="flake8"
    [hadolint]="hadolint"
    [yamllint]="yamllint"
    [shellcheck]="shellcheck"
)

declare -A FORMATTERS=(
    [stylua]="stylua"
    [prettier]="prettier"
    [black]="black"
    [rustfmt]="rustfmt"
    [gofmt]="go"  # go 툴체인에 포함
    [terraform_fmt]="terraform"
    [shfmt]="shfmt"
)

declare -A OTHERS=(
    [git]="git"
)
```

- [ ] **Step 3.5: install_tools 함수에 eslint_d 설치 추가**

Task 3과 Task 4와 동일하게 install_tools 함수 마지막에 eslint_d 설치 로직을 추가합니다.

```bash
# install_tools 함수 끝에 추가:
    # eslint_d 별도 설치 (pnpm global)
    echo ""
    echo "Installing eslint_d via pnpm..."
    if command -v eslint_d &>/dev/null; then
        echo -e "${YELLOW}✓ eslint_d already installed${NC}"
    elif [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would install: eslint_d (via pnpm)"
    else
        local logfile="/tmp/nvimtools_install.log"
        if pnpm install -g eslint_d &>>"$logfile"; then
            INSTALLED+=("eslint_d (pnpm)")
            echo -e "${GREEN}✓ eslint_d installed${NC}"
        else
            FAILED+=("eslint_d (pnpm)")
            echo -e "${RED}✗ eslint_d failed (check $logfile)${NC}"
        fi
    fi
```

- [ ] **Step 4: Commit**

```bash
git add girl/scripts/install_nvtools.sh
git commit -m "feat: SteamOS pacman 설치 스크립트 추가"
```

---

## Task 6: README 업데이트

**Files:**
- Modify: `README.md`

- [ ] **Step 1: External Dependencies 섹션 추가**

```bash
cat >> ~/git/env/README.md << 'EOF'

## External Dependencies

Neovim 플러그인이 사용하는 외부 도구들이 있습니다. 자세한 내용은 [`DEPENDENCIES.md`](base/.config/nvim/DEPENDENCIES.md)를 참고하세요.

### 빠른 설치

각 OS별로 설치 스크립트를 제공합니다:

```bash
# macOS (Homebrew)
eve/scripts/install_nvtools.sh

# Fedora (dnf)
walle/scripts/install_nvtools.sh

# SteamOS (pacman)
girl/scripts/install_nvtools.sh

# Nix
nix-shell base/.config/nvim/nvim-tools.nix
```

### 포함된 도구

- **Linter:** eslint_d, flake8, hadolint, yamllint, shellcheck
- **Formatter:** stylua, prettier, black, rustfmt, gofmt, terraform_fmt, shfmt
- **LSP:** Mason 플러그인이 자동 설치
- **기타:** git
EOF
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: External Dependencies 설치 방법 추가"
```

---

## Task 7: macOS에서 스크립트 테스트 (eve)

**Files:**
- N/A

- [ ] **Step 1: Dry-run 모드 테스트**

```bash
~/git/env/eve/scripts/install_nvtools.sh --dry-run
```

Expected: "[DRY-RUN] Would install: ..." 메시지 출력

- [ ] **Step 2: Idempotency 테스트 (첫 실행)**

```bash
~/git/env/eve/scripts/install_nvtools.sh
```

Expected: 일부 도구 설치됨, Skipped/Installed 요약 표시

- [ ] **Step 3: Idempotency 테스트 (두 번째 실행)**

```bash
~/git/env/eve/scripts/install_nvtools.sh
```

Expected: 모든 도구 Skipped 표시 (이미 설치됨)

---

## Task 8: Fedora/SteamOS 스크립트 테스트 (walle, girl)

**Files:**
- N/A

- [ ] **Step 1: Fedora에서 Dry-run 테스트**

```bash
# walle (Fedora)
~/git/env/walle/scripts/install_nvtools.sh --dry-run
```

Expected: 설치 명령만 표시

- [ ] **Step 2: SteamOS에서 Dry-run 테스트**

```bash
# girl (SteamOS)
~/git/env/girl/scripts/install_nvtools.sh --dry-run
```

Expected: 설치 명령만 표시

---

## Task 9: Nix-shell 테스트

**Files:**
- N/A

- [ ] **Step 1: Nix-shell 테스트**

```bash
cd ~/git/env
nix-shell base/.config/nvim/nvim-tools.nix
```

Expected: shell이 열리고 도구들이 사용 가능

- [ ] **Step 2: 도구 사용 가능 확인**

```bash
# nix-shell 내에서
which eslint_d flake8 hadolint yamllint shellcheck
which stylua prettier black rustfmt gofmt terraform_fmt shfmt
```

Expected: 모든 도구 PATH에 있음

---

## Task 10: 최종 검증

**Files:**
- N/A

- [ ] **Step 1: Neovim 내부 검증**

```vim
:LspInfo
:Mason
```

Expected: LSP 서버 상태 정상

- [ ] **Step 2: Linter/Formatter 기능 테스트**

```vim
# JavaScript 파일 열어서 :Eslint_d 검사
# Python 파일 열어서 :Flake8 검사
# Lua 파일 열어서 :Stylua 포맷팅
```

Expected: 각 도구가 정상 작동

- [ ] **Step 3: 문서 완전성 확인**

```bash
grep -E "(eslint|flake8|hadolint|yamllint|shellcheck)" ~/git/env/base/.config/nvim/DEPENDENCIES.md
```

Expected: 모든 도구가 문서에 포함됨

---

## Testing Strategy

### Unit Tests (각 Task 내에서 수행)
- Bash 문법 검증 (shellcheck)
- Nix 문법 검증 (nix-instantiate)
- 개별 스크립트 Dry-run 테스트

### Integration Tests
- 각 OS별 스크립트 실행 테스트
- Nix-shell 환경 테스트
- Neovim 플러그ین 연동 테스트

### Idempotency Tests
- 첫 실행: 일부 도구 설치
- 두 번째 실행: 모두 Skipped
- 실패 후 재실행: 성공한 것 유지, 실패한 것만 재시도

---

## Completion Criteria

- [ ] DEPENDENCIES.md 작성 완료
- [ ] nvim-tools.nix 작성 완료
- [ ] macOS 설치 스크립트 작성 완료
- [ ] Fedora 설치 스크립트 작성 완료
- [ ] SteamOS 설치 스크립트 작성 완료
- [ ] README 업데이트 완료
- [ ] macOS에서 스크립트 테스트 완료
- [ ] Fedora/SteamOS 스크립트 테스트 완료
- [ ] Nix-shell 테스트 완료
- [ ] 최종 검증 완료

---

_작성일: 2026-03-23_
_상태: Implementation Plan Ready_
_다음 단계: Plan Review_
