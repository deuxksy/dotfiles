--------------------------------------------------------------------------------
-- Treesitter: 구문 강조 및 인덴트
--------------------------------------------------------------------------------
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        ensure_installed = {
            "lua", "vim", "vimdoc",
            "javascript", "typescript", "tsx",
            "python", "go", "rust", "nix",
            "json", "yaml", "toml",
            "markdown", "markdown_inline",
            "html", "css", "scss",
            "bash", "dockerfile",
        },
        auto_install = true,
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
    },
}
