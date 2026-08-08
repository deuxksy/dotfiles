# nvim AI 기능 제거 설계

- **날짜**: 2026-08-08
- **상태**: 승인됨
- **대상**: `base/.config/nvim/`

## 목차

- [배경](#배경)
- [스코프](#스코프)
- [설계](#설계)
- [검증](#검증)

## 배경

AI 활용이 nvim 내장 플러그인(chat/inline/agent)에서 외부 도구(Claude Code, Antigravity CLI)로 이동했다. nvim 내 AI 플러그인은 더 이상 사용하지 않으므로 제거하고, nvim은 순수 에디터(LSP/포맷/린트) 역할만 유지한다.

제거 대상은 `lua/plugins/mcp.lua` 한 파일에 집중되어 있다.

| 플러그인 | 역할 |
| :--- | :--- |
| `ravitemer/mcphub.nvim` | MCP 서버 6개 관리 (z.ai vision/websearch/webreader/github, context7, brave search) |
| `olimorris/codecompanion.nvim` | AI chat/inline/agent (Anthropic 어댑터) |

전체 설정 grep 검증 결과, 위 2개 플러그인 외 AI 관련 설정(cmp source, keymap, autocmd, lualine component)은 존재하지 않는다.

## 스코프

### 제거

- `lua/plugins/mcp.lua` — 파일 삭제
- `lazy-lock.json` — `codecompanion.nvim`, `mcphub.nvim` 엔트리 2줄 제거

### 유지

- `docs/superpowers/` 아래 mcp-neovim 통합 문서 (plans 2개, spec 1개, ROLLBACK.md) — 이력으로 보존
- `~/.key` env vars (`Z_AI_API_KEY`, `CONTEXT7_API_KEY`, `BRAVE_API_KEY`, `ANTHROPIC_API_KEY`) — Claude Code zai-mcp-server, hermes-agent가 공유 사용
- `plenary.nvim`, `nvim-treesitter` — telescope, todo-comments 등이 공유 의존

## 설계

### 접근법: 수동 선언적 제거

dotfiles repo는 `lazy-lock.json`을 커밋 대상으로 관리하므로, lock 파일도 수동으로 편집해 declarative 일관성을 유지한다. lazy.nvim 자동 clean(`:Lazy clean`)은 lock 파일 전체를 재작성해 무관한 diff가 섞일 수 있어 사용하지 않는다.

### 변경

| 파일 | 변경 |
| :--- | :--- |
| `lua/plugins/mcp.lua` | 파일 삭제 |
| `lazy-lock.json` | 2엔트리 제거 (line 10, 19) |

`init.lua`는 `lazy.setup("plugins")`로 `lua/plugins/`를 자동 import하므로 수정 불필요. 다른 파일에 `require("mcphub")` / `require("codecompanion...")` 참조가 없어 dangling reference 위험도 없다.

### 에러 케이스

- 제거 후 MCP 서버용 `pnpx` on-demand 패키지(`@z_ai/mcp-server`, `@brave/brave-search-mcp-server`) 호출 경로는 mcp.lua 삭제로 자연 소멸
- 다음 nvim 실행 시 lazy.nvim이 고아 플러그인 디렉토리 clean을 제안 — 정상 동작이며 수락하면 로컬 정리 완료

## 검증

1. `grep -c "mcphub\|codecompanion" lazy-lock.json` → 0
2. `grep -rn "mcphub\|codecompanion" lua/` → 매치 없음
3. `nvim --headless "+lua print('startup ok')" +qa` → 에러 없이 기동
4. `git diff --stat` — 의도한 파일만 변경 확인
