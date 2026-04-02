--------------------------------------------------------------------------------
-- 코드 완성 (nvim-cmp)
--------------------------------------------------------------------------------
return {
    -- nvim-cmp: 완성 엔진
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            -- 완성 소스
            "hrsh7th/cmp-nvim-lsp",      -- LSP
            "hrsh7th/cmp-buffer",         -- 버퍼
            "hrsh7th/cmp-path",           -- 경로
            "hrsh7th/cmp-cmdline",        -- 명령행
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            -- friendly-snippets 로드
            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer", keyword_length = 3 },  -- 3글자 이상일 때만 버퍼 완성
                    { name = "path" },
                }),
            })

            -- 명령행 완성
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path" }
                }, {
                    { name = "cmdline" }
                })
            })
        end,
    },

    -- cmp-git: Git 완성
    {
        "petertriho/cmp-git",
        dependencies = { "hrsh7th/nvim-cmp" },
        config = function()
            require("cmp_git").setup()
        end,
        ft = { "gitcommit", "octo" },
    },
}
