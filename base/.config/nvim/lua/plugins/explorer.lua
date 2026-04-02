--------------------------------------------------------------------------------
-- 파일 탐색기 (telescope + neo-tree)
--------------------------------------------------------------------------------
return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local telescope = require("telescope")
            telescope.setup({
                defaults = {
                    mappings = {
                        i = {
                            ["<C-j>"] = require("telescope.actions").move_selection_next,
                            ["<C-k>"] = require("telescope.actions").move_selection_previous,
                        },
                    },
                },
            })
            vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
            vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
            vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
            vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>")
        end,
    },
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
        config = function() require("neo-tree").setup({}) end,
    },
}
