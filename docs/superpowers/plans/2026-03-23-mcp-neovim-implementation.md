# CodeCompanion.nvim + MCP Servers Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Neovim에 CodeCompanion.nvim(AI Chat)과 mcphub.nvim(MCP Hub)을 통합하고 6개 MCP 서버(Z.AI 4개, Context7, Brave Search)를 연동

**Architecture:** lazy.nvim이 두 플러그인 관리, mcphub.nvim이 MCP Hub 역할로 6개 서버 실행/관리, CodeCompanion이 AI Chat UI 제공하며 mcphub를 통해 MCP tools 접근. Zero-Trust 준수하여 시스템 환경변수만으로 API 키 관리.

**Tech Stack:** Neovim, Lua, lazy.nvim, mcphub.nvim, codecompanion.nvim, pnpm, MCP servers (Z.AI, Context7, Brave Search)

---

## File Structure

```
base/.config/nvim/
├── lua/
│   └── plugins/
│       └── mcp.lua              ← 신규 생성 (mcphub + codecompanion 통합)
└── init.lua                     ← 기존 파일 (변경 없음)
~/.key                            ← 기존 파일에 환경변수 추가
```

### 파일 책임 분리
- **mcp.lua**: MCP Hub 및 AI Chat 플러그인 설정 (단일 책임)
- **~/.key**: 시스템 환경변수 (보안 영역, Zero-Trust)

---

## Task 1: 사전 준비 - Neovim 설정 백업

**Files:**
- Backup: `~/.config/nvim/` (전체 백업)

- [ ] **Step 1: 기존 Neovim 설정 백업**

```bash
# 날짜가 붙은 백업 디렉토리 생성
cp -r ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d)
```

예상 결과: `~/.config/nvim.backup.20260323/` 디렉토리 생성

- [ ] **Step 2: 백업 확인**

```bash
ls -la ~/.config/nvim.backup.*/
```

예상 결과: 백업 디렉토리 존재 확인

- [ ] **Step 3: 커밋**

```bash
git add -A && git commit -m "chore: Neovim 설정 백업 (MCP 통합 전)"
```

---

## Task 2: 플러그인 설정 파일 생성

**Files:**
- Create: `base/.config/nvim/lua/plugins/mcp.lua`

- [ ] **Step 1: plugins 디렉토리 확인**

```bash
ls -la ~/git/env/base/.config/nvim/lua/plugins/
```

예상 결과: 디렉토리 존재, 다른 플러그인 파일들 확인 (ui.lua 등)

- [ ] **Step 2: mcp.lua 파일 생성**

```bash
nvim ~/git/env/base/.config/nvim/lua/plugins/mcp.lua
```

예상 결과: Neovim 편집기 실행, 새 빈 파일 열림

- [ ] **Step 3: mcphub.nvim 플러그인 설정 작성**

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

            -- Z.AI Zread (HTTP)
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

- [ ] **Step 4: 파일 저장 및 닫기**

Neovim에서 `:wq` 실행

예상 결과: 파일 저장됨, Neovim 종료

- [ ] **Step 5: 파일 생성 확인**

```bash
cat ~/git/env/base/.config/nvim/lua/plugins/mcp.lua
```

예상 결과: 작성한 Lua 코드 내용 확인

- [ ] **Step 6: Lua 문법 검증**

```bash
nvim --headless "+luafile ~/.config/nvim/lua/plugins/mcp.lua" +qa 2>&1 | grep -i error || echo "문법 검증 완료"
```

예상 결과: 에러 메시지 없거나 "문법 검증 완료" 출력

- [ ] **Step 7: 커밋**

