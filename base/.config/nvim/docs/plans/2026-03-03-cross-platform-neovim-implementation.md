# 크로스 플랫폼 Neovim 설정 구현 계획

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Windows, macOS, Linux(Fedora/Ubuntu/SteamOS)에서 모두 작동하는 모듈화된 Neovim 설정 구축

**Architecture:** lazy.nvim을 플러그인 매니저로 사용하며, lua/ 디렉토리에 기능별 모듈(options, keymaps, plugins, config)로 분리하여 유지보수성을 확보. Mason으로 LSP/포매터/린터를 관리하고, nvim-cmp로 코드 완성, conform.nvim으로 포맷팅, nvim-lint로 린팅을 처리.

**Tech Stack:** Neovim 0.10+, Lua, lazy.nvim, nvim-cmp, conform.nvim, nvim-lint, mason.nvim, nvim-lspconfig, telescope.nvim, neo-tree.nvim, toggleterm.nvim, lualine.nvim

---

## Task 1: 프로젝트 구조 생성 및 init.lua 작성

**Files:**
- Create: `~/.config/nvim/init.lua`
- Create: `~/.config/nvim/lua/core/`
- Create: `~/.config/nvim/lua/plugins/`
- Create: `~/.config/nvim/lua/config/`

**Step 1: 디렉토리 구조 생성**

```bash
mkdir -p ~/.config/nvim/lua/core
mkdir -p ~/.config/nvim/lua/plugins
mkdir -p ~/.config/nvim/lua/config
```

**Step 2: init.lua 작성**

```lua
--------------------------------------------------------------------------------
-- 진입점: 모듈 로드 및 lazy.nvim 부트스트랩
--------------------------------------------------------------------------------

-- 1. Core 모듈 로드 (기본 설정, 키매핑, 자동 명령)
require("core.options")
require("core.keymaps")
require("core.autocmds")

-- 2. lazy.nvim 부트스트랩
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- 3. Plugin Manager 로드
require("lazy").setup("plugins")

-- 4. 테마 적용
vim.cmd('colorscheme solarized')
```

**Step 3: Commit**

```bash
cd ~/.config/nvim
git init
git add init.lua lua/
git commit -m "feat: add project structure and init.lua

- Create modular lua/ directory structure
- Add init.lua as entry point
- Setup lazy.nvim bootstrap

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Core 모듈 - health.lua (OS 감지)

**Files:**
- Create: `~/.config/nvim/lua/core/health.lua`

**Step 1: health.lua 작성**

```lua
--------------------------------------------------------------------------------
-- OS 감지 및 크로스 플랫폼 유틸리티
--------------------------------------------------------------------------------
local M = {}

-- OS 감지
M.is_windows = vim.loop.os_uname().version:find("Windows") ~= nil
M.is_mac = vim.loop.os_uname().sysname == "Darwin"
M.is_linux = vim.loop.os_uname().sysname == "Linux"

-- 경로 구분자
M.path_sep = M.is_windows and "\\" or "/"

-- OS 정보 로깅 (디버깅용)
function M.log_platform_info()
    local uname = vim.loop.os_uname()
    print("Platform Info:")
    print("  sysname: " .. uname.sysname)
    print("  version: " .. uname.version)
    print("  is_windows: " .. tostring(M.is_windows))
    print("  is_mac: " .. tostring(M.is_mac))
    print("  is_linux: " .. tostring(M.is_linux))
end

return M
```

**Step 2: health.lua 문법 검증**

```bash
nvim --headless -c "lua require('core.health').log_platform_info()" -c "qa"
```
Expected: 플랫폼 정보가 출력됨

**Step 3: Commit**

```bash
git add lua/core/health.lua
git commit -m "feat: add health.lua for OS detection

- Detect Windows, macOS, Linux
- Provide path separator
- Add platform info logging

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: Core 모듈 - options.lua (기본 옵션)

**Files:**
- Create: `~/.config/nvim/lua/core/options.lua`

**Step 1: options.lua 작성**

