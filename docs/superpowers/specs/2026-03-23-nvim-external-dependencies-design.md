# Neovim External Dependencies Management

**작성일:** 2026-03-23
**상태:** Design

## 1. 개요 (Overview)

Neovim 플러그인(Lint, Formatter, LSP 등)이 사용하는 외부 도구들을 OS별(Ubuntu, Fedora, macOS, Nix)로 설치 가능하도록 관리하는 체계를 구축합니다.

### 1.1 목적

- 현재 설치된 nvim 플러그인이 사용하는 외부 의존성을 체계적으로 관리
- 각 OS별 패키지 매니저에서 해당 도구 설치 가능 여부 확인
- 사용자가 일관된 방식으로 의존성 설치 가능

### 1.2 범위

- **포함:** 현재 nvim 플러그인 설정에서 명시적으로 사용하는 외부 도구만
- **제외:** Mason이 자동 설치하는 LSP 서버 (문서에 "자동 설치" 표기만)

## 2. 대상 도구 (Target Tools)

### 2.1 Linter (nvim-lint)

| 도구 | 용도 | 비고 |
|------|------|------|
| eslint_d | JavaScript/TypeScript 린팅 | Node.js 기반 |
| flake8 | Python 린팅 | Python 패키지 |
| hadolint | Dockerfile 린팅 | Haskell 기반 |
| yamllint | YAML 린팅 | Python 패키지 |
| shellcheck | Shell script 린팅 | Haskell 기반 |

### 2.2 Formatter (conform.nvim)

| 도구 | 용도 | 비고 |
|------|------|------|
| stylua | Lua 포맷팅 | Rust 기반 |
| prettier | JS/TS/YAML 포맷팅 | Node.js 기반 |
| black | Python 포맷팅 | Python 패키지 |
| rustfmt | Rust 포맷팅 | Rust 툴체인 |
| gofmt | Go 포맷팅 | Go 툴체인 |
| terraform_fmt | Terraform 포맷팅 | Go 기반 |
| shfmt | Shell script 포맷팅 | Go 기반 |

### 2.3 LSP (Mason - 자동 설치)

lua_ls, ts_ls, pylsp, rust_analyzer, gopls, nil_ls, dockerls, yamlls, terraformls

> **참고:** Mason 플러그인이 자동으로 설치하므로 별도 시스템 설치 불필요

### 2.4 기타 (Common)

| 도구 | 용도 | 필수 여부 |
|------|------|----------|
| git | 버전 관리, fugitive/cmp-git | 필수 |

## 3. 파일 구조 (File Structure)

```
base/.config/nvim/
├── DEPENDENCIES.md              # 공통 문서 (외부 의존성 개요)
├── nvim-tools.nix               # Nix expression
│
eve/scripts/install_nvtools.sh   # macOS + Homebrew
walle/scripts/install_nvtools.sh # Fedora + dnf
girl/scripts/install_nvtools.sh  # SteamOS + pacman
```

### 3.1 파일 책임

**DEPENDENCIES.md:**
- 외부 의존성 개요 및 설명
- 도구 분류별 정리
- 각 OS별 설치 방법 요약
- 패키지 매니저별 패키지명 매핑 표

**nvim-tools.nix:**
- Nix expression으로 정의된 의존성
- `nix-shell` 또는 `nix profile`로 사용 가능

**install_nvtools.sh (각 OS별):**
- 해당 OS의 패키지 매니저 감지
- 설치된 패키지 확인
- 누락된 패키지만 선택적 설치
- `--dry-run` 모드 지원
- 실패 시 계속 진행, 마지막에 요약

## 4. 스크립트 설계 (Script Design)

### 4.1 공통 패턴

각 스크립트는 동일한 구조를 따릅니다:

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

# 도구 목록 (OS별 패키지명)
LINTERS=(...)
FORMATTERS=(...)
OTHERS=(...)

# 함수들
check_package_manager() { ... }
check_installed() { ... }
install_package() { ... }
install_tools() { ... }
print_summary() { ... }
parse_args() { ... }

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

### 4.2 주요 함수

#### 4.2.1 parse_args

```bash
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
                exit 1
                ;;
        esac
    done
}
```

#### 4.2.2 check_installed (OS별 구현)

