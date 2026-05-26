# Codex MCP Server ↔ Claude Code 하이브리드 연결 설계

> **Date**: 2026-05-27 (merged from 05-26 + 05-27)
> **Status**: Approved

## 배경

- Codex PRO 구독 중 (gpt-5.5 사용)
- Claude Code를 메인 클라이언트로 사용
- Codex를 서브 에이전트로 활용하여 검증, 교차 비교, 작업 위임 수행

## 아키텍처

```text
Claude Code (glm-5.1)
  ├── 기존 MCP 서버 (Context7, Notion, Figma, Serena...)
  ├── MCP stdio → codex mcp-server
  │     ├── codex(prompt, model?, cwd?, sandbox?, approval-policy?)
  │     └── codex-reply(threadId, prompt)
  ├── Bash → codex exec "PROMPT"
  ├── Bash → codex exec review [--uncommitted | --base BRANCH]
  └── Bash → codex cloud [exec | list | apply]
```

## MCP 서버 설정

`~/.claude/settings.json`의 `mcpServers`:

```json
"codex": {
  "command": "codex",
  "args": ["mcp-server"]
}
```

### 노출 도구

| 도구 | 설명 | 필수 파라미터 |
| :--- | :--- | :--- |
| `codex` | 새 Codex 세션 시작 | `prompt` |
| `codex-reply` | 기존 세션 continuation | `prompt`, `threadId` |

### codex 도구 파라미터

| 파라미터 | 타입 | 설명 |
| :--- | :--- | :--- |
| `prompt` | string (필수) | 초기 프롬프트 |
| `model` | string | 모델 오버라이드 (기본: gpt-5.5) |
| `sandbox` | enum | `read-only`, `workspace-write`, `danger-full-access` |
| `approval-policy` | enum | `untrusted`, `on-failure`, `on-request`, `never` |
| `cwd` | string | 작업 디렉토리 |
| `developer-instructions` | string | 커스텀 지시사항 |
| `config` | object | config.toml 오버라이드 |

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

| 모델 | 특성 | Claude 호출 시 사용 |
| :--- | :--- | :--- |
| `gpt-5.5` | 최고 성능 | config.toml 기본값, 교차 검증/리뷰 |
| `gpt-5.4` | 고성능 범용 | 고성능 작업 필요시 |
| `gpt-5.4-mini` | 빠른/가성비 | 빠른 탐색/조회 |
| `gpt-5.3-codex` | 코딩 특화 | 코드 작성/실행 |
| `gpt-5.2` | 경량 | 가벼운 작업 |

## 사용 패턴별 정책

| 목적 | 도구 | model | sandbox | approval-policy |
| :--- | :--- | :--- | :--- | :--- |
| 코드 작성/실행 | `codex` | gpt-5.3-codex | workspace-write | on-failure |
| 교차 검증/리뷰 | `codex` | (기본 gpt-5.5) | read-only | - |
| 코드 탐색 | `codex` | gpt-5.4-mini | read-only | - |
| 대화 이어가기 | `codex-reply` | (세션 모델 유지) | (세션 설정 유지) | - |

## 제약사항

- `codex mcp-server`는 stdio 프로토콜 사용 — Claude Code 세션당 1개 프로세스
- 각 `codex` 호출은 독립 세션 — `codex-reply`로만 대화 유지 가능
- ChatGPT PRO 구독 모델만 사용 가능 (GPT-5.4 Pro 등은 제외)
- NixOS(mo)에서는 PATH에 `/run/current-system/sw/bin/codex` 필요

## 변경 사항

1. `~/.claude/settings.json` — `mcpServers.codex` 이미 등록됨 (변경 없음)
2. `base/.claude/rules/05-multi-agent.md` (신규) — 다중 에이전트 위임 규칙
3. `axiom/.codex/AGENTS.md` — Claude→Codex 위임 컨텍스트 보완

## 검증 기준

- [ ] `mcp__codex__codex` 도구로 Codex 세션 시작 가능
- [ ] `mcp__codex__codex-reply`로 후속 질문 가능
- [ ] `codex exec review --uncommitted` Bash로 PR 리뷰 실행 가능
- [ ] Claude가 상황에 맞게 MCP/Bash 경로 자동 선택