```lua
--------------------------------------------------------------------------------
-- 기본 옵션 (Environment Properties)
--------------------------------------------------------------------------------
local opt = vim.opt
local health = require("core.health")

-- 행 번호
opt.number = true
opt.relativenumber = false

-- 들여쓰기
opt.autoindent = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.expandtab = true
opt.smartindent = true

-- 검색
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- 표시
opt.list = true
opt.showmatch = true
opt.wrap = false
opt.cursorline = true
opt.scrolloff = 5
opt.sidescrolloff = 5

-- 색상
opt.termguicolors = true
opt.fileencodings = "utf-8"

-- 마우스
opt.mouse = ""

-- 기록
opt.history = 1000

-- Shada (리소스 최적화)
opt.shada = "!,'100,<50,s10,h"

-- 백업/스왑 (비활성화 - 모던 편집기 방식)
opt.backup = false
opt.writebackup = false
opt.swapfile = false

-- Undo 파일 (영구 지원)
local undodir = vim.fn.stdpath("data") .. "/undo"
if not vim.loop.fs_stat(undodir) then
    vim.fn.mkdir(undodir, "p")
end
opt.undofile = true
opt.undodir = undodir

-- 완성 메뉴
opt.completeopt = { "menu", "menuone", "noselect" }

-- 업데이트 시간 (LSP 대기 시간 단축)
opt.updatetime = 300

-- Sign 컬럼 (Git gitsigns 등을 위한 공간 확보)
opt.signcolumn = "yes"

-- 폴드 방식 (treesitter 사용)
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldenable = false

-- 크로스 플랫폼: 클립보드
if health.is_windows or health.is_mac then
    opt.clipboard = "unnamed"
else  -- Linux Wayland
    opt.clipboard = "unnamedplus"
end

-- 크로스 플랫폼: Shell 설정
if health.is_windows then
    -- PowerShell 7
    opt.shell = "pwsh"
    opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    opt.shellquote = '"'
    opt.shellxquote = ""
    opt.shellredir = "2>&1 | Out-File -Encoding UTF8 %s"
    opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s"
else  -- macOS/Linux
    opt.shell = "zsh"
end
```

**Step 2: options.lua 문법 검증**

```bash
nvim --headless -c "lua require('core.options')" -c "qa"
```
Expected: 에러 없이 종료

**Step 3: Commit**

```bash
git add lua/core/options.lua
git commit -m "feat: add core options with cross-platform support

- Basic editor options (indent, search, display)
- Cross-platform clipboard (Windows/macOS use unnamed, Linux uses unnamedplus)
- Shell configuration (pwsh for Windows, zsh for macOS/Linux)
- Undo file support
- Treesitter fold integration

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Core 모듈 - keymaps.lua (글로벌 키매핑)

**Files:**
- Create: `~/.config/nvim/lua/core/keymaps.lua`

**Step 1: keymaps.lua 작성**

```lua
--------------------------------------------------------------------------------
-- 글로벌 키매핑
--------------------------------------------------------------------------------
local M = {}

-- Leader 키 설정
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 네비게이션: 창 이동
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to lower window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to upper window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- 버퍼 관리
vim.keymap.set('n', '<leader>bd', ':bd<CR>', { desc = 'Delete buffer' })
vim.keymap.set('n', '<leader>bn', ':bn<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bp', ':bp<CR>', { desc = 'Previous buffer' })

-- 탭 관리
vim.keymap.set('n', '<leader>tn', ':tabnew<CR>', { desc = 'New tab' })
vim.keymap.set('n', '<leader>tc', ':tabclose<CR>', { desc = 'Close tab' })
vim.keymap.set('n', '<leader>to', ':tabonly<CR>', { desc = 'Close other tabs' })

-- 빠른 접근
vim.keymap.set('n', '<leader>w', ':write<CR>', { desc = 'Write file' })
vim.keymap.set('n', '<leader>q', ':quit<CR>', { desc = 'Quit' })
vim.keymap.set('n', '<leader>x', ':x<CR>', { desc = 'Write and quit' })

-- 검색 하이라이트 해제
vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>', { desc = 'Clear search highlight' })

-- 텍스트 조작 (visual 모드)
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move line down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move line up' })

-- 단어 밑줄 변경 (snake_case <-> camelCase)
vim.keymap.set('n', '<leader>cs', 'ciw', { desc = 'Change inner word' }) -- 확장 가능

return M
```

**Step 2: keymaps.lua 문법 검증**

```bash
nvim --headless -c "lua require('core.keymaps')" -c "qa"
```
Expected: 에러 없이 종료

**Step 3: Commit**

```bash
git add lua/core/keymaps.lua
git commit -m "feat: add global keymaps

- Leader key: space
- Window navigation (Ctrl+h/j/k/l)
- Buffer management
- Tab management
- Quick access (write, quit)
- Search highlight clear
- Visual mode line moving

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 5: Core 모듈 - autocmds.lua (자동 명령)

**Files:**
- Create: `~/.config/nvim/lua/core/autocmds.lua`

**Step 1: autocmds.lua 작성**

