--------------------------------------------------------------------------------
-- 글로벌 키매핑
--------------------------------------------------------------------------------
local M = {}

-- Leader 키 설정
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 네비게이션: 창 이동 — vim-tmux-navigator가 C-h/j/k/l 관리

-- 버퍼 관리 — <leader>bd는 bufferline(ui-extras)에서 관리
vim.keymap.set('n', '<leader>bn', ':bn<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bp', ':bp<CR>', { desc = 'Previous buffer' })

-- 탭 관리
vim.keymap.set('n', '<leader>tn', ':tabnew<CR>', { desc = 'New tab' })
vim.keymap.set('n', '<leader>tc', ':tabclose<CR>', { desc = 'Close tab' })
vim.keymap.set('n', '<leader>to', ':tabonly<CR>', { desc = 'Close other tabs' })

-- 빠른 접근
vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = 'Write file' })
vim.keymap.set('n', '<leader>q', ':q<CR>', { desc = 'Quit' })
vim.keymap.set('n', '<leader>x', ':x<CR>', { desc = 'Write and quit' })

-- 검색 하이라이트 해제
vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>', { desc = 'Clear search highlight' })

-- 텍스트 조작 (visual 모드)
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move line down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move line up' })

return M
