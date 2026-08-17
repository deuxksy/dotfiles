--------------------------------------------------------------------------------
-- UI 향상 도구 (which-key + todo-comments)
--------------------------------------------------------------------------------
return {
    -- which-key: 키바인딩 가시화
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "modern",
            delay = 500,
            icons = {
                mappings = true,
                keys = {},
            },
            spec = {
                { "<leader>b", group = "buffer", icon = "" },
                { "<leader>t", group = "tab", icon = "" },
                { "<leader>f", group = "find", icon = "" },
                { "<leader>m", group = "format/lint", icon = "" },
                { "<leader>c", group = "code", icon = "" },
            },
        },
        keys = {
            {
                "<leader>?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "Buffer Local Keymaps",
            },
        },
    },

    -- todo-comments: TODO/FIXME 하이라이트
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            signs = true,
            sign_priority = 8,
            colors = {
                error = { "DiagnosticError", "ErrorMsg", "#f38633" },
                warning = { "DiagnosticWarn", "WarningMsg", "#FFA500" },
                info = { "DiagnosticInfo", "#2196f3" },
                hint = { "DiagnosticHint", "#7C3AED" },
                default = { "Identifier", "#7C3AED" },
                test = { "Identifier", "#FF6B6B" },
                perf = { "DiagnosticWarn", "#FFD93D" },
            },
            keywords = {
                FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
                TODO = { icon = " ", color = "info" },
                HACK = { icon = " ", color = "warning" },
                WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
                PERF = { icon = " ", color = "perf" },
                NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
                TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
            },
            highlight = {
                pattern = [[.*<(KEYWORDS)\s*:]],
            },
        },
    },

    -- wakatime: 코딩 시간 추적
    { 'wakatime/vim-wakatime', lazy = false },

    -- trouble.nvim: 진단 목록
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {},
        cmd = "Trouble",
        keys = {
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
            { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
            { "<leader>cs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols" },
            { "<leader>cl", "<cmd>Trouble lsp toggle<cr>", desc = "LSP Definitions" },
            { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location List" },
            { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List" },
        },
    },
}