```lua
--------------------------------------------------------------------------------
-- 자동 명령 (Event Listeners)
--------------------------------------------------------------------------------
local M = {}

-- 파일 타입별 설정
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "lua", "vim" },
    callback = function()
        vim.opt_local.shiftwidth = 4
        vim.opt_local.tabstop = 4
    end,
    desc = "Set indentation for Lua/Vim files",
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "javascript", "typescript", "python", "rust", "go" },
    callback = function()
        vim.opt_local.shiftwidth = 4
        vim.opt_local.tabstop = 4
    end,
    desc = "Set indentation for programming languages",
})

-- 마지막 커서 위치 복구
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
    desc = "Restore last cursor position",
})

-- 포커스 잃으면 자동 저장 (선택적)
-- vim.api.nvim_create_autocmd("FocusLost", {
--     callback = function()
--         if vim.bo.modifiable and not vim.bo.readonly then
--             vim.cmd("silent! write")
--         end
--     end,
--     desc = "Auto-save on focus lost",
-- })

return M
```

**Step 2: autocmds.lua 문법 검증**

```bash
nvim --headless -c "lua require('core.autocmds')" -c "qa"
```
Expected: 에러 없이 종료

**Step 3: Commit**

```bash
git add lua/core/autocmds.lua
git commit -m "feat: add autocommands

- Filetype-specific indentation
- Restore last cursor position
- Auto-save on focus lost (commented out, optional)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 6: LSP 공통 핸들러 - config/lsp_handlers.lua

**Files:**
- Create: `~/.config/nvim/lua/config/lsp_handlers.lua`

**Step 1: lsp_handlers.lua 작성**

```lua
--------------------------------------------------------------------------------
-- LSP 공통 핸들러 (모든 LSP 서버에 적용)
--------------------------------------------------------------------------------
local M = {}

-- LSP 키매핑 설정 (on_attach에서 호출)
function M.on_attach(client, bufnr)
    local bufopts = { noremap = true, silent = true, buffer = bufnr }

    -- 네비게이션
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, bufopts)

    -- 정보 표시
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)

    -- 코드 액션
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', '<leader>fm', function()
        vim.lsp.buf.format({ async = true })
    end, bufopts)

    -- Diagnostics
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
    vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, bufopts)
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, bufopts)
end

-- LSP capabilities 설정 (nvim-cmp 연동)
function M.get_capabilities()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
    return capabilities
end

return M
```

**Step 2: lsp_handlers.lua 문법 검증**

```bash
nvim --headless -c "lua require('config.lsp_handlers')" -c "qa"
```
Expected: cmp_nvim_lsp 관련 경고 (아직 설치 안 함)지만 문법 에러는 없음

**Step 3: Commit**

```bash
git add lua/config/lsp_handlers.lua
git commit -m "feat: add LSP common handlers

- on_attach: buffer-specific keymaps
- get_capabilities: nvim-cmp integration
- Navigation (gd, gr, gi, gt)
- Info display (K, Ctrl+k)
- Code actions (rename, code_action, format)
- Diagnostics navigation

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 7: Plugin - Mason & LSP (plugins/lsp.lua)

**Files:**
- Create: `~/.config/nvim/lua/plugins/lsp.lua`

**Step 1: plugins/lsp.lua 작성**

```lua
--------------------------------------------------------------------------------
-- LSP 및 Mason 설정
--------------------------------------------------------------------------------
return {
    -- Mason: LSP/포매터/린터 매니저
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        config = function()
            require("mason").setup({
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗"
                    }
                }
            })
        end,
    },

    -- Mason-LSPConfig 연동
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            local lsp_handlers = require("config.lsp_handlers")

            require("mason-lspconfig").setup({
                -- 자동 설치할 LSP 서버
                ensure_installed = {
                    -- Lua
                    "lua_ls",
                    -- JavaScript/TypeScript
                    "ts_ls",
                    -- Python
                    "pylsp",
                    -- Rust
                    "rust_analyzer",
                    -- Go
                    "gopls",
                    -- Docker
                    "dockerls",
                    -- YAML
                    "yamlls",
                    -- Terraform
                    "terraformls",
                },
                -- 자동 설치 후 LSP 설정
                automatic_installation = true,
                handlers = {
                    -- 기본 핸들러
                    function(server_name)
                        local lspconfig = require("lspconfig")
                        local opts = {
                            on_attach = lsp_handlers.on_attach,
                            capabilities = lsp_handlers.get_capabilities(),
                        }

                        -- 서버별 설정
                        if server_name == "lua_ls" then
                            opts.settings = {
                                Lua = {
                                    diagnostics = {
                                        globals = { "vim" }
                                    }
                                }
                            }
                        elseif server_name == "ts_ls" then
                            opts.settings = {
                                typescript = {
                                    format = {
                                        enable = false  -- prettier 사용
                                    }
                                }
                            }
                        end

                        lspconfig[server_name].setup(opts)
                    end,
                }
            })
        end,
    },

    -- nvim-lspconfig: LSP 설정
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
    },

    -- Java LSP (별도 설정 필요)
    {
        "mfussenegger/jdtls",
        dependencies = { "neovim/nvim-lspconfig" },
        ft = { "java" },
    },
}
```