```bash
cd ~/git/env
git add base/.config/nvim/lua/plugins/mcp.lua
git commit -m "feat: MCP Hub + CodeCompanion 플러그인 설정 추가

- mcphub.nvim으로 6개 MCP 서버 통합 (Z.AI 4개, Context7, Brave Search)
- CodeCompanion.nvim으로 Anthropic Claude 연동
- 환경변수 검증으로 Zero-Trust 준수

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 3: 환경변수 설정 (시스템)

**Files:**
- Modify: `~/.key`

- [ ] **Step 1: ~/.key 파일 백업**

```bash
cp ~/.key ~/.key.backup.$(date +%Y%m%d)
```

예상 결과: `~/.key.backup.20260323` 생성

- [ ] **Step 2: ~/.key 파일 편집**

```bash
vim ~/.key
```

예상 결과: 편집기 실행

- [ ] **Step 3: 환경변수 추가**

파일 끝에 다음 내용 추가:

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

**중요**: 실제 API 키 값으로 `"sk-..."`, `"..."` 부분을 교체

- [ ] **Step 4: 파일 저장 및 닫기**

Vim에서 `:wq` 실행

- [ ] **Step 5: 환경변수 로드 테스트**

```bash
source ~/.key
echo $Z_AI_API_KEY
```

예상 결과: API 키 값 출력 (또는 에러 없이 로드됨)

- [ ] **Step 6: ~/.key gitignore 확인**

```bash
git -C ~/git/env check-ignore -v ~/.key
```

예상 결과: `.gitignore`에 포함되어 있어야 함

---

## Task 4: Stow로 설정 적용

**Files:**
- Symlink: `~/.config/nvim/lua/plugins/mcp.lua` → `~/git/env/base/.config/nvim/lua/plugins/mcp.lua`

- [ ] **Step 1: Stow 적용 전 상태 확인**

```bash
ls -la ~/.config/nvim/lua/plugins/ | grep mcp || echo "mcp.lua 없음 (정상)"
```

예상 결과: mcp.lua가 없거나 기존 심볼릭 링크 확인

- [ ] **Step 2: Stow 적용**

```bash
cd ~/git/env
stow -t ~ base
```

예상 결과: 심볼릭 링크 생성됨

- [ ] **Step 3: 심볼릭 링크 확인**

```bash
ls -la ~/.config/nvim/lua/plugins/mcp.lua
```

예상 결과: 심볼릭 링크가 `~/git/env/base/.config/nvim/lua/plugins/mcp.lua`를 가리킴

- [ ] **Step 4: 커밋 (Stow 변경사항)**

```bash
git add -A && git commit -m "chore: Stow로 MCP 플러그인 설정 적용"
```

---

## Task 5: Neovim 플러그인 설치 및 동기화

**Files:**
- No file modifications (lazy.nvim state)

- [ ] **Step 1: Neovim 실행 및 Lazy 첫 동기화**

```bash
nvim --headless "+Lazy! sync" +qa
```

예상 결과: lazy.nvim이 플러그인들을 설치하고 동기화함

- [ ] **Step 2: 설치 성공 확인**

```bash
nvim --headless "+Lazy! log" +qa | grep -E "(mcphub|codecompanion)" || echo "플러그인 로그 확인 필요"
```

예상 결과: 두 플러그인이 설치된 로그 확인

- [ ] **Step 3: 커밋 (Lazy 상태 변경사항, 있을 경우)**

```bash
git add -A
git status
# 만약 lazy-lock.json 변경이 있다면 커밋
```

---

## Task 6: 환경변수 로드 및 Neovim 재시작

**Files:**
- No file modifications (runtime environment)

- [ ] **Step 1: 환경변수 로드**

```bash
source ~/.key
```

예상 결과: 쉘에 에러 없음

- [ ] **Step 2: 환경변수 설정 확인**

```bash
env | grep -E "(Z_AI_API_KEY|CONTEXT7_API_KEY|BRAVE_API_KEY|ANTHROPIC_API_KEY)"
```

예상 결과: 4개 환경변수 모두 출력됨

- [ ] **Step 3: Neovim 테스트 실행 (백그라운드)**

```bash
nvim --headless -c "lua print(vim.inspect(require('mcphub')))" -c "qa"
```

예상 상태:
- 성공: mcphub 모듈 로드됨 (에러 없이 종료)
- 실패: 에러 메시지 출력 (환경변수 누락 또는 mcphub 설치 안 됨)

---

## Task 7: MCP Hub 상태 검증

**Files:**
- No file modifications (verification only)

- [ ] **Step 1: Neovim 실행 및 MCP Hub 열기**

```bash
nvim
```

Neovim이 실행되면 `:MCPHub` 명령어 실행

- [ ] **Step 2: MCP Hub UI 확인**

예상 결과:
- MCP Hub UI가 열림
- 6개 MCP 서버 목록 표시:
  - zai_vision (stdio)
  - zai_websearch (HTTP)
  - zai_webreader (HTTP)
  - zai_github (HTTP)
  - context7 (HTTP)
  - brave_search (stdio)

- [ ] **Step 3: 각 서버 연결 상태 확인**

각 서버 옆에 초록색 체크표(✅) 또는 연결 상태 표시

- [ ] **Step 4: Lua로 상태 확인**

```vim
:lua print(vim.inspect(require('mcphub').get_servers_status()))
```

예상 결과: 6개 서버 모두 상태 테이블 출력

- [ ] **Step 5: Neovim 종료**

```
:qa
```

---

## Task 8: CodeCompanion Chat 테스트

**Files:**
- No file modifications (verification only)

- [ ] **Step 1: Neovim 실행 및 CodeCompanionChat 열기**

```bash
nvim
```

`:CodeCompanionChat` 명령어 실행

- [ ] **Step 2: Chat 창이 열리는지 확인**

예상 결과:
- 우측 또는 분할된 창에 Chat 패널 열림
- Anthropic Claude adapter 선택 가능

- [ ] **Step 3: 간단한 메시지 전송 테스트**

Chat 창에 입력:
```
Hello, this is a test message.
```

- [ ] **Step 4: 응답 확인**

예상 결과: Claude가 응답 반환

- [ ] **Step 5: MCP tools 사용 가능성 테스트**

Chat 창에 입력:
```
Please use the web search tool to find information about Neovim plugins.
```

- [ ] **Step 6: tools 목록에서 zai_websearch 또는 brave_search 선택**

- [ ] **Step 7: 검색 실행 및 결과 확인**

예상 결과: 검색 결과가 Chat에 표시됨

- [ ] **Step 8: Neovim 종료**

```
:qa
```

- [ ] **Step 9: 커밋 (설정 완료)**

```bash
cd ~/git/env
git add -A
git commit -m "chore: MCP + CodeCompanion 통합 설정 완료

