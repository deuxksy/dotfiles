# Multi-Agent

## Codex (MCP + Bash Hybrid)

Codex PRO 구독(gpt-5.5)을 Claude Code의 서브 에이전트로 활용.

### Routing

- **MCP** (`mcp__codex__codex` / `mcp__codex__codex-reply`): 코드 검증, 교차 비교, 대화형 위임
- **Bash** (`codex exec`): 일회성 코드 생성, PR 리뷰(`codex exec review --uncommitted` 또는 `--base BRANCH`)
- **Bash** (`codex cloud`): Cloud 태스크 제출/조회/적용

### Available Models

| 모델 | 용도 |
| :--- | :--- |
| `gpt-5.5` | 기본, 복잡한 분석/설계 |
| `gpt-5.4` | 표준 코딩 작업 |
| `gpt-5.4-mini` | 빠른 검증, 가벼운 작업 |
| `gpt-5.3-codex` | 코드 특화 작업 |
| `gpt-5.2` | 경량 작업 |

### Default Parameters

- 모델: `gpt-5.5` (상기 모델 중 상황에 맞게 선택)
- 샌드박스: `workspace-write`
- 승인 정책: `on-failure`

### Use Cases

1. **검증**: Claude 작업 완료 후 Codex에 리뷰 요청 → 결과 반영
2. **교차 비교**: 동일 프롬프트를 양쪽에 실행 → 결과 비교/분석
3. **PR 리뷰**: `codex exec review --uncommitted`로 변경사항 자동 리뷰

## Gemini CLI

- Google Gemini CLI로 코드 생성, 분석, 검증
- 모델: `gemini-3.1-pro-preview` (기본), 하기 모델 중 상황에 맞게 선택

| 모델 | 용도 |
| :--- | :--- |
| `gemini-3.1-pro-preview` | 기본, 복잡한 분석/설계 |
| `gemini-3-flash-preview` | 빠른 검증, 가벼운 작업 |
| `gemini-3.1-flash-lite-preview` | 경량 작업 |
| `gemini-2.5-pro` | 표준 작업 |
| `gemini-2.5-flash` | 빠른 코딩 작업 |
| `gemini-2.5-flash-lite` | 경량 코딩 |
| `gemma-4-31b-it` | 오픈모델 작업 |
| `gemma-4-26b-a4b-it` | 경량 오픈모델 |

## K8sGPT

- MCP 서버(`k8sgpt serve --mcp --mcp-port 34089`)로 K8s 리소스 분석
- Claude Code에서 `mcp__k8sgpt__*` 도구로 호출

## Holmes

- MCP 미지원, Bash로 호출
- 환경변수: `OPENAI_API_KEY` + `OPENAI_API_BASE=http://ai/v1`
- 모델: `--model openai/<model>` (litellm provider prefix 필수)
- 인프라/로그 종합 조사에 활용

## Serena

- MCP 서버(`serena start-mcp-server`)로 코드 심볼 분석
- 선언/참조/구현 탐색, 심볼 리네임/삭제 등 코드 내비게이션