- **Ubuntu/Debian:** `dpkg -s "$pkg" >/dev/null 2>&1` 또는 `command -v "$pkg"`
- **Fedora/RHEL:** `rpm -q "$pkg" >/dev/null 2>&1`
- **macOS:** `command -v "$pkg"` 또는 `brew list "$pkg" &>/dev/null`
- **Arch:** `pacman -Q "$pkg" &>/dev/null`

#### 4.2.3 install_package

```bash
install_package() {
    local pkg=$1
    local install_cmd=$2

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
    if $install_cmd "$pkg" 2>>"$logfile"; then
        INSTALLED+=("$pkg")
        echo -e "${GREEN}✓ $pkg installed${NC}"
    else
        FAILED+=("$pkg")
        echo -e "${RED}✗ $pkg failed (check $logfile)${NC}"
    fi
    return 0  # 항상 계속 진행
}
```

#### 4.2.4 print_summary

```bash
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
```

### 4.3 실행 순서

```
시작
  ↓
parse_args (--dry-run 확인)
  ↓
check_package_manager (apt/dnf/brew/pacman 감지)
  ↓
─────────────────────────────────────
│ 카테고리별 순회                     │
│  1. Linter (5개)                    │
│  2. Formatter (6개)                 │
│  3. 기타 (git)                      │
│                                     │
│  각 도구마다:                       │
│    1. check_installed              │
│    2. 설치되어 있으면 → skip        │
│    3. 없으면 install_package        │
│    4. dry-run이면 echo만            │
│    5. 실패 시 기록 후 continue      │
─────────────────────────────────────
  ↓
print_summary (성공/실패/스킵 카운트)
  ↓
종료 (exit code: 실패 수만큼)
```

## 5. 멱등성 및 에러 핸들링 (Idempotency & Error Handling)

### 5.1 멱등성 보장

- 이미 설치된 패키지는 `check_installed`로 감지하여 건너뜀
- 스크립트를 여러 번 실행해도 안전 (Idempotent)
- 실패 후 재실행 시 성공한 것은 유지, 실패한 것만 재시도

### 5.2 에러 핸들링 전략

**Continue on Error:**
- 개별 패키지 설치 실패 시 기록 후 계속 진행
- 마지막에 실패 요약을 출력
- Exit code: 실패한 패키지 수 (`exit ${#FAILED[@]}`)

**에러 출력:**
- 표준 에러는 `/dev/null`로 리다이렉션 (2>/dev/null)
- 사용자에게는 성공/실패만 시각적으로 표시

## 6. 문서 형식 (Documentation Format)

### 6.1 DEPENDENCIES.md 구조

```markdown
# Neovim External Dependencies

## 개요
Neovim 플러그인이 사용하는 외부 도구들

## 카테고리별 도구

### Linter (nvim-lint)
| 도구 | 용도 | Ubuntu | Fedora | macOS | Nix |
|------|------|--------|--------|-------|-----|
| eslint_d | JS/TS | eslint | eslint | eslint | nodePackages.eslint |
| flake8 | Python | python3-flake8 | python3-flake8 | flake8 | python3Packages.flake8 |
| hadolint | Dockerfile | hadolint | hadolint | hadolint | hadolint |
| yamllint | YAML | yamllint | yamllint | yamllint | python3Packages.yamllint |
| shellcheck | Shell | shellcheck | shellcheck | shellcheck | shellcheck |

### Formatter (conform.nvim)
| 도구 | 용도 | Ubuntu | Fedora | macOS | Nix |
|------|------|--------|--------|-------|-----|
| stylua | Lua | stylua | stylua | stylua | stylua |
| prettier | JS/TS/YAML | prettier | prettier | prettier | nodePackages.prettier |
| black | Python | black | black | black | python3Packages.black |
| rustfmt | Rust | rustfmt | rustfmt | rustfmt | rustfmt |
| gofmt | Go | golang | golang | go | go |
| terraform_fmt | Terraform | terraform | terraform | terraform | terraform |
| shfmt | Shell | shfmt | shfmt | shfmt | shfmt |

> **참고:** gofmt는 Go 툴체인에 포함된 바이너리 |
| terraform_fmt | Terraform | terraform | terraform | terraform | terraform |
| shfmt | Shell | shfmt | shfmt | shfmt | shfmt |

### LSP (Mason - 자동 설치)
lua_ls, ts_ls, pylsp, rust_analyzer, gopls, nil_ls, dockerls, yamlls, terraformls

> **참고:** Mason 플러그인이 `:Mason` 명령으로 자동 설치합니다.

### 기타
| 도구 | 용도 | 필수 여부 | 설치 확인 |
|------|------|----------|----------|
| git | 버전 관리 | 필수 | `git --version` |

## 설치 방법

### Ubuntu/Debian
\`\`\`bash
# 수동 설치
sudo apt update
sudo apt install -y eslint flake8 hadolint yamllint shellcheck ...

# 또는 스크립트 사용 (준비 중)
\`\`\`

### Fedora
\`\`\`bash
sudo dnf install -y eslint flake8 hadolint yamllint shellcheck ...
\`\`\`

### macOS
\`\`\`bash
brew install eslint flake8 hadolint yamllint shellcheck ...
\`\`\`

### Nix
\`\`\`bash
nix-shell -p eslint flake8 hadolint yamllint shellcheck ...
# 또는 nvim-tools.nix 사용
\`\`\`

## 검증

설치 후 확인:

\`\`\`bash
# nvim 내에서
:LspInfo
:Mason

# 또는 명령행에서
which eslint_d flake8 hadolint yamllint shellcheck
\`\`\`
```

