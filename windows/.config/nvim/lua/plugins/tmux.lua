--------------------------------------------------------------------------------
-- tmux 연동 (vim-tmux-navigator)
--------------------------------------------------------------------------------
return {
    {
        "christoomey/vim-tmux-navigator",
        cmd = {
            "TmuxNavigateLeft",
            "TmuxNavigateDown",
            "TmuxNavigateUp",
            "TmuxNavigateRight",
            "TmuxNavigatePrevious",
        },
        keys = {
            { "<C-h>", "<cmd>TmuxNavigateLeft<cr>",  desc = "Navigate left (tmux aware)" },
            { "<C-j>", "<cmd>TmuxNavigateDown<cr>",  desc = "Navigate down (tmux aware)" },
            { "<C-k>", "<cmd>TmuxNavigateUp<cr>",    desc = "Navigate up (tmux aware)" },
            { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right (tmux aware)" },
        },
        init = function()
            vim.g.tmux_navigator_no_mappings = 1
            vim.g.tmux_navigator_save_on_switch = 2
        end,
    },
}
