# Neovim External Dependencies

## 개요
Neovim 플러그인이 사용하는 외부 도구들

이 문서는 Neovim 플러그인(nvim-lint, conform.nvim, LSP 등)이 사용하는 외부 도구들을 체계적으로 관리하기 위한 가이드입니다.

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

### LSP (Mason - 자동 설치)
lua_ls, ts_ls, pylsp, rust_analyzer, gopls, nil_ls, dockerls, yamlls, terraformls

> **참고:** Mason 플러그인이 `:Mason` 명령으로 자동 설치합니다.

### 기타
| 도구 | 용도 | 필수 여부 | 설치 확인 |
|------|------|----------|----------|
| git | 버전 관리 | 필수 | `git --version` |

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
# nvim-tools.nix 사용 (git 포함됨)
nix-shell ~/git/env/base/.config/nvim/nvim-tools.nix

# 또는 직접 패키지 지정 (git 포함)
nix-shell -p eslint flake8 hadolint yamllint shellcheck \
             stylua prettier black rustfmt go terraform shfmt git
```

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
