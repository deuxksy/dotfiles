--------------------------------------------------------------------------------
-- 추가 UI: bufferline + 인덴트 가이드
--------------------------------------------------------------------------------
return {
    -- bufferline: 상단 탭 바
    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        event = "VeryLazy",
        opts = {
            options = {
                mode = "buffers",
                separator_style = "thin",
                always_show_bufferline = false,
                diagnostics = "nvim_lsp",
                offsets = {
                    {
                        filetype = "neo-tree",
                        text = "File Explorer",
                        text_align = "left",
                        separator = true,
                    },
                },
            },
        },
        keys = {
            { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
            { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
            { "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete buffer" },
            { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Close other buffers" },
        },
    },

    -- indent-blankline: 인덴트 가이드
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            indent = {
                char = "│",
            },
            scope = {
                enabled = true,
            },
        },
    },
}