**Step 2: Commit**

```bash
git add lua/plugins/lsp.lua
git commit -m "feat: add Mason and LSP configuration

- Install mason.nvim as LSP/formatter/linter manager
- Configure mason-lspconfig with auto-install
- Supported languages: Lua, JS/TS, Python, Rust, Go, Docker, YAML, Terraform
- Add JDTLS for Java (manual setup required)
- Integrate with lsp_handlers for keymaps and capabilities

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 8: Plugin - Completion (plugins/completion.lua)

**Files:**
- Create: `~/.config/nvim/lua/plugins/completion.lua`

**Step 1: plugins/completion.lua 작성**

```lua
--------------------------------------------------------------------------------
-- 코드 완성 (nvim-cmp)
--------------------------------------------------------------------------------
return {
    -- nvim-cmp: 완성 엔진
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            -- 완성 소스
            "hrsh7th/cmp-nvim-lsp",      -- LSP
            "hrsh7th/cmp-buffer",         -- 버퍼
            "hrsh7th/cmp-path",           -- 경로
            "hrsh7th/cmp-cmdline",        -- 명령행
            "petertriho/cmp-git",         -- Git
            -- Snippet 엔진
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                    { name = "path" },
                }),
            })

            -- 명령행 완성
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path" }
                }, {
                    { name = "cmdline" }
                })
            })
        end,
    },

    -- cmp-git: Git 완성
    {
        "petertriho/cmp-git",
        dependencies = { "hrsh7th/nvim-cmp" },
        config = function()
            require("cmp_git").setup()
        end,
        ft = { "gitcommit", "octo" },
    },
}
```

**Step 2: Commit**

```bash
git add lua/plugins/completion.lua
git commit -m "feat: add nvim-cmp completion

- Install nvim-cmp as completion engine
- Add completion sources: LSP, buffer, path, cmdline, git
- Integrate with LuaSnip for snippets
- Configure tab completion behavior
- Add cmdline completion for :commands

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 9: Plugin - Formatting (plugins/formatting.lua)

**Files:**
- Create: `~/.config/nvim/lua/plugins/formatting.lua`

**Step 1: plugins/formatting.lua 작성**

```lua
--------------------------------------------------------------------------------
-- 코드 포맷팅 (conform.nvim)
--------------------------------------------------------------------------------
return {
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                -- Lua
                lua = { "stylua" },
                -- JavaScript/TypeScript
                javascript = { "prettier" },
                typescript = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                -- Python
                python = { "black" },
                -- Rust
                rust = { "rustfmt" },
                -- Go
                go = { "gofmt" },
                -- Docker
                dockerfile = { "hadolint" },
                -- YAML
                yaml = { "prettier" },
                -- Terraform
                terraform = { "terraform fmt" },
                -- sh
                sh = { "shfmt" },
            },
            -- 포매터가 없으면 에러 표시 안 함
            log_level = vim.log.levels.WARN,
        },
        config = function(_, opts)
            require("conform").setup(opts)

            -- 포맷팅 키매핑
            vim.keymap.set({ "n", "v" }, "<leader>mp", function()
                require("conform").format({
                    lsp_fallback = true,
                    async = false,
                    timeout_ms = 1000,
                })
            end, { desc = "Format file or range" })
        end,
    },
}
```

**Step 2: Commit**

```bash
git add lua/plugins/formatting.lua
git commit -m "feat: add conform.nvim for formatting

- Install conform.nvim as formatter manager
- Configure formatters: stylua, prettier, black, rustfmt, gofmt, etc.
- Add <leader>mp keymap for manual format
- LSP fallback enabled

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 10: Plugin - Linting (plugins/linting.lua)

**Files:**
- Create: `~/.config/nvim/lua/plugins/linting.lua`

**Step 1: plugins/linting.lua 작성**

```lua
--------------------------------------------------------------------------------
-- 린팅 (nvim-lint)
--------------------------------------------------------------------------------
return {
    {
        "mfussenegger/nvim-lint",
        config = function()
            local lint = require("lint")

            -- Linter 설정
            lint.linters_by_ft = {
                -- JavaScript/TypeScript
                javascript = { "eslint_d" },
                typescript = { "eslint_d" },
                javascriptreact = { "eslint_d" },
                typescriptreact = { "eslint_d" },
                -- Python
                python = { "flake8" },
                -- Lua
                lua = { "selene" },
                -- Docker
                dockerfile = { "hadolint" },
                -- YAML
                yaml = { "yamllint" },
                -- Shell
                sh = { "shellcheck" },
            }

            -- 자동 린팅 트리거
            local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
            vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
                group = lint_augroup,
                callback = function()
                    lint.try_lint()
                end,
            })
        end,
    },
}
```

**Step 2: Commit**

```bash
git add lua/plugins/linting.lua
git commit -m "feat: add nvim-lint for linting

