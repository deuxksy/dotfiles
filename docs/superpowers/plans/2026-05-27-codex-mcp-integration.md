# Codex MCP 하이브리드 연결 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Codex PRO(gpt-5.5)를 Claude Code의 서브 에이전트로 연결하는 MCP+Bash 하이브리드 환경 구성

**Architecture:** `codex mcp-server`(stdio)로 MCP 도구(`codex`/`codex-reply`)를 노출하고, `codex exec`/`codex exec review`는 Bash로 직접 호출. Claude Code가 상황에 따라 경로를 자동 선택.

**Tech Stack:** Codex CLI v0.133.0, Claude Code, GNU Stow

---

### Task 1: 규칙 파일 stow 배포

**Files:**
- Deployed: `~/.claude/rules/10-multi-agent.md` (from `base/.claude/rules/10-multi-agent.md`)

- [ ] **Step 1: stow로 base 패키지 재배포**

```bash
cd /Users/crong/git/dotfiles && stow -t ~ base
```

- [ ] **Step 2: 배포 확인**

```bash
ls -la ~/.claude/rules/10-multi-agent.md
```

Expected: symlink → `/Users/crong/git/dotfiles/base/.claude/rules/10-multi-agent.md`

---

### Task 2: Codex AGENTS.md에 Claude 위임 컨텍스트 추가

**Files:**
- Modify: `axiom/.codex/AGENTS.md:91-92` (파일 끝에 섹션 추가)

- [ ] **Step 1: Claude→Codex 위임 컨텍스트 섹션 추가**

`axiom/.codex/AGENTS.md` 파일 끝(User Rules Index 테이블 이후)에 다음 섹션 추가:

```markdown

## Claude → Codex 위임

Claude Code에서 MCP/Bash로 위임된 작업을 수행할 때 참고.

### 위임 시나리오

1. **검증**: Claude가 작성한 코드의 리뷰/검증 요청
2. **교차 비교**: 동일 프롬프트에 대한 결과 비교
3. **코드 생성**: Claude가 설계한 내용의 구현 위임

### 사용 가능 모델

| 모델 | 용도 |
| :--- | :--- |
| `gpt-5.5` | 기본, 복잡한 분석/설계 |
| `gpt-5.4` | 표준 코딩 작업 |
| `gpt-5.4-mini` | 빠른 검증, 가벼운 작업 |
| `gpt-5.3-codex` | 코드 특화 작업 |
| `gpt-5.2` | 경량 작업 |

### Claude Code와의 협업 규칙

- Claude에서 위임된 작업은 해당 프로젝트의 코딩 표준(rules/04-coding-standard.md) 준수
- 결과는 간결하게 요약하여 반환 (불필요한 설명 생략)
- 파일 수정 시 변경 사항을 명확히 표시
```

- [ ] **Step 2: 파일 내용 확인**

```bash
tail -30 /Users/crong/git/dotfiles/axiom/.codex/AGENTS.md
```

Expected: 추가한 섹션이 정상적으로 출력됨

- [ ] **Step 3: 커밋**

```bash
git add axiom/.codex/AGENTS.md
git commit -m "feat(codex): add Claude delegation context to AGENTS.md"
```

---

### Task 3: MCP 경로 검증 — codex 도구 호출

**Files:** 없음 (기능 검증만)

- [ ] **Step 1: MCP 서버 핸드셰이크 재확인**

```bash
printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"0.1.0"}}}\n{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}\n' | perl -e 'alarm 15; exec @ARGV' -- codex mcp-server 2>&1 | cat
```

Expected: `codex`와 `codex-reply` 두 도구가 포함된 JSON 응답

- [ ] **Step 2: Claude Code에서 MCP 도구 호출 테스트**

Claude Code 세션에서 다음 호출 수행:

```
mcp__codex__codex(prompt="echo hello world를 출력하는 Python 스크립트를 작성해줘", model="gpt-5.4-mini", sandbox="workspace-write", approval-policy="on-failure")
```

Expected: `threadId`와 `content`가 포함된 응답

- [ ] **Step 3: codex-reply로 후속 질문 테스트**

Step 2에서 받은 `threadId`를 사용:

```
mcp__codex__codex-reply(threadId="<step2의 threadId>", prompt="이 코드에 타입 힌트를 추가해줘")
```

Expected: 동일 `threadId`로 후속 응답 반환

---

### Task 4: Bash 경로 검증 — codex exec review

**Files:** 없음 (기능 검증만)

- [ ] **Step 1: codex exec로 일회성 작업 테스트**

```bash
cd /Users/crong/git/dotfiles && codex exec -m gpt-5.4-mini "현재 git diff --stat의 결과를 한 줄로 요약해줘" 2>&1 | head -30
```

Expected: git diff --stat 요약 결과

- [ ] **Step 2: codex exec review 테스트**

```bash
cd /Users/crong/git/dotfiles && codex exec review --uncommitted 2>&1 | head -50
```

Expected: uncommitted 변경사항에 대한 리뷰 결과

---

### Task 5: User Rules Index 업데이트

**Files:**
- Modify: `base/.claude/rules/10-multi-agent.md` (이미 작성됨, 확인만)
- Verify: `base/.claude/CLAUDE.md` 또는 프로젝트 CLAUDE.md의 Rules Index 테이블

- [ ] **Step 1: 프로젝트 CLAUDE.md Rules Index에 10번 항목 추가 여부 확인**

```bash
grep "10-multi-agent\|10.*다중" /Users/crong/git/dotfiles/CLAUDE.md /Users/crong/git/dotfiles/base/.claude/CLAUDE.md 2>/dev/null
```

Expected: 아직 미존재. stow 배포 시 `~/.claude/rules/10-multi-agent.md`가 자동으로 Claude Code에 로드됨 (CLAUDE.md 인덱스 수동 업데이트 불필요 — Claude Code가 `~/.claude/rules/` 디렉토리를 자동 스캔)

- [ ] **Step 2: 최종 상태 확인**

```bash
echo "=== MCP 서버 등록 ==="
python3 -c "import json; d=json.load(open('$HOME/.claude/settings.json')); print(json.dumps(d.get('mcpServers',{}).get('codex',{}), indent=2))"

echo "=== 규칙 파일 배포 ==="
ls -la ~/.claude/rules/10-multi-agent.md

echo "=== Codex AGENTS.md 위임 섹션 ==="
grep -c "Claude.*Codex.*위임" /Users/crong/git/dotfiles/axiom/.codex/AGENTS.md
```

Expected: MCP 서버 등록됨, 규칙 파일 symlink 존재, AGENTS.md에 위임 섹션 포함(1 이상)

- [ ] **Step 3: 최종 커밋 (검증 통과 시)**

```bash
git add -A && git status --short
# 변경사항 확인 후
git commit -m "feat: complete Codex MCP hybrid integration

- MCP 서버 등록 확인
- 다중 에이전트 위임 규칙 배포
- Codex AGENTS.md에 Claude 위임 컨텍스트 추가
- MCP/Bash 경로 검증 완료"
```
