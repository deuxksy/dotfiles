# MCP Neovim Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Neovim에 CodeCompanion.nvim (AI Chat)과 mcphub.nvim (MCP Hub)을 통합하고, 6개 MCP 서버를 연동

**Architecture:** mcphub.nvim이 MCP Hub 역할을 하며, 6개 MCP 서버(Z.AI Vision/Search/WebReader/GitHub, Context7, Brave Search)를 중앙 관리. CodeCompanion.nvim은 AI Chat UI로서 mcphub를 통해 MCP tools에 접근. Zero-Trust 준수를 위해 API 키는 시스템 환경변수(~/.key)에서만 로드.

**Tech Stack:** Neovim, Lua, lazy.nvim, mcphub.nvim, codecompanion.nvim, pnpm/pnpx

---

## Task 0: 사전 요구사항 확인

**Files:**
- N/A

- [ ] **Step 1: 작업 디렉토리로 이동**

```bash
cd ~/git/env
```

- [ ] **Step 2: Neovim 버전 확인**

```bash
nvim --version | grep -E "NVIM v0.9|NVIM v0.10|NVIM v0.11"
```

Expected: Neovim 0.9 이상

- [ ] **Step 3: pnpm 설치 확인**

```bash
which pnpm || (npm install -g pnpm && echo "pnpm installed")
```

Expected: pnpm 명령어可用

- [ ] **Step 4: Shell 프로필에서 ~/.key 로드 확인**

```bash
grep -q "source ~/.key" ~/.zshrc || grep -q "source ~/.key" ~/.bashrc || echo "Warning: ~/.key not sourced in shell profile"
```

Expected: ~/.key가 .zshrc 또는 .bashrc에서 source됨

---

## Task 1: 플러그인 설정 파일 생성 (mcp.lua)

**Files:**
- Create: `base/.config/nvim/lua/plugins/mcp.lua`

- [ ] **Step 1: plugins 디렉토리 확인**

```bash
ls -la base/.config/nvim/lua/plugins/
```

Expected: plugins 디렉토리 존재

- [ ] **Step 2: mcp.lua 파일 생성 (heredoc 사용)**

```bash
cat > base/.config/nvim/lua/plugins/mcp.lua << 'EOF'
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
EOF
```

Expected: 파일 생성됨 (이미 존재하면 덮어쓰기)

- [ ] **Step 3: Commit**

```bash
git add base/.config/nvim/lua/plugins/mcp.lua
git commit -m "feat: MCP 플러그인 설정 추가 (mcphub + codecompanion)"
```

---

## Task 2: 환경변수 설정 파일 확인

**Files:**
- Check: `~/.key`

- [ ] **Step 1: ~/.key 파일 존재 확인**

```bash
ls -la ~/.key
```

Expected: 파일 존재

- [ ] **Step 2: 환경변수 설정 확인**

```bash
cat ~/.key | grep -E '(Z_AI_API_KEY|CONTEXT7_API_KEY|BRAVE_API_KEY|ANTHROPIC_API_KEY)'
```

Expected: 4개 API 키 모두 설정되어 있음

- [ ] **Step 3: Shell 프로필에 ~/.key source 확인**

```bash
grep "source ~/.key" ~/.zshrc || grep "source ~/.key" ~/.bashrc
```

Expected: source ~/.key 라인 확인

- [ ] **Step 4: 없으면 추가 (선택사항)**

```bash
if ! grep -q "source ~/.key" ~/.zshrc; then
  echo "" >> ~/.zshrc
  echo "# Load environment variables" >> ~/.zshrc
  echo "source ~/.key" >> ~/.zshrc
  echo "Added 'source ~/.key' to ~/.zshrc"
fi
```

---

## Task 3: Stow로 설정 적용

**Files:**
- Modify: `~/.config/nvim/lua/plugins/mcp.lua` (symlink)

- [ ] **Step 1: Stow 적용**

```bash
stow -t ~ base
```

Expected: 완료 메시지 또는 에러 없음

- [ ] **Step 2: 심볼릭 링크 확인**

```bash
ls -la ~/.config/nvim/lua/plugins/mcp.lua
```

Expected: `~/git/env/base/.config/nvim/lua/plugins/mcp.lua`를 가리키는 심볼릭 링크

- [ ] **Step 3: Neovim 플러그인 로드 테스트**

```bash
nvim --headless -c "Lazy sync" -c "qa"
```

Expected: 플러그인 설치 진행됨

---

## Task 4: Neovim 플러그인 설치 확인

**Files:**
- N/A (Neovim internal)

- [ ] **Step 1: Neovim 시작**

```bash
nvim
```

- [ ] **Step 2: lazy.nvim 동기화**

```vim
:Lazy sync
```

Expected: mcphub.nvim, codecompanion.nvim 설치 완료

- [ ] **Step 3: 플러그인 상태 확인**

```vim
:Lazy
```

Expected:
- ✅ mcphub.nvim (loaded)
- ✅ codecompanion.nvim (loaded)

---

## Task 5: 환경변수 로드 확인

**Files:**
- N/A (Neovim internal)

- [ ] **Step 1: Neovim 내 환경변수 확인**

```vim
:echo $Z_AI_API_KEY
:echo $CONTEXT7_API_KEY
:echo $BRAVE_API_KEY
:echo $ANTHROPIC_API_KEY
```

Expected: 모든 값 출력됨 (또는 ***로 마스킹됨)

- [ ] **Step 2: 환경변수 누락 시 에러 메시지 확인**

