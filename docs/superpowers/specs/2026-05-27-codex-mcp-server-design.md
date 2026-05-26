# Codex MCP Server for Claude Code

> **Date**: 2026-05-27
> **Status**: Approved

## 개요

Claude Code를 클라이언트로, Codex CLI를 MCP 서버로 구성하여 GPT 계열 모델(GPT-5.5, GPT-5.4, GPT-5.4-Mini, GPT-5.3-Codex, GPT-5.2)을 Claude 작업 흐름에 통합.

## 아키텍처

```text
Claude Code (glm-5.1)
  ├── 기존 MCP 서버 (Context7, Notion, Figma, Serena...)
  └── codex MCP 서버 (stdio)
        ├── codex 도구       → 새 세션 시작
        └── codex-reply 도구 → 기존 세인 continuation
```

## MCP 서버 설정

`~/.claude/settings.json`의 `mcpServers`에 추가:

```json
"codex": {
  "command": "codex",
  "args": ["mcp-server"]
}
```

## 노출 도구

| 도구 | 설명 | 필수 파라미터 |
| :--- | :--- | :--- |
| `codex` | 새 Codex 세션 시작 | `prompt` |
| `codex-reply` | 기존 세인 continuation | `prompt`, `threadId` |

### codex 도구 파라미터

| 파라미터 | 타입 | 설명 |
| :--- | :--- | :--- |
| `prompt` | string (필수) | 초기 프롬프트 |
| `model` | string | 모델 오버라이드 |
| `sandbox` | enum | `read-only`, `workspace-write`, `danger-full-access` |
| `approval-policy` | enum | `untrusted`, `on-failure`, `on-request`, `never` |
| `cwd` | string | 작업 디렉토리 |
| `developer-instructions` | string | 커스텀 지시사항 |
| `config` | object | config.toml 오버라이드 |

## 모델 전략

ChatGPT PRO 구독으로 사용 가능한 모델:

| 모델 | 특성 | Claude 호출 시 사용 |
| :--- | :--- | :--- |
| gpt-5.5 | 최고 성능 | config.toml 기본값, 교차 검증/리뷰 |
| gpt-5.4 | 고성능 범용 | 고성능 작업 필요시 |
| gpt-5.4-mini | 빠른/가성비 | 빠른 탐색/조회 |
| gpt-5.3-codex | 코딩 특화 | 코드 작성/실행 |
| gpt-5.2 | 경량 | 가벼운 작업 |

기본 모델은 config.toml의 `gpt-5.5`를 유지. Claude가 상황에 따라 `model` 파라미터로 오버라이드.

## 사용 패턴

| 목적 | 도구 | model | sandbox | approval-policy |
| :--- | :--- | :--- | :--- | :--- |
| 코드 작성/실행 | `codex` | gpt-5.3-codex | workspace-write | on-failure |
| 교차 검증/리뷰 | `codex` | (기본 gpt-5.5) | read-only | - |
| 코드 탐색 | `codex` | gpt-5.4-mini | read-only | - |
| 대화 이어가기 | `codex-reply` | (세션 모델 유지) | (세션 설정 유지) | - |

## 변경 범위

1. `~/.claude/settings.json` — `mcpServers`에 `codex` 항목 추가
2. `~/.claude/settings.local.json` — 권한에 `mcp__codex__*` 추가 (선택)

## 제약사항

- `codex mcp-server`는 stdio 프로토콜 사용 — Claude Code 세션당 1개 프로세스
- Codex CLI가 NixOS 패키지로 설치되어 PATH에 있어야 함 (`/run/current-system/sw/bin/codex`)
- 각 `codex` 호출은 독립 세션 — `codex-reply`로만 대화 유지 가능
- ChatGPT PRO 구독 모델만 사용 가능 (GPT-5.4 Pro 등은 제외)