- Install nvim-lint as linter manager
- Configure linters: eslint_d, flake8, selene, hadolint, yamllint, shellcheck
- Auto-lint on BufEnter, BufWritePost, InsertLeave

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 11: Plugin - Git (plugins/git.lua)

**Files:**
- Create: `~/.config/nvim/lua/plugins/git.lua`

**Step 1: plugins/git.lua 작성**

```lua
--------------------------------------------------------------------------------
-- Git 통합
--------------------------------------------------------------------------------
return {
    -- vim-fugitive: Git 명령
    {
        "tpope/vim-fugitive",
        dependencies = { "tpope/vim-rhubarb" },
    },

    -- gitsigns.nvim: Git 변경 사항 표시
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                signs = {
                    add          = { text = "│" },
                    change       = { text = "│" },
                    delete       = { text = "_" },
                    topdelete    = { text = "‾" },
                    changedelete = { text = "~" },
                    untracked    = { text = "┆" },
                },
                signcolumn = true,
                numhl = false,
                linehl = false,
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- 네비게이션
                    map("n", "]c", function()
                        if vim.wo.diff then return "]c" end
                        vim.schedule(function() gs.next_hunk() end)
                        return "<Ignore>"
                    end, { expr = true })

                    map("n", "[c", function()
                        if vim.wo.diff then return "[c" end
                        vim.schedule(function() gs.prev_hunk() end)
                        return "<Ignore>"
                    end, { expr = true })

                    -- 액션
                    map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
                    map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
                    map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
                    map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })
                    map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Toggle blame" })
                    map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
                    map("n", "<leader>hD", function() gs.diffthis("~") end, { desc = "Diff this ~" })

                    -- 텍스트 오브젝트
                    map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
                end,
            })
        end,
    },
}
```

**Step 2: Commit**

```bash
git add lua/plugins/git.lua
git commit -m "feat: add Git integration

- Install vim-fugitive for Git commands
- Install gitsigns.nvim for Git change visualization
- Add keymaps for hunk navigation and actions
- Support text objects for hunks

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 12: Plugin - Explorer (plugins/explorer.lua)

**Files:**
- Create: `~/.config/nvim/lua/plugins/explorer.lua`

**Step 1: plugins/explorer.lua 작성**

```lua
--------------------------------------------------------------------------------
-- 파일 탐색 (Telescope + Neo-tree)
--------------------------------------------------------------------------------
return {
    -- Telescope: 퍼지 파일inder
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            -- FZF 네이티브 속도
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
                cond = function()
                    return vim.fn.executable("make") == 1
                end,
            },
        },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")

            telescope.setup({
                defaults = {
                    mappings = {
                        i = {
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                            ["<Esc>"] = actions.close,
                        },
                    },
                    prompt_prefix = " ",
                    selection_caret = " ",
                    entry_prefix = " ",
                },
                pickers = {
                    find_files = {
                        theme = "dropdown",
                        previewer = false,
                    },
                    live_grep = {
                        theme = "ivy",
                    },
                    buffers = {
                        theme = "dropdown",
                        previewer = false,
                    },
                },
            })

            -- FZF 네이티브 확장 로드
            pcall(function()
                telescope.load_extension("fzf")
            end)

            -- 키매핑
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
            vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
            vim.keymap.set("n", "<leader>fc", builtin.git_files, { desc = "Git files" })
        end,
    },

    -- Neo-tree: 파일 트리
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        config = function()
            require("neo-tree").setup({
                close_if_last_window = false,
                popup_border_style = "rounded",
                enable_git_status = true,
                enable_diagnostics = true,
                open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
                sort_case_insensitive = false,
                default_component_configs = {
                    container = { enable_character_fade = true },
                    indent = { indent_size = 2, padding = 1 },
                    icon = { folder_closed = "", folder_open = "" },
                    modified = { symbol = "[+]" },
                    git_status = {
                        symbols = {
                            added = "",
                            modified = "",
                            deleted = "",
                            renamed = "",
                            untracked = "?",
                            ignored = "",
                            unstaged = "",
                            staged = "",
                            conflict = "",
                        },
                    },
                },
                window = {
                    position = "left",
                    width = 40,
                    mapping_options = { noremap = true, nowait = true },
                },
                filesystem = {
                    bind_to_cwd = true,
                    cwd_target = { sidebar = "tab", current = "window" },
                    components = {
                        harpoon_index = function(config, node, state)
                            local Harpoon = package.loaded["harpoon"]
                            if Harpoon then
                                local index = Harpoon.get_index_of(node.path)
                                if index then
                                    return { text = string.format(" [%d]", index), highlight = "HarpoonIndex" }
                                end
                            end
                            return {}
                        end,
                    },
                },
            })
        end,
    },
}
```

**Step 2: Commit**

```bash
git add lua/plugins/explorer.lua
git commit -m "feat: add file explorers (Telescope + Neo-tree)

