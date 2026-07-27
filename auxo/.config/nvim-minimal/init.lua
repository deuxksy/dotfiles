-- auxo minimal neovim config
-- plugin manager 없이 동작, mcp/lsp/telescope/codecompanion 등 비활성화

-- undo 디렉토리 보장
vim.fn.mkdir(vim.fn.stdpath('cache') .. '/undo', 'p')

-- 기본 옵션
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath('cache') .. '/undo'
vim.opt.clipboard = 'unnamedplus'
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.completeopt = { 'menuone', 'noselect' }

-- leader
vim.g.mapleader = ' '

-- 최소 키맵
vim.keymap.set('n', '<leader>w', '<cmd>w<cr>', { desc = '저장' })
vim.keymap.set('n', '<leader>q', '<cmd>q<cr>', { desc = '종료' })
vim.keymap.set('n', '<leader>h', '<cmd>nohlsearch<cr>', { desc = '하이라이트 제거' })
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- 기본 colorscheme
vim.cmd('colorscheme default')
