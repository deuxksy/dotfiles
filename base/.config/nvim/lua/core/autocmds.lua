--------------------------------------------------------------------------------
-- 자동 명령 (Event Listeners)
--------------------------------------------------------------------------------

-- tmux: 포커스 이벤트 — 파일 외부 변경 자동 반영
vim.api.nvim_create_autocmd("FocusGained", {
    callback = function()
        vim.cmd("checktime")
    end,
    desc = "Reload file when gaining focus (tmux passthrough)",
})

-- tmux: 패널 리사이즈 시 Neovim 재정렬
vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
        vim.cmd("wincmd =")
    end,
    desc = "Equalize panes on resize (tmux aggressive-resize)",
})

-- 마지막 커서 위치 복구
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if
            mark[1] > 0
            and mark[1] <= lcount
            and vim.bo.buftype == ""      -- 일반 버퍼만
            and not vim.bo.readonly       -- 읽기 전용 제외
        then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
    desc = "Restore last cursor position",
})
