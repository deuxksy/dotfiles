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
# User Rules Index

> KISS, YAGNI, DRY + Karpathy AI 개발 4원칙 준수. 상세 규칙은 `~/.Codex/rules/` 참조.
>
> 1. **KISS** — Keep It Simple, Stupid. 복잡하게 하지 말고 간단하게
> 2. **YAGNI** — You Aren't Gonna Need It. 지금 필요 없는 건 만들지 마
> 3. **DRY** — Don't Repeat Yourself. 같은 코드를 반복하지 마
> 4. **Think Before Coding** — 가정 명시, 모호하면 물어보기
> 5. **Simplicity First** — 요청한 것만, 과도한 추상화 금지
> 6. **Surgical Changes** — 필요한 것만 건드림, 기존 스타일 유지
> 7. **Goal-Driven Execution** — 검증 가능한 목표로 변환, TDD 루프

| # | 파일 | 내용 |
| :--- | :--- | :--- |
| 00 | [user-profile](rules/00-user-profile.md) | 사용자 프로필, 글로벌 원칙 |
| 01 | [language-communication](rules/01-language-communication.md) | 언어, 어조, 3-Options |
| 02 | [verification-protocol](rules/02-verification-protocol.md) | Negative Premise, Ground Truth, 3-Strike |
| 03 | [documentation](rules/03-documentation.md) | Markdown, Mermaid |
| 04 | [coding-standard](rules/04-coding-standard.md) | 코딩 표준, 라이브러리, Context7 |
| 05 | [operations-safety](rules/05-operations-safety.md) | 운영, 안전, 파일 경로 |
| 06 | [git](rules/06-git.md) | Git, Conventional Commits, SemVer |
| 07 | [package-manager](rules/07-package-manager.md) | mise, pnpm, uv |
| 08 | [problem-solving](rules/08-problem-solving.md) | 문제 해결 프로세스 9단계 |
| 09 | [work-log](rules/09-work-log.md) | Work-Log 관리, Notion 연동 |

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

- Claude에서 위임된 작업은 해당 프로젝트의 코딩 표준 준수
- 결과는 간결하게 요약하여 반환 (불필요한 설명 생략)
- 파일 수정 시 변경 사항을 명확히 표시
