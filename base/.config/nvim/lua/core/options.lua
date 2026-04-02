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

-- 기록
opt.history = 1000

-- Shada (리소스 최적화)
opt.shada = "!,'100,<50,s10,h"

-- 백업/스왑 (비활성화 - 모던 에디터 방식)
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

-- 폴드 방식 (treesitter 사용, 지연 설정)
opt.foldenable = false
vim.api.nvim_create_autocmd("FileType", {
    callback = function()
        pcall(function()
            vim.opt_local.foldmethod = "expr"
            vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end)
    end,
})

-- 분할 방향
opt.splitbelow = true       -- 가로분할: 아래로
opt.splitright = true       -- 세로분할: 오른쪽으로

-- 키 대기시간
opt.timeoutlen = 500        -- Leader 키 조합 대기시간

-- 완성 메뉴
opt.pumheight = 10          -- 팝업 메뉴 높이 제한

-- 상태바 (Neovim 0.8+)
opt.laststatus = 3          -- 전역 상태바

-- 성능
opt.redrawtime = 1500       -- redraw 타임아웃
opt.synmaxcol = 200         -- 구문강조 컬럼 제한 (긴 라인 성능)
opt.emoji = false           -- 이모지 깨짐 방지

-- 클립보드: tmux OSC 52 + 시스템 클립보드 연동
opt.clipboard = "unnamedplus"

-- 마우스: tmux passthrough 허용
opt.mouse = "a"

-- Modeline 비활성화 (CVE-2019-12735 파일 내 설정 주입 방어)
opt.modeline = false

-- 크로스 플랫폼: Shell 설정
if health.is_windows then
    if vim.fn.executable("pwsh") > 0 then
        opt.shell = "pwsh"
        opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
        opt.shellquote = '"'
        opt.shellxquote = ""
    else
        opt.shell = "cmd.exe"
    end
else  -- macOS/Linux
    local shells = { "zsh", "bash" }
    for _, shell in ipairs(shells) do
        if vim.fn.executable(shell) > 0 then
            opt.shell = shell
            break
        end
    end
end
