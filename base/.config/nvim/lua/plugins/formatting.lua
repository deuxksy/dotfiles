--------------------------------------------------------------------------------
-- 코드 포맷팅 (conform.nvim)
--------------------------------------------------------------------------------
return {
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                python = { "black" },
                rust = { "rustfmt" },
                go = { "gofmt" },
                -- dockerfile formatting은 별도 도구 없음 (hadolint는 Liner)
                yaml = { "prettier" },
                terraform = { "terraform_fmt" },
                sh = { "shfmt" },
            },
            log_level = vim.log.levels.WARN,
        },
        config = function(_, opts)
            require("conform").setup(opts)
            vim.keymap.set({ "n", "v" }, "<leader>mp", function()
                require("conform").format({
                    lsp_fallback = true,
                    async = false,
                    timeout_ms = 3000,
                })
            end, { desc = "Format file or range" })
        end,
    },
}
