return {
  -- MCP Hub
  {
    "ravitemer/mcphub.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "MCP" },
    config = function()
      -- 환경변수 검증 (실패 시 초기화 중단)
      local required_env_vars = {
        ZAI_API_KEY = "Z.AI API Key",
        CONTEXT7_API_KEY = "Context7 API Key",
        BRAVE_API_KEY = "Brave API Key",
        ANTHROPIC_API_KEY = "Anthropic API Key (CodeCompanion용)"
      }

      for var, name in pairs(required_env_vars) do
        if vim.env[var] == nil then
          vim.notify(
            string.format("필수 환경변수 누락: %s (%s) - ~/.key 확인 필요", name, var),
            vim.log.levels.ERROR
          )
          return -- 초기화 중단
        end
      end

      -- MCP Hub 초기화
      local ok, err = pcall(function()
        require("mcphub").setup({
          mcp_servers = {
            -- Z.AI Vision (stdio)
            zai_vision = {
              command = "pnpx",
              args = { "@z_ai/mcp-server" },
              env = {
                ZAI_API_KEY = vim.env.ZAI_API_KEY,
                Z_AI_MODE = "ZAI"
              }
            },

            -- Z.AI Web Search (HTTP)
            zai_websearch = {
              type = "http",
              url = "https://api.z.ai/api/mcp/search/mcp",
              headers = {
                Authorization = "Bearer " .. vim.env.ZAI_API_KEY
              }
            },

            -- Z.AI Web Reader (HTTP)
            zai_webreader = {
              type = "http",
              url = "https://api.z.ai/api/mcp/web_reader/mcp",
              headers = {
                Authorization = "Bearer " .. vim.env.ZAI_API_KEY
              }
            },

            -- Z.AI GitHub/Zread (HTTP)
            zai_github = {
              type = "http",
              url = "https://api.z.ai/api/mcp/zread/mcp",
              headers = {
                Authorization = "Bearer " .. vim.env.ZAI_API_KEY
              }
            },

            -- Context7 (HTTP)
            context7 = {
              type = "http",
              url = "https://mcp.context7.com/mcp",
              headers = {
                ["CONTEXT7_API_KEY"] = vim.env.CONTEXT7_API_KEY
              }
            },

            -- Brave Search (stdio)
            brave_search = {
              command = "pnpx",
              args = { "@brave/brave-search-mcp-server" },
              env = {
                BRAVE_API_KEY = vim.env.BRAVE_API_KEY
              }
            }
          }
        })
      end)

      if not ok then
        vim.notify("MCP Hub 초기화 실패: " .. err, vim.log.levels.ERROR)
      end
    end,
  },

  -- AI Chat
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "ravitemer/mcphub.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter"
    },
    opts = {
      adapters = {
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            env = {
              api_key = vim.env.ANTHROPIC_API_KEY,
            }
          })
        end,
      },
      strategies = {
        chat = {
          adapter = "anthropic",
        },
        inline = {
          adapter = "anthropic",
        },
        agent = {
          adapter = "anthropic",
        },
      }
    }
  }
}
