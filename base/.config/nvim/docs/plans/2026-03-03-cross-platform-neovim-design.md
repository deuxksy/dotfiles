# 크로스 플랫폼 Neovim 설정 디자인 문서

**날짜:** 2026-03-03
**목표:** Windows, macOS, Fedora, Ubuntu, SteamOS에서 모두 작동하는 모듈화된 Neovim 설정

---

## 1. 개요

### 1.1 목표
- 다중 OS 지원 (Windows, macOS, Linux)
- 모듈화된 구조로 유지보수성 향상
- 필수 + 개발 생산성 향상 기능 포함 (Balanced 복잡도)
- 활발히 유지보수되는 현대적 플러그인 생태계 사용

### 1.2 지원 언어 및 기술
- JavaScript/TypeScript
- Python
- Rust
- Go
- Java
- Lua
- Docker/Podman
- YAML
- Terraform
- Git

---

## 2. 프로젝트 구조

```
~/.config/nvim/
├── init.lua                    # 진입점, 모듈 로드
├── lazy-lock.json              # 플러그인 버전 고정 (크로스 플랫폼 일관성)
└── lua/
    ├── core/
    │   ├── options.lua         # 기본 옵션
    │   ├── keymaps.lua         # 글로벌 키매핑
    │   ├── autocmds.lua        # 자동 명령
    │   └── health.lua          # OS 감지 및 유틸리티
    ├── plugins/
    │   ├── completion.lua      # nvim-cmp 설정
    │   ├── formatting.lua      # conform.nvim 설정
    │   ├── linting.lua         # nvim-lint 설정
    │   ├── lsp.lua             # LSP 설정 (mason + lspconfig)
    │   ├── git.lua             # fugitive + gitsigns
    │   ├── explorer.lua        # telescope + neo-tree
    │   ├── terminal.lua        # toggleterm
    │   ├── theme.lua           # colorscheme
    │   └── ui.lua              # lualine + devicons
    └── config/
        └── lsp_handlers.lua    # LSP 공통 핸들러 (formatting, keymaps 등)
```

---

## 3. 플러그인 구성

### 3.1 Core
| 플러그인 | 용도 |
|----------|------|
| `lazy.nvim` | 플러그인 매니저 |
| `nvim-web-devicons` | 아이콘 지원 |

### 3.2 Completion
| 플러그인 | 용도 |
|----------|------|
| `nvim-cmp` | 코드 완성 엔진 |
| `cmp-lsp` | LSP 완성 소스 |
| `cmp-buffer` | 버퍼 완성 |
| `cmp-path` | 경로 완성 |
| `cmp-cmdline` | 명령행 완성 |
| `cmp-git` | Git 완성 |

### 3.3 Formatting & Linting
| 플러그인 | 용도 |
|----------|------|
| `conform.nvim` | 코드 포맷터 |
| `nvim-lint` | Linter |

### 3.4 LSP
| 플러그인 | 용도 |
|----------|------|
| `mason.nvim` | LSP/포매터/린터 매니저 |
| `mason-lspconfig.nvim` | Mason-LSP 연결 |
| `nvim-lspconfig` | LSP 설정 |

### 3.5 Git
| 플러그인 | 용도 |
|----------|------|
| `vim-fugitive` | Git 명령 |
| `gitsigns.nvim` | Git 변경 사항 표시 |

### 3.6 Explorer
| 플러그인 | 용도 |
|----------|------|
| `telescope.nvim` | 퍼지 파일inder |
| `telescope-fzf-native.nvim` | FZF 네이티브 속도 |
| `neo-tree.nvim` | 파일 트리 |

### 3.7 Terminal
| 플러그인 | 용도 |
|----------|------|
| `toggleterm.nvim` | 터미널 토글 |

### 3.8 UI
| 플러그인 | 용도 |
|----------|------|
| `lualine.nvim` | 상태줄 |
| `solarized.nvim` | 테마 |
| `nvim-treesitter` | 구문 강조 |

---

## 4. LSP 및 언어 지원

### 4.1 Mason 설치 목록

| 언어/기술 | LSP 서버 | 포매터 | Linter |
|-----------|----------|--------|--------|
| **Lua** | `lua_ls` | stylua | selene |
| **JavaScript/TypeScript** | `ts_ls` | prettier | eslint_d |
| **Python** | `pylsp` / `pyright` | black | flake8 |
| **Rust** | `rust_analyzer` | rustfmt | clippy |
| **Go** | `gopls` | gofmt | golangci-lint |
| **Java** | `jdtls` | google-java-format | checkstyle |
| **Docker/Podman** | `dockerls` | hadolint | - |
| **YAML** | `yamlls` | prettier | yamllint |
| **Terraform** | `terraformls` | terraform fmt | tflint |
| **Git** | - | - | gitlint |

