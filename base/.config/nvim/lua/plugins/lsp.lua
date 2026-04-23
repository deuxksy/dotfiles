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
            local health = require("core.health")

            -- 자동 설치할 LSP 서버
            local servers = {
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
                -- Nix (Linux/macOS만)
                "nil_ls",
                -- Java
                "jdtls",
                -- Kotlin (Android)
                "kotlin_language_server",
                -- Gradle (Android build)
                "gradle_ls",
                -- Docker
                "dockerls",
                -- YAML
                "yamlls",
                -- Terraform
                "terraformls",
            }

            -- Windows에서 nil_ls 제외 (Nix 미지원)
            if health.is_windows then
                servers = vim.tbl_filter(function(s)
                    return s ~= "nil_ls"
                end, servers)
            end

            require("mason-lspconfig").setup({
                ensure_installed = servers,
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