```vim
# ~/.key에서 하나의 API 키를 일시적으로 주석 처리 후 Neovim 재시작
```

Expected: ERROR notify 메시지로 "필수 환경변수 누락" 표시

---

## Task 6: MCP Hub 상태 검증

**Files:**
- N/A (Neovim internal)

- [ ] **Step 1: MCP Hub UI 열기**

```vim
:MCPHub
```

Expected: MCP Hub UI가 열리고 6개 서버 목록 표시

- [ ] **Step 2: 서버 상태 확인 (UI)**

UI에서 각 서버의 연결 상태를 시각적으로 확인

Expected: 모든 서버가 "connected" 상태 (녹색 표시)

- [ ] **Step 3: 개별 서버 연결 테스트**

각 서버 옆의 토글 버튼으로 연결/해제 테스트

Expected: 서버가 연결/해제됨

---

## Task 7: CodeCompanion Chat 테스트

**Files:**
- N/A (Neovim internal)

- [ ] **Step 1: CodeCompanion Chat 열기**

```vim
:CodeCompanionChat
```

Expected: Chat 버퍼가 열림

- [ ] **Step 2: Chat 기능 기본 테스트**

```
Hello, can you help me?
```

Expected: AI가 응답

- [ ] **Step 3: MCP Tools 사용 테스트**

```
@zai_websearch "Neovim plugins"를 검색해줘
```

Expected: Z.AI Web Search tool이 호출됨

---

## Task 8: 롤백 절차 문서화

**Files:**
- Create: `docs/superpowers/ROLLBACK.md`

- [ ] **Step 1: 롤백 문서 작성**

```bash
mkdir -p docs/superpowers
cat > docs/superpowers/ROLLBACK.md << 'EOF'
# MCP Neovim Integration Rollback Procedure

## 설정 롤백

```bash
cd ~/git/env
git checkout base/.config/nvim/lua/plugins/mcp.lua
stow -t ~ base
```

## 플러그인 제거

```vim
:Lazy
# mcphub.nvim, codecompanion.nvim 선택 후 X로 삭제
```

## 환경변수 제거 (선택사항)

```bash
# ~/.key에서 관련 행 주석 처리
vim ~/.key
source ~/.key
```

## 완전 제거

```bash
cd ~/git/env
rm base/.config/nvim/lua/plugins/mcp.lua
stow -t ~ base
```
EOF
```

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/ROLLBACK.md
git commit -m "docs: MCP 통합 롤백 절차 문서화"
```

---

## Task 9: 최종 검증 및 정리

**Files:**
- N/A

- [ ] **Step 1: 전체 기능 테스트**

```vim
# 1. 환경변수 로드 확인
:echo $Z_AI_API_KEY

# 2. MCP Hub 상태 확인
:MCPHub

# 3. CodeCompanion Chat 테스트
:CodeCompanionChat
```

Expected: 모든 기능 정상 작동

- [ ] **Step 2: Neovim 설정 리로드 테스트**

```vim
:source ~/.config/nvim/init.lua
```

Expected: 에러 없이 리로드됨

- [ ] **Step 3: README 업데이트 (중복 방지)**

```bash
if ! grep -q "## MCP Integration" README.md; then
  cat >> README.md << 'EOF'

## MCP Integration

Neovim에 CodeCompanion.nvim과 mcphub.nvim이 통합되어 있으며, 6개 MCP 서버를 사용할 수 있습니다:

- **Z.AI Vision**: 이미지 분석
- **Z.AI Web Search**: 웹 검색
- **Z.AI Web Reader**: 웹 페이지 읽기
- **Z.AI GitHub**: GitHub 저장소 분석
- **Context7**: 문서 검색
- **Brave Search**: 대체 검색 엔진

### 사용법

```vim
:MCPHub              # MCP Hub UI 열기
:CodeCompanionChat   # AI Chat 열기
```

### 환경변수 설정

~/.key 파일에 다음 환경변수가 필요합니다 (이미 ~/.zshrc에서 source됨):

```bash
export Z_AI_API_KEY="sk-..."
export CONTEXT7_API_KEY="..."
export BRAVE_API_KEY="..."
export ANTHROPIC_API_KEY="sk-ant-..."
```

자세한 내용은 [Design Document](docs/superpowers/specs/2026-03-23-mcp-neovim-design.md)를 참고하세요.
EOF
fi
```

Expected: README에 섹션追加됨 (중복 시 스킵)

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: MCP 통합 사용법 추가"
```

---

## Testing Strategy

### Unit Tests (각 Task 내에서 수행)
- Neovim 버전 호환성 확인
- pnpm 설치 확인
- Shell 프로필 설정 확인

### Integration Tests
- MCP Hub 연결 상태 확인
- CodeCompanion Chat 기능 테스트
- MCP Tools 호출 테스트

### Manual Tests
- Neovim 시작 및 설정 로드
- Chat 기능 테스트
- 롤백 절차 검증

---

## Completion Criteria

- [ ] 사전 요구사항 확인 완료
- [ ] 플러그인 설정 파일 생성 완료
- [ ] 환경변수 설정 확인 완료
- [ ] Stow로 설정 적용 완료
- [ ] Neovim 플러그인 설치 완료
- [ ] 환경변수 로드 확인 완료
- [ ] MCP Hub 상태 검증 완료
- [ ] CodeCompanion Chat 테스트 완료
- [ ] 롤백 절차 문서화 완료
- [ ] 최종 검증 및 정리 완료

---

_작성일: 2026-03-23_
_상태: Implementation Plan (Revision 1)_
_다음 단계: Execution_
