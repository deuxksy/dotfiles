# Multi-Agent

## 검증 (zzizily verify로 이관)

검증 실행 로직(3단계 티어, Codex+Antigravity 2-Way, 라우팅, B/R/A/T 포맷, 충돌 해결)은
zzizily plugin의 `verify` 컴포넌트(skill + subagent)로 이관됨.

**자동 트리거**: 사용자 명시적 입력에서 '검증'/'verify'/'리뷰해줘' + 검증 대상(spec/plan/diff)
감지 시 `/zzizily:verify` 자동 호출.
**제외**(무한 루프 방지): 이미 verify 실행 중 / 리포트 출력 중 / opt-out 플래그 세션에서는 트리거 안 함.

**인프라 설정**(아래 각 섹션 유지, Source of Truth): 검증 시 zzizily verify가 소비.

### 검증 및 서브 에이전트 라우팅 우선순위 (Claude Code 기준)

- **Plan A: Codex (MCP)** (`mcp__codex__codex` / `mcp__codex__codex-reply`): `gpt-5.6-sol`을 통한 대화형 코드 검증 및 심층 분석
- **Plan B: Antigravity CLI (`agy`)**: `agy -p "..."`를 통한 Gemini 대용량 컨텍스트 2-Way 교차 검증
- **Plan C (Option): LLM CLI (`llm`)**: Tailscale Aperture 게이트웨이를 통한 독립 3자 모델 교차 검증
  - `llm -t review` (Alibaba): 빠른 코드 diff 리뷰 & 버그 탐지
  - `llm -t audit` (Kimi): 시스템 아키텍처/기획/엣지케이스 심층 추론 감사

- Codex: MCP 설정·파라미터 → 아래 `## Codex` 섹션
- Antigravity: CLI 사용법·모델 → 아래 `## Antigravity CLI` 섹션
- LLM CLI: Aperture Alibaba/Kimi 교차 검증 → 아래 `## LLM CLI` 섹션
- Holmes/Serena: 도메인 에이전트 → 아래 각 섹션

## Codex (MCP + Bash Hybrid)

Codex PRO 구독(gpt-5.6-sol)을 서브 에이전트로 활용.

### Routing

- **MCP** (`mcp__codex__codex` / `mcp__codex__codex-reply`): 코드 검증, 교차 비교, 대화형 위임
- **Bash** (`codex exec`): 일회성 코드 생성, PR 리뷰(`codex exec review --uncommitted` 또는 `--base BRANCH`)
- **Bash** (`codex cloud`): Cloud 태스크 제출/조회/적용

### Default Parameters

- 모델: `gpt-5.6-sol` (상기 모델 중 상황에 맞게 선택)
- 샌드박스: `workspace-write`
- 승인 정책: `on-failure`

### Available Models

GPT-5.6 세대는 번호(5.6)가 세대, 이름(Sol/Terra/Luna)이 영구 capability tier를 의미한다. Terra/Luna는 standard ChatGPT 대화에서 선택 불가, Codex/API에서만 사용 가능.

| 모델            | 용도                                           |
| :-------------- | :--------------------------------------------- |
| `gpt-5.6-sol`   | 기본, 복잡한 분석/설계 (플래그십, agentic)     |
| `gpt-5.6-terra` | 표준 작업, 비용 효율 (GPT-5.5 성능, 절반 비용) |
| `gpt-5.6-luna`  | 빠른 검증, 대용량 작업 (최저비용·최고속)       |
| `gpt-5.5`       | 레거시                                         |

### Use Cases

1. **코드 검증**: 완성된 코드의 sandbox 실행, 버그 탐지
2. **PR 리뷰**: `codex exec review --uncommitted`로 변경사항 자동 리뷰
3. **교차 비교**: 동일 프롬프트를 양쪽에 실행 → 결과 비교/분석

## Holmes

- MCP 미지원, Bash로 호출
- 환경변수: `OPENAI_API_KEY` + `OPENAI_API_BASE=http://ai/v1`
- 모델: `--model openai/<model>` (litellm provider prefix 필수)
- 인프라/로그 종합 조사에 활용

## Serena

- MCP 서버(`serena start-mcp-server`)로 코드 심볼 분석
- 선언/참조/구현 탐색, 심볼 리네임/삭제 등 코드 내비게이션

## LLM CLI (교차 검증 및 파이프라인)

Simon Willison의 `llm` CLI(`uv tool install llm`)로 Tailscale Aperture 게이트웨이를 통해 AI Agent 산출물을 독립적으로 교차 검증.

### Routing & Models (Aperture `http://ai.bun-bull.ts.net/v1`)

- **기본 모델**: `qwen3.8-max` (별칭: `alibaba`, `qwen`, `max`) — 빠른 코드 리뷰 & 버그 탐지
- **심층 추론**: `k3` (별칭: `kimi`, `k3`, 템플릿: `-t kimi` / `-t audit`) — 아키텍처/엣지케이스 심층 분석
- **초고속 모델**: `qwen3.6-flash` (별칭: `flash`, `fast`) — 빠른 질의
- **코딩 특화**: `kimi-for-coding`

### Verification Templates

- `review`: Alibaba 기반 코드 변경사항 및 diff 빠른 버그/보안 리뷰 (`git diff | llm -t review`)
- `audit`: Kimi 기반 시스템 아키텍처 및 논리 결함 심층 감사 (`cat plan.md | llm -t audit`)
- `alibaba`: Alibaba Qwen 3.8 Max 전용 호출 (`llm -t alibaba`)
- `kimi`: Kimi k3 가중치(1.0 / 0.95) 사전 고정 호출 (`llm -t kimi`)

### Usage Examples

```bash
# 코드 diff 빠른 리뷰 (Alibaba 기반)
git diff | llm -t review

# 아키텍처/기획 문서 심층 감사 (Kimi 기반)
cat docs/plan.md | llm -t audit

# 단발성 질의 (기본 Alibaba Qwen 3.8 Max)
llm "질문 내용"

# Kimi 심층 질의
llm -t kimi "질문 내용"

# 특정 질문과 함께 검증
cat src/engine.ts | llm "동시성 이슈나 메모리 누수 위험이 있는지 검토해줘"
```
