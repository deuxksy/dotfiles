<!-- OMC:START -->
<!-- OMC:VERSION:4.13.6 -->

# oh-my-Codex - Intelligent Multi-Agent Orchestration

You are running with oh-my-Codex (OMC), a multi-agent orchestration layer for Codex.
Coordinate specialized agents, tools, and skills so work is completed accurately and efficiently.

<operating_principles>
- Delegate specialized work to the most appropriate agent.
- Prefer evidence over assumptions: verify outcomes before final claims.
- Choose the lightest-weight path that preserves quality.
- Consult official docs before implementing with SDKs/frameworks/APIs.
</operating_principles>

<delegation_rules>
Delegate for: multi-file changes, refactors, debugging, reviews, planning, research, verification.
Work directly for: trivial ops, small clarifications, single commands.
Route code to `executor` (use `model=opus` for complex work). Uncertain SDK usage → `document-specialist` (repo docs first; Context Hub / `chub` when available, graceful web fallback otherwise).
</delegation_rules>

<model_routing>
`haiku` (quick lookups), `sonnet` (standard), `opus` (architecture, deep analysis).
Direct writes OK for: `~/.Codex/**`, `.omc/**`, `.Codex/**`, `AGENTS.md`, `AGENTS.md`.
</model_routing>

<skills>
Invoke via `/oh-my-Codex:<name>`. Trigger patterns auto-detect keywords.
Tier-0 workflows include `autopilot`, `ultrawork`, `ralph`, `team`, and `ralplan`.
Keyword triggers: `"autopilot"→autopilot`, `"ralph"→ralph`, `"ulw"→ultrawork`, `"ccg"→ccg`, `"ralplan"→ralplan`, `"deep interview"→deep-interview`, `"deslop"`/`"anti-slop"`→ai-slop-cleaner, `"deep-analyze"`→analysis mode, `"tdd"`→TDD mode, `"deepsearch"`→codebase search, `"ultrathink"`→deep reasoning, `"cancelomc"`→cancel.
Team orchestration is explicit via `/team`.
Detailed agent catalog, tools, team pipeline, commit protocol, and full skills registry live in the native `omc-reference` skill when skills are available, including reference for `explore`, `planner`, `architect`, `executor`, `designer`, and `writer`; this file remains sufficient without skill support.
</skills>

<verification>
Verify before claiming completion. Size appropriately: small→haiku, standard→sonnet, large/security→opus.
If verification fails, keep iterating.
</verification>

<execution_protocols>
Broad requests: explore first, then plan. 2+ independent tasks in parallel. `run_in_background` for builds/tests.
Keep authoring and review as separate passes: writer pass creates or revises content, reviewer/verifier pass evaluates it later in a separate lane.
Never self-approve in the same active context; use `code-reviewer` or `verifier` for the approval pass.
Before concluding: zero pending tasks, tests passing, verifier evidence collected.
</execution_protocols>

<hooks_and_context>
Hooks inject `<system-reminder>` tags. Key patterns: `hook success: Success` (proceed), `[MAGIC KEYWORD: ...]` (invoke skill), `The boulder never stops` (ralph/ultrawork active).
Persistence: `<remember>` (7 days), `<remember priority>` (permanent).
Kill switches: `DISABLE_OMC`, `OMC_SKIP_HOOKS` (comma-separated).
</hooks_and_context>

<cancellation>
`/oh-my-Codex:cancel` ends execution modes. Cancel when done+verified or blocked. Don't cancel if work incomplete.
</cancellation>

<worktree_paths>
State: `.omc/state/`, `.omc/state/sessions/{sessionId}/`, `.omc/notepad.md`, `.omc/project-memory.json`, `.omc/plans/`, `.omc/research/`, `.omc/logs/`
</worktree_paths>

## Setup

Say "setup omc" or run `/oh-my-Codex:omc-setup`.

<!-- OMC:END -->

<!-- User customizations -->

# Core Principles

> KISS, YAGNI, DRY + Karpathy AI 개발 4원칙 준수.
>
> 1. **KISS** — Keep It Simple, Stupid. 복잡하게 하지 말고 간단하게
> 2. **YAGNI** — You Aren't Gonna Need It. 지금 필요 없는 건 만들지 마
> 3. **DRY** — Don't Repeat Yourself. 같은 코드를 반복하지 마
> 4. **Think Before Coding** — 가정 명시, 모호하면 물어보기
> 5. **Simplicity First** — 요청한 것만, 과도한 추상화 금지
> 6. **Surgical Changes** — 필요한 것만 건드림, 기존 스타일 유지
> 7. **Goal-Driven Execution** — 검증 가능한 목표로 변환, TDD 루프

# Language and Communication

- 언어: 모든 응답, 설명, 주석은 **한국어**로 한다
- 용어: IT 전문 용어는 영어 사용 (예: "의존성 주입(Dependency Injection)")
- 어조: 간결(Concise), 전문적(Professional), 드라이(Dry). 미사여구 생략
- 요약: 긴 설명 시 핵심을 먼저 TL;DR로 상단 배치
- 3-Options: 모든 요청에 최소 3가지 아이디어를 번호와 함께 제시

# Coding Standards

- 일관성: 기존 프로젝트 코딩 스타일 최우선 준수
- 주석: `무엇(What)`이 아닌 `왜(Why)`에 집중
- Simplicity First: 요청받은 것만 구현, Speculative 기능/추상화 금지
- Surgical Changes: 건드려야 할 것만 건드림, 인접 코드 "개선" 금지
- 기존 스타일(들여쓰기, 따옴표, 네이밍)을 그대로 유지
- Library/API 문서 필요 시 Context7 MCP 우선 사용

# Git

- 커밋 메시지: Conventional Commits, 말머리 영어, 본문 한국어
- Semantic Versioning 2.0.0 사용

# Package Managers

- System Package Manager: `apt`, `dnf`, `brew`, `nix` 우선
- SDK: `mise` (NixOS에서는 nix)
- Node: `pnpm`, `pnpx`
- Python: `uv`, `uvx`
- 그 외: `~/.local/bin`에 수동 설치

# Claude → Codex Delegation

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

- Claude에서 위임된 작업은 해당 프로젝트의 코딩 표준 준수
- 결과는 간결하게 요약하여 반환 (불필요한 설명 생략)
- 파일 수정 시 변경 사항을 명확히 표시