- Install Telescope for fuzzy finding
- Install telescope-fzf-native for speed
- Add keymaps: ff (files), fg (grep), fb (buffers), etc.
- Install Neo-tree for file tree
- Configure Neo-tree with git status and diagnostics
- Add <leader>e keymap for Neo-tree toggle

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 13: Plugin - Terminal (plugins/terminal.lua)

**Files:**
- Create: `~/.config/nvim/lua/plugins/terminal.lua`

**Step 1: plugins/terminal.lua 작성**

```lua
--------------------------------------------------------------------------------
-- 터미널 (toggleterm.nvim)
--------------------------------------------------------------------------------
return {
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        config = function()
            require("toggleterm").setup({
                size = function(term)
                    if term.direction == "horizontal" then
                        return 15
                    elseif term.direction == "vertical" then
                        return vim.o.columns * 0.4
                    end
                end,
                open_mapping = [[<leader>t]],
                direction = "float",
                float_opts = {
                    border = "curved",
                },
            })

            -- 터미널 모드에서 Esc로 터미널 닫기
            vim.api.nvim_create_autocmd("TermOpen", {
                pattern = "term://*toggleterm#*",
                callback = function()
                    local opts = { buffer = 0 }
                    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
                end,
            })

            -- OS별 터미널 설정
            local health = require("core.health")
            local Terminal = require("toggleterm.terminal").Terminal

            if health.is_windows then
                -- PowerShell 7 터미널
                local pwsh = Terminal:new({ cmd = "pwsh", hidden = true })
                function _PWSH_TOGGLE()
                    pwsh:toggle()
                end
                vim.keymap.set("n", "<leader>tp", _PWSH_TOGGLE, { desc = "Toggle PowerShell" })
            else
                -- zsh 터미널
                local zsh = Terminal:new({ cmd = "zsh", hidden = true })
                function _ZSH_TOGGLE()
                    zsh:toggle()
                end
                vim.keymap.set("n", "<leader>tz", _ZSH_TOGGLE, { desc = "Toggle zsh" })
            end
        end,
    },
}
```

**Step 2: Commit**

```bash
git add lua/plugins/terminal.lua
git commit -m "feat: add toggleterm.nvim for terminal management

- Install toggleterm.nvim
- Configure floating terminal with curved border
- Add <leader>t keymap for toggle
- Add Esc mapping to exit terminal mode
- OS-specific terminals: pwsh on Windows, zsh on macOS/Linux

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 14: Plugin - UI (plugins/ui.lua)

**Files:**
- Create: `~/.config/nvim/lua/plugins/ui.lua`

**Step 1: plugins/ui.lua 작성**

```lua
--------------------------------------------------------------------------------
-- UI 구성 요소
--------------------------------------------------------------------------------
return {
    -- nvim-web-devicons: 아이콘 지원
    {
        "nvim-tree/nvim-web-devicons",
        config = function()
            require("nvim-web-devicons").setup({
                default = true,
                strict = true,
            })
        end,
    },

    -- lualine.nvim: 상태줄
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "solarized_dark",
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                    globalstatus = true,
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", "diff", "diagnostics" },
                    lualine_c = { { "filename", path = 1 } },
                    lualine_x = { "encoding", "fileformat", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = { "filename" },
                    lualine_x = { "location" },
                    lualine_y = {},
                    lualine_z = {},
                },
            })
        end,
    },
}
```

**Step 2: Commit**

```bash
git add lua/plugins/ui.lua
git commit -m "feat: add UI components (devicons + lualine)

