# Cross-Platform Neovim Configuration

Windows, macOS, Linux에서 동작하는 Neovim 설정입니다.

## 구조

```
.
├── init.lua              # 진입점 (lazy.nvim 로드)
├── lua/
│   ├── config/           # 설정 파일
│   │   └── lsp_handlers.lua  # LSP 핸들러 공통 설정
│   ├── core/             # 핵심 모듈
│   │   ├── health.lua    # OS 감지
│   │   ├── options.lua   # 기본 옵션
│   │   ├── keymaps.lua   # 글로벌 키매핑
│   │   └── autocmds.lua  # 자동 명령
│   └── plugins/          # 플러그인 설정
│       ├── lsp.lua       # LSP (mason.nvim + nvim-lspconfig)
│       ├── completion.lua# 완료 (nvim-cmp)
│       ├── formatting.lua# 포맷팅 (conform.nvim)
│       ├── linting.lua   # 린팅 (nvim-lint)
│       ├── git.lua       # Git (fugitive + gitsigns)
│       ├── explorer.lua  # 탐색기 (telescope + neo-tree)
│       ├── terminal.lua  # 터미널 (toggleterm)
│       ├── ui.lua        # UI (devicons + lualine)
│       ├── theme.lua     # 테마 (solarized.nvim)
│       └── mason_formatters.lua # 포매터/린터 자동 설치
└── lazy-lock.json        # 의존성 버전 고정
```

## 설치

### 1. Neovim 설치

- **Windows**: `winget install neovim.nvim`
- **macOS**: `brew install neovim`
- **Linux**: 배포판 패키지 매니저로 설치

### 2. 설정 배치

```bash
git clone https://github.com/deuxksy/env.git ~/.config/nvim
```

### 3. 의존성 설치

- **Node.js**: `npm install -g neovim`
- **Python**: `pip install neovim`
- **Rust**: (선택) LSP 서버 설치

### 4. 첫 실행

```bash
nvim
```

`:Lazy sync` 명령어로 플러그인이 자동 설치됩니다.

## 지원 언어

| 언어 | LSP | 포매터 | 린터 |
|------|-----|--------|------|
| Lua | lua_ls | stylua | selene |
| Python | pyright | black | flake8 |
| JavaScript/TypeScript | ts_ls | prettier | eslint_d |
| Rust | rust_analyzer | rustfmt | - |
| Go | gopls | gofmt | - |
| Docker | dockerls | hadolint | hadolint |
| YAML | yamlls | prettier | yamllint |
| Terraform | terraformls | terraform_fmt | tflint |
| Shell | - | shfmt | shellcheck |
| Java | jdtls | google-java-format | - |

## 주요 키매핑

| 키 | 기능 |
|----|------|
| `<leader>ff` | 파일 검색 (telescope) |
| `<leader>fg` | 라이브 그렙 (telescope) |
| `<leader>fb` | 버퍼 목록 (telescope) |
| `<leader>e` | 파일 탐색기 토글 (neo-tree) |
| `<leader>t` | 터미널 토글 (toggleterm) |
| `<leader>mp` | 파일 포맷 (conform) |
| `]c` / `[c` | 다음/이전 Git hunk |
| `gd` | 정의로 이동 |
| `gr` | 참조 검색 |
| `K` | 호버 표시 |
| `<leader>ca` | 코드 액션 |

## 라이선스

MIT
