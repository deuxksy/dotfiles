#!/usr/bin/env bash
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
    if command -v corepack &>/dev/null; then
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
    else
        echo -e "${YELLOW}✗ corepack not available, skipping pnpm activation${NC}"
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
    local logfile="/tmp/nvimtools_install_$$.log"
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
        local logfile="/tmp/nvimtools_install_$$.log"
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