- Install nvim-web-devicons for file type icons
- Install lualine.nvim for modern status line
- Configure lualine with solarized_dark theme
- Show: mode, branch, diff, diagnostics, filename, progress, location
- Enable global status line

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 15: Plugin - Theme (plugins/theme.lua)

**Files:**
- Create: `~/.config/nvim/lua/plugins/theme.lua`

**Step 1: plugins/theme.lua 작성**

```lua
--------------------------------------------------------------------------------
-- 테마 설정
--------------------------------------------------------------------------------
return {
    {
        "maxmx03/solarized.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("solarized").setup({
                variant = "autumn",  -- or "spring"
                transparent = false,
                styles = {
                    comments = { italic = true },
                    functions = {},
                    keywords = { bold = true },
                    variables = {},
                },
            })
            vim.cmd.colorscheme("solarized")
        end,
    },
}
```

**Step 2: Commit**

```bash
git add lua/plugins/theme.lua
git commit -m "feat: add solarized.nvim theme

- Install solarized.nvim (modern Lua port)
- Use autumn variant
- Enable italic for comments
- Set highest priority for early load
- Auto-apply colorscheme

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 16: Mason Formatters & Linters 추가

**Files:**
- Create: `~/.config/nvim/lua/plugins/mason_formatters.lua`

**Step 1: plugins/mason_formatters.lua 작성**

```lua
--------------------------------------------------------------------------------
-- Mason: 포매터 & 린터 설치
--------------------------------------------------------------------------------
return {
    {
        "williamboman/mason.nvim",
        dependencies = {
            "williamboman/mason-null-ls.nvim",
            "jay-babu/mason-null-ls.nvim",
        },
        config = function()
            require("mason").setup()

            require("mason-null-ls").setup({
                ensure_installed = {
                    -- Formatters
                    "stylua",          -- Lua
                    "prettier",        -- JS/TS/YAML/JSON
                    "black",           -- Python
                    "rustfmt",         -- Rust
                    "gofmt",           -- Go
                    "google-java-format", -- Java
                    "hadolint",        -- Dockerfile
                    "shfmt",           -- Shell
                    "terraform_fmt",   -- Terraform

                    -- Linters
                    "selene",          -- Lua
                    "eslint_d",        -- JS/TS
                    "flake8",          -- Python
                    "yamllint",        -- YAML
                    "shellcheck",      -- Shell
                    "tflint",          -- Terraform
                },
                automatic_installation = true,
            })
        end,
    },

    {
        "jay-babu/mason-null-ls.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "nvimtools/none-ls.nvim",
        },
        config = function()
            require("mason-null-ls").setup({
                handlers = {},
            })
        end,
    },
}
```

**Step 2: Commit**

```bash
git add lua/plugins/mason_formatters.lua
git commit -m "feat: add Mason formatters and linters

- Install mason-null-ls.nvim
- Configure formatters: stylua, prettier, black, rustfmt, gofmt, etc.
- Configure linters: selene, eslint_d, flake8, yamllint, shellcheck, tflint
- Auto-install enabled

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 17: README.md 작성

**Files:**
- Create: `~/.config/nvim/README.md`

**Step 1: README.md 작성**

```markdown
# Cross-Platform Neovim Configuration

다중 OS 지원 Neovim 설정 (Windows, macOS, Linux)

## 지원 플랫폼

- Windows 10/11 (PowerShell 7)
- macOS (zsh)
- Linux (Fedora/Ubuntu/SteamOS) (zsh, Wayland)

## 지원 언어

- Lua, JavaScript/TypeScript, Python, Rust, Go, Java
- Docker, YAML, Terraform

## 기능

- LSP (Mason + nvim-lspconfig)
- Code completion (nvim-cmp)
- Formatting (conform.nvim)
- Linting (nvim-lint)
- Git integration (vim-fugitive + gitsigns)
- File explorer (Telescope + Neo-tree)
- Terminal (toggleterm)
- Status line (lualine)

## 설치

### 1. Neovim 설치

**Windows:**
```powershell
winget install Neovim.Neovim
```

**macOS:**
```bash
brew install neovim
```

**Fedora:**
```bash
sudo dnf install neovim
```

**Ubuntu:**
```bash
sudo apt install neovim
```

**SteamOS:**
```bash
sudo steamos-readonly disable
sudo pacman -S neovim
sudo steamos-readonly enable
```

### 2. 설정 복사

```bash
git clone <repo-url> ~/.config/nvim
```

### 3. 의존성 설치

**Windows (PowerShell 7 필요):**
```powershell
# PowerShell 7 설치
winget install Microsoft.PowerShell

