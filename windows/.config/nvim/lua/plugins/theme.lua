--------------------------------------------------------------------------------
-- 테마 설정 (monokai-pro.nvim)
--------------------------------------------------------------------------------
return {
    {
        "loctvl842/monokai-pro.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("monokai-pro").setup({
                transparent_background = true,   -- WezTerm blur 투과
                terminal_colors = true,
                devicons = true,
                filter = "pro", -- classic | octagon | pro | machine | rist | spectrum
                plugins = {
                    bufferline = {
                        underline_selected = true,
                        underline_visible = true,
                    },
                    indent_blankline = {
                        context_highlight = "pro",
                    },
                    lsp_saga = true,
                    neo_tree = true,
                    which_key = true,
                },
            })
            vim.cmd.colorscheme("monokai-pro")
        end,
    },
}
