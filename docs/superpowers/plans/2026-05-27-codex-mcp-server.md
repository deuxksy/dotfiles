# Codex MCP Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude Code에 Codex CLI를 MCP 서버로 등록하여 GPT 계열 모델을 Claude 작업 흐름에 통합

**Architecture:** `codex mcp-server`를 stdio 기반 MCP 서버로 실행. Claude Code의 `settings.json`에 `mcpServers` 항목 추가. 권한은 `settings.local.json`에 자동 승인 추가.

**Tech Stack:** Codex CLI v0.133.0 (NixOS), Claude Code, MCP stdio protocol

---

### Task 1: MCP 서버 설정 추가

**Files:**
- Modify: `~/.claude/settings.json` — `mcpServers` 섹션 추가

현재 `settings.json`에는 `mcpServers` 섹션이 없음. 최상위 레벨에 추가.

- [ ] **Step 1: settings.json에 mcpServers 추가**

`~/.claude/settings.json`의 `"theme": "dark"` 앞에 다음 섹션 추가:

```json
"mcpServers": {
  "codex": {
    "command": "codex",
    "args": ["mcp-server"]
  }
},
```

- [ ] **Step 2: JSON 유효성 검증**

Run: `python3 -c "import json; json.load(open('/home/crong/.claude/settings.json')); print('valid')"`
Expected: `valid`

- [ ] **Step 3: Claude Code 재시작 후 MCP 서버 연결 확인**

Claude Code를 재시작한 후, MCP 서버 목록에서 `codex`가 보이는지 확인.

Run: `/mcp` (Claude Code 내부 명령)
Expected: codex 서버가 목록에 표시, `codex`, `codex-reply` 도구 2개 노출

- [ ] **Step 4: 기본 도구 호출 테스트**

Claude Code에서 간단한 테스트 호출:

```
mcp__codex__codex 도구를 사용해서 prompt="echo hello" sandbox="read-only" 로 호출
```

Expected: GPT-5.5 모델로 응답 반환, threadId와 content 포함

- [ ] **Step 5: 커밋**

```bash
git add docs/superpowers/specs/2026-05-27-codex-mcp-server-design.md
git commit -m "feat: codex MCP 서버 설정 추가 - Claude Code에 Codex CLI 통합"
```

---

### Task 2: 권한 자동 승인 추가

**Files:**
- Modify: `~/.claude/settings.local.json:3-57` — `permissions.allow` 배열에 항목 추가

- [ ] **Step 1: settings.local.json에 codex 권한 추가**

`~/.claude/settings.local.json`의 `"permissions"` → `"allow"` 배열 끝(`"mcp__filesystem__directory_tree"` 뒤)에 추가:

```json
"mcp__codex__*"
```

- [ ] **Step 2: JSON 유효성 검증**

Run: `python3 -c "import json; json.load(open('/home/crong/.claude/settings.local.json')); print('valid')"`
Expected: `valid`

- [ ] **Step 3: 권한 동작 확인**

Claude Code 재시작 후 `codex` 도구 호출 시 권한 프롬프트 없이 자동 승인되는지 확인.

---

### Task 3: 모델별 사용 패턴 검증

**Files:** 없음 (수동 테스트)

- [ ] **Step 1: 기본 모델(gpt-5.5) 리뷰 테스트**

```
codex 도구: prompt="Review this code: def add(a, b): return a + b", sandbox="read-only"
```

Expected: config.toml 기본값 gpt-5.5로 응답

- [ ] **Step 2: 코딩 특화 모델(gpt-5.3-codex) 테스트**

```
codex 도구: prompt="Write a Python function to reverse a linked list", model="gpt-5.3-codex", sandbox="workspace-write", approval-policy="on-failure"
```

Expected: gpt-5.3-codex 모델로 응답

- [ ] **Step 3: 경량 모델(gpt-5.4-mini) 탐색 테스트**

```
codex 도구: prompt="What does this project do?", model="gpt-5.4-mini", sandbox="read-only"
```

Expected: gpt-5.4-mini 모델로 빠른 응답

- [ ] **Step 4: codex-reply 대화 continuation 테스트**

Step 1에서 반환된 threadId를 사용:

```
codex-reply 도구: threadId="<Step 1의 threadId>", prompt="Can you elaborate on edge cases?"
```

Expected: 같은 세션 컨텍스트에서 이어서 응답
