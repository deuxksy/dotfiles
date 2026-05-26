# Codex MCP Server ↔ Claude Code 하이브리드 연결 설계

> **Date**: 2026-05-26
> **Status**: Approved

## 배경

- Codex PRO 구독 중 (gpt-5.5 사용)
- Claude Code를 메인 클라이언트로 사용
- Codex를 서브 에이전트로 활용하여 검증, 교차 비교, 작업 위임 수행

## 아키텍처

```text
Claude Code
  ├── MCP stdio → codex mcp-server
  │     ├── codex(prompt, model?, cwd?, sandbox?, approval-policy?)
  │     └── codex-reply(threadId, prompt)
  ├── Bash → codex exec "PROMPT"
  ├── Bash → codex exec review [--uncommitted | --base BRANCH]
  └── Bash → codex cloud [exec | list | apply]
```

## 라우팅 규칙

| 상황 | 경로 | 명령 |
| :--- | :--- | :--- |
| 코드 검증/리뷰 요청 | MCP | `mcp__codex__codex(prompt, cwd)` |
| 교차 비교 (동일 프롬프트 양쪽 실행) | MCP | `mcp__codex__codex(prompt)` → Claude 결과와 비교 |
| 대화형 위임 (후속질문) | MCP | `mcp__codex__codex-reply(threadId, prompt)` |
| PR/커밋 리뷰 | Bash | `codex exec review --uncommitted` 또는 `--base main` |
| 일회성 코드 생성 | Bash | `codex exec -m gpt-5.5 "프롬프트"` |
| Cloud 태스크 | Bash | `codex cloud exec/list/apply` |

## 사용 가능 모델

| 모델 | 용도 |
| :--- | :--- |
| `gpt-5.5` | 기본, 복잡한 분석/설계 |
| `gpt-5.4` | 표준 코딩 작업 |
| `gpt-5.4-mini` | 빠른 검증, 가벼운 작업 |
| `gpt-5.3-codex` | 코드 특화 작업 |
| `gpt-5.2` | 경량 작업 |

## 기본 파라미터

- **모델**: 기본 `gpt-5.5`, 호출 시 상기 모델 중 선택 가능
- **샌드박스**: `workspace-write`
- **승인 정책**: `on-failure`

## 변경 사항

1. `~/.claude/settings.json` — `mcpServers.codex` 이미 등록됨 (변경 없음)
2. `base/.claude/rules/05-multi-agent.md` (신규) — 다중 에이전트 위임 규칙
3. `axiom/.codex/AGENTS.md` — Claude→Codex 위임 컨텍스트 보완

## 검증 기준

- [ ] `mcp__codex__codex` 도구로 Codex 세션 시작 가능
- [ ] `mcp__codex__codex-reply`로 후속 질문 가능
- [ ] `codex exec review --uncommitted` Bash로 PR 리뷰 실행 가능
- [ ] Claude가 상황에 맞게 MCP/Bash 경로 자동 선택