# Neovim을 열면 자동으로 플러그인 설치됨
nvim
# :Lazy sync 실행
# :Mason 실행 후 필요한 도구 설치
```

**macOS:**
```bash
brew install zsh
nvim
:Lazysync
:Mason
```

**Linux (Fedora):**
```bash
sudo dnf install wl-clipboard zsh
nvim
:Lazysync
:Mason
```

**Linux (Ubuntu):**
```bash
sudo apt install wl-clipboard zsh
nvim
:Lazysync
:Mason
```

**SteamOS:**
```bash
sudo steamos-readonly disable
sudo pacman -S wl-clipboard zsh
sudo steamos-readonly enable
nvim
:Lazysync
:Mason
```

## 키매핑

### Leader
- `<Space>` - Leader 키

### 네비게이션
- `<Ctrl-h/j/k/l>` - 창 이동

### 파일
- `<leader>ff` - 파일 찾기 (Telescope)
- `<leader>fg` - 라이브 그렙
- `<leader>fb` - 버퍼 찾기
- `<leader>e` - 파일 트리 (Neo-tree)

### 터미널
- `<leader>t` - 터미널 토글
- `<leader>tp` - PowerShell (Windows)
- `<leader>tz` - zsh (macOS/Linux)

### Git
- `<leader>gs` - Git 상태
- `<leader>gb` - Git 블레임

### LSP
- `K` - 호버
- `gd` - 정의로 이동
- `gr` - 참조 찾기
- `<leader>rn` - 이름 변경
- `<leader>ca` - 코드 액션
- `<leader>mp` - 포맷팅

## 구조

```
~/.config/nvim/
├── init.lua           # 진입점
├── lua/
│   ├── core/          # 기본 설정
│   ├── plugins/       # 플러그인 설정
│   └── config/        # LSP 핸들러
└── README.md
```
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README.md

- Installation instructions for each platform
- Supported languages list
- Key mappings reference
- Project structure overview

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 18: lazy-lock.json 생성 및 테스트

**Files:**
- Create: `~/.config/nvim/lazy-lock.json` (자동 생성)

**Step 1: Neovim 실행 및 플러그인 설치 테스트**

```bash
nvim --headless "+Lazy! sync" +qa
```
Expected: 플러그인 설치 완료

**Step 2: lazy-lock.json 커밋**

```bash
cd ~/.config/nvim
git add lazy-lock.json
git commit -m "chore: add lazy-lock.json for plugin version consistency

- Lock plugin versions for cross-platform consistency
- Generated by :Lazy sync

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

**Step 3: 최종 커밋 전체 푸시 준비**

```bash
git log --oneline
```
Expected: 모든 커밋이 순서대로 표시됨

---

## 검증 (Verification)

### Windows 검증
```powershell
nvim --headless -c "lua print('Lua OK')" -c "lua require('core.health').log_platform_info()" -c "qa"
```

### macOS/Linux 검증
```bash
nvim --headless -c "lua print('Lua OK')" -c "lua require('core.health').log_platform_info()" -c "qa"
```

---

## 완료 체크리스트

- [ ] init.lua 작성 및 커밋
- [ ] core/health.lua 작성 및 커밋
- [ ] core/options.lua 작성 및 커밋
- [ ] core/keymaps.lua 작성 및 커밋
- [ ] core/autocmds.lua 작성 및 커밋
- [ ] config/lsp_handlers.lua 작성 및 커밋
- [ ] plugins/lsp.lua 작성 및 커밋
- [ ] plugins/completion.lua 작성 및 커밋
- [ ] plugins/formatting.lua 작성 및 커밋
- [ ] plugins/linting.lua 작성 및 커밋
- [ ] plugins/git.lua 작성 및 커밋
- [ ] plugins/explorer.lua 작성 및 커밋
- [ ] plugins/terminal.lua 작성 및 커밋
- [ ] plugins/ui.lua 작성 및 커밋
- [ ] plugins/theme.lua 작성 및 커밋
- [ ] plugins/mason_formatters.lua 작성 및 커밋
- [ ] README.md 작성 및 커밋
- [ ] lazy-lock.json 생성 및 커밋
- [ ] 각 플랫폼에서 동작 확인

---

## 추가 리소스

- [lazy.nvim 문서](https://github.com/folke/lazy.nvim)
- [nvim-cmp 문서](https://github.com/hrsh7th/nvim-cmp)
- [conform.nvim 문서](https://github.com/stevearc/conform.nvim)
- [nvim-lint 문서](https://github.com/mfussenegger/nvim-lint)
- [Mason 문서](https://github.com/williamboman/mason.nvim)
