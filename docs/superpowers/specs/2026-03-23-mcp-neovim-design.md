# CodeCompanion.nvim + mcphub.nvim + MCP Servers Integration Design

## Overview

Neovim에 CodeCompanion.nvim (AI Chat)과 mcphub.nvim (MCP Hub)을 통합하고, 6개 MCP 서버를 연동하는 설정입니다.

### 목표

- CodeCompanion.nvim 전체 기능 활성화
- mcphub.nvim을 통한 MCP 서버 중앙 관리
- 6개 MCP 서버 통합 (Z.AI 4개, Context7, Brave Search)
- pnpm 기반 패키지 관리
- Tailscale Aperture를 통한 AI Gateway 라우팅
- Zero-Trust 준수 (시스템 환경변수 기반 API 키 관리)

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Neovim                           │
│  ┌──────────────────────────────────────────────┐  │
│  │        lazy.nvim (Plugin Manager)           │  │
│  │  ┌────────────────┐  ┌──────────────────┐  │  │
│  │  │ mcphub.nvim    │  │codecompanion.nvim│  │  │
│  │  │ (MCP Hub)      │  │  (AI Chat)       │  │  │
│  │  └────────────────┘  └──────────────────┘  │  │
│  │         │                    ↑             │  │
│  │         │ dependency         │             │  │
│  │         └────────────────────┘             │  │
│  └──────────────────────────────────────────────┘  │
│                                                      │
│  MCP Hub 관리 계층:                                   │
│  ┌──────────────────────────────────────────────┐  │
│  │ mcphub.setup({                                │  │
│  │   mcp_servers = {                             │  │
│  │     zai_vision (stdio),                       │  │
│  │     zai_websearch (HTTP),                      │  │
│  │     zai_webreader (HTTP),                     │  │
│  │     zai_github (HTTP),                        │  │
│  │     context7 (HTTP),                          │  │
│  │     brave_search (stdio)                      │  │
│  │   }                                           │  │
│  │ })                                            │  │
│  └──────────────────────────────────────────────┘  │
│         │                    ↕                     │
│  ┌─────▼─────┐         ┌──────────┐              │
│  │  ~/.key   │         │ Tailscale│              │
│  │ (env var) │         │ Aperture │              │
│  └───────────┘         └──────────┘              │
└─────────────────────────────────────────────────────┘
```

### 계층별 역할

1. **lazy.nvim**: 두 플러그인의 생명주기 관리
2. **mcphub.nvim**: MCP Hub 역할, 6개 서버 실행/관리
3. **codecompanion.nvim**: AI Chat UI, mcphub를 통해 MCP tools 접근
4. **~/.key**: 시스템 환경변수 로드 (Zero-Trust)
5. **Tailscale Aperture**: HTTP MCP 서버들의 외부 API 호출 프록시

---

## File Structure

```
base/.config/nvim/
├── lua/
│   └── plugins/
│       └── mcp.lua              ← 신규 (mcphub + codecompanion 통합)
└── init.lua
```

### plugins/mcp.lua

```lua
return {
  -- MCP Hub
  {
    "Smart-pkgs/mcphub.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "MCP" },
    config = function()
      -- 환경변수 검증 (실패 시 초기화 중단)
      local required_env_vars = {
        Z_AI_API_KEY = "Z.AI API Key",
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
                Z_AI_API_KEY = vim.env.Z_AI_API_KEY,
                Z_AI_MODE = "ZAI"
              }
            },

            -- Z.AI Web Search (HTTP)
            zai_websearch = {
              type = "http",
              url = "https://api.z.ai/api/mcp/search/mcp",
              headers = {
                Authorization = "Bearer " .. vim.env.Z_AI_API_KEY
              }
            },

            -- Z.AI Web Reader (HTTP)
            zai_webreader = {
              type = "http",
              url = "https://api.z.ai/api/mcp/web_reader/mcp",
              headers = {
                Authorization = "Bearer " .. vim.env.Z_AI_API_KEY
              }
            },

            -- Z.AI GitHub/Zread (HTTP)
            zai_github = {
              type = "http",
              url = "https://api.z.ai/api/mcp/zread/mcp",
              headers = {
                Authorization = "Bearer " .. vim.env.Z_AI_API_KEY
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
      "Smart-pkgs/mcphub.nvim",
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
```

### ~/.key (시스템 환경변수)

```bash
# MCP 서버용 API 키
export Z_AI_API_KEY="sk-..."
export CONTEXT7_API_KEY="..."
export BRAVE_API_KEY="..."

# CodeCompanion용 LLM API 키
export ANTHROPIC_API_KEY="sk-ant-..."

# 선택사항: Tailscale Aperture (HTTP 프록시)
# export HTTP_PROXY="https://your-aperture-url"
# export HTTPS_PROXY="https://your-aperture-url"
```

---

## MCP Servers Configuration

### 1. Z.AI Vision (stdio)

- **Transport**: stdio
- **Command**: `pnpx @z_ai/mcp-server`
- **환경변수**:
  - `Z_AI_API_KEY`
  - `Z_AI_MODE=ZAI`

### 2. Z.AI Web Search (HTTP)

- **Transport**: HTTP
- **URL**: `https://api.z.ai/api/mcp/search/mcp`
- **인증**: Bearer Token (Z_AI_API_KEY)

### 3. Z.AI Web Reader (HTTP)

- **Transport**: HTTP
- **URL**: `https://api.z.ai/api/mcp/web_reader/mcp`
- **인증**: Bearer Token (Z_AI_API_KEY)

### 4. Z.AI Zread (HTTP)

- **Transport**: HTTP
- **URL**: `https://api.z.ai/api/mcp/zread/mcp`
- **인증**: Bearer Token (Z_AI_API_KEY)
- **참고**: GitHub 저장소 분석 및 코드 검색 기능 제공

### 5. Context7 (HTTP)

- **Transport**: HTTP
- **URL**: `https://mcp.context7.com/mcp`
- **인증**: Header `CONTEXT7_API_KEY`

### 6. Brave Search (stdio)

- **Transport**: stdio (pnpx 실행)
- **Command**: `pnpx @brave/brave-search-mcp-server`
- **환경변수**: `BRAVE_API_KEY`

---

## Data Flow

```
사용자 입력 (Neovim)
    ↓
CodeCompanion Chat
    ↓
mcphub (MCP Hub)
    ↓
    ├─→ zai_vision (stdio) → pnpx 프로세스 → Z.AI API
    ├─→ zai_websearch (HTTP) → HTTP 요청 → https://api.z.ai/...
    ├─→ zai_webreader (HTTP) → HTTP 요청 → https://api.z.ai/...
    ├─→ zai_github (HTTP) → HTTP 요청 → https://api.z.ai/...
    ├─→ context7 (HTTP) → HTTP 요청 → https://mcp.context7.com/...
    └─→ brave_search (stdio) → pnpx 프로세스 → Brave API
         ↓
    (선택사항) HTTP_PROXY/HTTPS_PROXY 환경변수
         ↓
    외부 AI API
```

---

## Error Handling

### 1단계: 환경변수 검증

Neovim 시작 시 필수 환경변수 존재 확인:
- `Z_AI_API_KEY`
- `CONTEXT7_API_KEY`
- `BRAVE_API_KEY`
- `ANTHROPIC_API_KEY`

선택사항:
- `HTTP_PROXY` / `HTTPS_PROXY` (Tailscale Aperture 사용 시)

### 2단계: MCP Hub 초기화 실패 처리

- `pcall()`로 감싸서 초기화 실패 시 로깅
- 개별 서버 실패가 전체 Hub 중단 방지

### 3단계: 장애 격리

- 한 MCP 서버 실패가 다른 서버에 영향 없도록 구성
- 사용자에게 명확한 에러 메시지 제공

---

## Testing & Verification

### 1단계: 의존성 설치 확인

```vim
:Lazy
```

예상 결과:
- ✅ mcphub.nvim (loaded)
- ✅ codecompanion.nvim (loaded)

### 2단계: 환경변수 로드 확인

```vim
:echo $Z_AI_API_KEY
:echo $CONTEXT7_API_KEY
:echo $BRAVE_API_KEY
```

### 3단계: MCP Hub 상태 확인

```vim
:MCPHub
```

예상 결과:
- MCP Hub UI에서 6개 서버 상태 확인
- 각 서버가 정상적으로 connected 상태여야 함

또는 Lua로 직접 확인:
```vim
:lua print(vim.inspect(require('mcphub').get_servers_status()))
```

### 4단계: CodeCompanion Chat 테스트

```vim
:CodeCompanionChat
```

테스트 시나리오:
1. 이미지 설명 (Z.AI Vision)
2. 웹 검색 (Z.AI Web Search, Brave Search)
3. 웹 페이지 읽기 (Z.AI Web Reader)
4. GitHub 정보 (Z.AI GitHub)
5. 문서 검색 (Context7)

---

## Deployment Steps

1. **파일 생성**
   ```bash
   nvim ~/git/env/base/.config/nvim/lua/plugins/mcp.lua
   ```

2. **설정 적용** (Stow)
   ```bash
   cd ~/git/env
   stow -t ~ base
   ```

3. **Neovim 재시작 및 lazy.nvim 동기화**
   ```vim
   :Lazy sync
   ```

4. **환경변수 설정**
   ```bash
   # ~/.key 에 실제 API 키 입력
   vim ~/.key

   # 소스 적용
   source ~/.key
   ```

5. **최종 검증**
   ```vim
   :MCPHub  -- MCP Hub UI 및 서버 상태 확인
   :CodeCompanionChat  -- AI Chat 테스트
   ```

---

## Maintenance

### MCP 서버 업데이트

- **stdio 서버** (pnpx): 자동 최신 버전 유지
- **HTTP 서버**: 서버 측 업데이트 자동 반영

### 플러그인 업데이트

```vim
:Lazy update
```

### 설정 롤백

```bash
cd ~/git/env
git checkout base/.config/nvim/lua/plugins/mcp.lua
stow -t ~ base
```

---

## Design Decisions

### Q1: 왜 단일 파일 (mcp.lua)인가?

**A**: MCP 설정은 하나의 목적 (AI 도구 통합)을 가지므로, 단일 파일로 통합 관리하는 것이 실무적입니다. 파일이 커지거나 관리가 어려워지면 분리 고려.

### Q2: 왜 snake_case 인가?

**A**: Neovim 설정 표준에 따르며, 따옴표 없이 간결하게 작성 가능합니다. 외부 서비스 이름이지만, Lua 설정에서는 snake_case가 더 자연스럽습니다.

### Q3: pnpx에 -y 옵션이 없는 이유는?

**A**: pnpm/pnpx는 기본적으로 확인 없이 실행되며, `-y` 옵션이 존재하지 않습니다.

### Q4: HTTP 서버들을 왜 URL 방식으로 설정했나?

**A**: Z.AI HTTP 서버들은 원격 HTTP 엔드포인트를 제공하며, 별도 로컬 프로세스 실행 없이 URL로 직접 통신하는 것이 더 간단하고 안정적입니다.

### Q5: Tailscale Aperture 프록시는 어떻게 적용하나?

**A**: HTTP MCP 서버들의 프록시는 시스템 환경변수(`HTTP_PROXY`, `HTTPS_PROXY`)를 통해 적용됩니다. mcphub.nvim의 `http_proxy` 옵션은 현재 지원되지 않을 수 있으므로, 프록시가 필요한 경우 시스템 환경변수를 설정하세요.

---

## Security Considerations

### Zero-Trust 준수

- ❌ API 키를 설정 파일에 직접 저장 금지
- ✅ 시스템 환경변수만 참조 (`vim.env.XXX`)
- ✅ `~/.key` 파일은 `.gitignore`로 보호
- ✅ 환경변수 누락 시 초기화 중단 (fail-fast)

### Tailscale Aperture 활용

- HTTP MCP 서버들의 외부 API 호출 시 프록시 경유 (선택사항)
- 시스템 환경변수 `HTTP_PROXY`/`HTTPS_PROXY`로 설정
- 중앙 집중식 인증 관리
- 감사 및 로깅 용이

### 하드코딩 검증

```lua
-- 설정 파일 내 API 키 하드코딩 방지 검증 로직
local function prevent_hardcoded_keys()
  local config_file = debug.getinfo(1).source:sub(2)
  local content = vim.fn.readfile(config_file)

  for _, line in ipairs(content) do
    if line:match("API_KEY%s*=%s*['\"]") then
      vim.notify("하드코딩된 API 키 감지! 즉시 제거하세요.", vim.log.levels.ERROR)
    end
  end
end
```

---

## Future Enhancements

1. **새 MCP 서버 추가**: `mcp_servers` 테이블에 추가
2. **CodeCompanion 커스텀 프롬프트**: 프로젝트 특화된 프롬프트 작성
3. **LLM Adapter 구성**: Anthropic, OpenAI 등 다양한 LLM 지원

---

_작성일: 2026-03-23_
_스테이터: Spec Review (Revision 1)_
_다음 단계: Spec 재검토_
