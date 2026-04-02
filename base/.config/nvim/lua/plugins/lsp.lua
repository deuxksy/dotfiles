--------------------------------------------------------------------------------
-- LSP 및 Mason 설정
--------------------------------------------------------------------------------
return {
    -- Mason: LSP/포매터/린터 매니저
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        config = function()
            require("mason").setup({
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗"
                    }
                }
            })
        end,
    },

    -- Mason-LSPConfig 연동
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            local lsp_handlers = require("config.lsp_handlers")

            require("mason-lspconfig").setup({
                -- 자동 설치할 LSP 서버
                ensure_installed = {
                    -- Lua
                    "lua_ls",
                    -- JavaScript/TypeScript
                    "ts_ls",
                    -- Python
                    "pylsp",
                    -- Rust
                    "rust_analyzer",
                    -- Go
                    "gopls",
                    -- Nix
                    "nil_ls",
                    -- Docker
                    "dockerls",
                    -- YAML
                    "yamlls",
                    -- Terraform
                    "terraformls",
                },
                handlers = {
                    -- 기본 핸들러
                    function(server_name)
                        local lspconfig = require("lspconfig")
                        local opts = {
                            on_attach = lsp_handlers.on_attach,
                            capabilities = lsp_handlers.get_capabilities(),
                        }

                        -- 서버별 설정
                        if server_name == "lua_ls" then
                            opts.settings = {
                                Lua = {
                                    diagnostics = {
                                        globals = { "vim" }
                                    }
                                }
                            }
                        elseif server_name == "ts_ls" then
                            opts.settings = {
                                typescript = {
                                    format = {
                                        enable = false  -- prettier 사용
                                    }
                                }
                            }
                        end

                        lspconfig[server_name].setup(opts)
                    end,
                }
            })
        end,
    },

    -- nvim-lspconfig: LSP 설정
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
    },
}