### 6.2 nvim-tools.nix 구조

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
    echo "Available tools: eslint_d, flake8, hadolint, yamllint, shellcheck, ..."
  '';
}
```

## 7. 검증 계획 (Validation Plan)

### 7.1 스크립트 테스트

각 OS별로 다음을 확인:

1. **Dry-run 모드:**
   ```bash
   ./install_nvtools.sh --dry-run
   ```
   - 설치 명령이 표시되기만 하고 실제 설치는 안 되는지 확인

2. **Idempotency:**
   ```bash
   ./install_nvtools.sh
   ./install_nvtools.sh  # 두 번째 실행
   ```
   - 첫 실행: 설치 진행
   - 두 번째 실행: 모두 Skipped로 표시

3. **부분 실패 시나리오:**
   - 존재하지 않는 패키지명을 포함해서 실패 처리 확인
   - 실패 후에도 다른 패키지는 계속 설치되는지 확인

### 7.2 패키지 매니저별 검증

| OS | 패키지 매니저 | 검증 명령어 |
|----|--------------|-------------|
| Ubuntu | apt | `apt list --installed | grep -E '(eslint|flake8|...)` |
| Fedora | dnf | `dnf list installed | grep -E '(eslint|flake8|...)` |
| macOS | brew | `brew list --formula` |
| Arch | pacman | `pacman -Q` |

### 7.3 nvim 내부 검증

nvim 실행 후 확인:

```vim
:LspInfo          " LSP 서버 상태
:Mason            " Mason 패키지 목록
:checkhealth lsp  " LSP 건강 상태 확인
```

## 8. 다음 단계 (Next Steps)

1. **구현 (Implementation)**
   - DEPENDENCIES.md 작성
   - nvim-tools.nix 작성
   - 각 OS별 install_nvtools.sh 작성
   - Ubuntu (apt) → Fedora (dnf) → macOS (brew) → Nix 순서

2. **테스트 (Testing)**
   - 각 OS에서 스크립트 실행 테스트
   - Dry-run 모드 검증
   - 멱등성 검증

3. **문서화 (Documentation)**
   - README.md에 설치 방법 추가
   - 각 OS별 사용법 문서화

**구현 순서:** macOS (Homebrew) → Fedora (dnf) → SteamOS (pacman) → Nix

## 9. 참고 (References)

- Neovim 설정: `base/.config/nvim/`
- 플러그인 설정:
  - Lint: `lua/plugins/linting.lua`
  - Format: `lua/plugins/formatting.lua`
  - LSP: `lua/plugins/lsp.lua`
  - Completion: `lua/plugins/completion.lua`
  - Git: `lua/plugins/git.lua`
  - Explorer: `lua/plugins/explorer.lua`
  - Terminal: `lua/plugins/terminal.lua`