### 4.2 LSP 공통 핸들러
- `on_attach`: 버퍼별 키매핑 자동 설정
- `capabilities`: `nvim-cmp`와 연동
- Format on demand (저장 시 자동 포맷은 conform.nvim이 담당)

---

## 5. 키매핑

### 5.1 Leader 키
- Space (`<leader>`)

### 5.2 네비게이션
| 키 | 동작 |
|----|------|
| `<C-h>` | 창 왼쪽 |
| `<C-j>` | 창 아래 |
| `<C-k>` | 창 위 |
| `<C-l>` | 창 오른쪽 |

### 5.3 터미널
| 키 | 동작 |
|----|------|
| `<leader>t` | 터미널 토글 |
| `<Esc>` (터미널 모드) | 터미널 모드 탈출 |

### 5.4 Telescope
| 키 | 동작 |
|----|------|
| `<leader>ff` | 파일 찾기 |
| `<leader>fg` | 라이브 그렙 |
| `<leader>fb` | 버퍼 찾기 |

### 5.5 Neo-tree
| 키 | 동작 |
|----|------|
| `<leader>e` | 파일 트리 토글 |

### 5.6 Git
| 키 | 동작 |
|----|------|
| `<leader>gs` | Git 상태 |
| `<leader>gb` | Git 블레임 |

### 5.7 LSP (버퍼별)
| 키 | 동작 |
|----|------|
| `K` | 호버 표시 |
| `gd` | 정의로 이동 |
| `gr` | 참조 찾기 |
| `gi` | 구현으로 이동 |
| `<leader>rn` | 이름 변경 |
| `<leader>ca` | 코드 액션 |

---

## 6. 크로스 플랫폼 고려사항

### 6.1 OS 감지 (`lua/core/health.lua`)

```lua
local M = {}

M.is_windows = vim.loop.os_uname().version:find("Windows") ~= nil
M.is_mac = vim.loop.os_uname().sysname == "Darwin"
M.is_linux = vim.loop.os_uname().sysname == "Linux"

M.path_sep = M.is_windows and "\\" or "/"

-- 클립보드 설정
if M.is_windows or M.is_mac then
    vim.opt.clipboard = "unnamed"
else  -- Linux Wayland
    vim.opt.clipboard = "unnamedplus"
end

-- Shell 설정
if M.is_windows then
    vim.opt.shell = "pwsh"  -- PowerShell 7
    vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    vim.opt.shellquote = '"'
    vim.opt.shellxquote = ""
else  -- macOS/Linux
    vim.opt.shell = "zsh"
end

return M
```

### 6.2 플랫폼별 설정

| 항목 | Windows | macOS | Linux (Fedora/Ubuntu/SteamOS) |
|------|---------|-------|-------------------------------|
| **lazy-lock.json** | ✅ 버전 고정 | ✅ 버전 고정 | ✅ 버전 고정 |
| **플러그인 경로** | `~/AppData/Local/nvim-data/` | `~/.local/share/nvim/` | `~/.local/share/nvim/` |
| **clipboard** | 내장 | 내장 | `wl-paste` (Wayland) |
| **shell** | `pwsh` (PowerShell 7) | `zsh` | `zsh` |
| **terminal** | `pwsh` | `zsh` | `zsh` |

### 6.3 의존성 설치

**Windows:**
- PowerShell 7 설치 필요
- Windows Terminal (선택, 권장)

**macOS:**
```bash
brew install zsh
```

**Linux (Fedora):**
```bash
sudo dnf install wl-clipboard zsh
```

**Linux (Ubuntu):**
```bash
sudo apt install wl-clipboard zsh
```

**SteamOS:**
- Wayland 기반이므로 `wl-clipboard`가 이미 설치되어 있을 수 있음
```bash
sudo steamos-readonly disable
sudo pacman -S wl-clipboard zsh
sudo steamos-readonly enable
```

---

## 7. 테스트된 환경

| OS | 터미널 | Shell |
|----|--------|-------|
| Windows 11 | Windows Terminal 1.23.20211.0 | PowerShell 7.5.4 |
| macOS | Terminal.app / iTerm2 | zsh |
| Fedora | GNOME Terminal | zsh |
| Ubuntu | GNOME Terminal | zsh |
| SteamOS | SteamOS Terminal | zsh |

---

## 8. 다음 단계

이 디자인을 바탕으로 구현 계획을 작성합니다. (`writing-plans` 스킬 호출)