검증 완료:
- MCP Hub: 6개 서버 모두 연결 성공
- CodeCompanion Chat: 정상 작동
- MCP tools: 웹 검색 기능 확인

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 9: 롤백 절차 정의 (문제 발생 시)

**Files:**
- No file modifications (documentation only)

- [ ] **Step 1: 롤백 절차 문서화**

```bash
cat >> ~/git/env/README.md << 'EOF'

## MCP Integration Rollback

If issues occur with MCP integration:

1. 복구:
   \`\`\`bash
   rm ~/.config/nvim
   mv ~/.config/nvim.backup.* ~/.config/nvim
   \`\`\`

2. 플러그인 재설치:
   \`\`\`vim
   :Lazy restore
   \`\`\`

3. 환경변수 제거 (필요시):
   \`\`\`bash
   vim ~/.key  # 관련 export 줄 삭제
   source ~/.key
   \`\`\`

EOF
```

예상 결과: README.md에 롤백 절차 추가됨

- [ ] **Step 2: 커밋**

```bash
cd ~/git/env
git add README.md
git commit -m "docs: MCP Integration 롤백 절차 추가"
```

---

## Task 10: 최종 검증 및 정리

**Files:**
- No file modifications (final verification)

- [ ] **Step 1: Neovim 설정 재로드**

```bash
nvim --head "+source ~/.config/nvim/init.lua" +qa
```

- [ ] **Step 2: 전체 기능 스크린샷트 테스트**

```bash
nvim
```

테스트 항목:
1. `:MCPHub` - MCP Hub UI 열기
2. `:CodeCompanionChat` - Chat 열기
3. Chat에서 간단한 질문/명령 테스트
4. `:Lazy` - 플러그인 상태 확인

- [ ] **Step 3: 정리 작업**

```bash
cd ~/git/env
git status
git log --oneline -5
```

예상 결과: 최근 5개 커밋 확인, 작업 흐름 파악

- [ ] **Step 4: 문서 정리 (필요시)**

```bash
git log --oneline --graph -10
```

---

## 완료 조건

모든 작업 완료 후:
- ✅ Neovim 실행 시 mcphub.nvim이 6개 MCP 서버 연결
- ✅ `:MCPHub` 명령어로 UI 및 서버 상태 확인 가능
- ✅ `:CodeCompanionChat`으로 AI Chat 사용 가능
- ✅ Chat에서 MCP tools (웹 검색, 이미지 분석 등) 호출 가능
- ✅ 환경변수는 ~/.key에서만 관리 (Zero-Trust 준수)
- ✅ 백업부터 롤백까지 모든 절차 문서화

## 문제 해결 가이드

| 문제 증상 | 가능한 원인 | 해결 방법 |
|---------|-----------|---------|
| 환경변수 에러 | ~/.key에 키 미기입 | 실제 API 키로 교체 후 `source ~/.key` |
| MCP Hub 초기화 실패 | 플러그인 미설치 | `:Lazy sync`로 설치 |
| 서버 연결 실패 | API 키 만료 또는 네트워크 | ~/.key의 API 키 확인 |
| CodeCompanion 작동 안함 | ANTHROPIC_API_KEY 누락 | ~/.key에 키 추가 |
| pnpx 명령 없음 | pnpm 미설치 | `brew install pnpm` (macOS) |
| Stow 적용 실패 | 기존 링크 충돌 | `rm ~/.config/nvim/lua/plugins/mcp.lua` 후 재시도 |

---

_작성일: 2026-03-23_
_관련 스펙: docs/superpowers/specs/2026-03-23-mcp-neovim-design.md_
_예상 소요 시간: 30-45분_
_난이도: 중간 (MCP 서버 설정 이해 필요)_
