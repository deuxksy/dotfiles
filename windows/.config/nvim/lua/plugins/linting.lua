--------------------------------------------------------------------------------
-- 린팅 (nvim-lint)
--------------------------------------------------------------------------------
return {
    {
        "mfussenegger/nvim-lint",
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = {
                javascript = { "eslint_d" },
                typescript = { "eslint_d" },
                javascriptreact = { "eslint_d" },
                typescriptreact = { "eslint_d" },
                python = { "flake8" },
                -- lua = { "selene" },  -- selene 설정 파일 필요
                dockerfile = { "hadolint" },
                yaml = { "yamllint" },
                sh = { "shellcheck" },
            }
            vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
                callback = function()
                    pcall(lint.try_lint)
                end,
            })
        end,
    },
}
