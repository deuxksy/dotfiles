# AI Agent 4-Layer 표준 및 의존성 인벤토리

- [4-Layer 표준 정의](#4-layer-표준-정의)
- [채널 분리 원칙](#채널-분리-원칙)
- [Layer 1: Skill](#layer-1-skill)
- [Layer 2: Hook](#layer-2-hook)
- [Layer 3: MCP](#layer-3-mcp)
- [Layer 4: LSP](#layer-4-lsp)
- [옵션 / 프로젝트 tier](#옵션--프로젝트-tier)
- [제거 tier](#제거-tier)

## 4-Layer 표준 정의

2026-11-26 확정 — 전역 기본 구성을 최소 필수 세트로 유지하고, 업무별 도구는 옵션(프로젝트 tier)으로 분리한다.

| 레이어 | 필수 (전역 상시) | 옵션 (업무별 / 프로젝트) |
| :--- | :--- | :--- |
| **1. Skill** | `superpowers`, `vercel-labs/skills` (`find-skills`), `deuxksy/ai-agent-skill` (13개) | 필요 시 `find-skills`로 추가 |
| **2. Hook** | `superpowers`, `remember`, `claude-code-wakatime`, `serena-hooks` | - |
| **3. MCP** | `serena` (공통), `statusline-tickets` (Codex 전용) | `playwright-mcp`, `chrome-devtools-mcp`, `appium-mcp`, `dbhub`, `cloudflare`, `notion`, `figma` 등 |
| **4. LSP** | 주요 언어 전체 (Claude LSP 8종 + `/infra:lsp` 시스템 바이너리) | - |

## 채널 분리 원칙

- **공통 hook-less 외부 skill · 공통 필수 MCP** → **`apm`** (`chezmoi/dot_apm/apm.yml`, `base/.apm/apm.yml` v2.0.0)
- **개인 skill 마켓플레이스 (`deuxksy/ai-agent-skill`)** → **네이티브 `@zzizily` 플러그인 단일화** (`/git:commit`, `/infra:packages` 등 네임스페이스 유지, `apm.yml` 중복 제거)
- **hook 포함 plugin · LSP** → **각 에이전트 자체 채널** (Claude `enabledPlugins` / `settings.json`, Codex `config.toml`)
- **에이전트 전용 MCP** → 해당 에이전트 설정에 직접 유지 (예: `statusline-tickets` → Codex `config.toml`)

## Layer 1: Skill

### apm (`apm.yml` v2.0.0)

| 항목 | 용도 | 대상 |
| :--- | :--- | :--- |
| `vercel-labs/skills` | `find-skills` (외부 스킬 탐색·설치) | `claude`, `codex` |

### 네이티브 플러그인 (`@zzizily` / 공식 마켓플레이스)

| 항목 | 채널 | 비고 |
| :--- | :--- | :--- |
| `superpowers` | Claude (`anthropic-plugin-directory`), Codex (`openai-curated-remote`) | hook 포함 필수 워크플로우 |
| `deuxksy/ai-agent-skill` (13종) | `@zzizily` (Claude · Codex · Antigravity) | `dev`, `docs`, `email`, `git`, `infra`, `jmeter`, `kisa`, `l10n`, `review`, `rules`, `security`, `sessions`, `trackers` |

> `deuxksy/ai-agent-skill` 개별 plugin 버전은 각 `plugin.json`이 SoT.

## Layer 2: Hook

| 항목 | 관리 위치 | 역할 |
| :--- | :--- | :--- |
| `superpowers` | Claude / Codex 네이티브 플러그인 | 세션 시작 및 워크플로우 hook |
| `remember` | Claude 네이티브 플러그인 (`remember@claude-plugins-official`) | 장기 메모리 hook |
| `claude-code-wakatime` | Claude 네이티브 플러그인 (`claude-code-wakatime@wakatime`) | 작업 시간 추적 hook |
| `serena-hooks` | Claude `~/.claude/settings.json` (`hooks`) | `serena` MCP 자동 활성화·리마인드·자동 승인·정리 |

## Layer 3: MCP

### 전역 필수

| 항목 | Transport | 관리 위치 | 대상 |
| :--- | :--- | :--- | :--- |
| `serena` | stdio (`serena start-mcp-server --context=claude-code --project-from-cwd`) | `apm.yml` + Gemini `~/.gemini/settings.json` | Claude, Codex, Gemini |
| `statusline-tickets` | stdio (`python3 -u ~/git/statusline/integrations/codex/statusline.py`) | Codex `~/.codex/config.toml` | Codex 전용 |

> Claude 네이티브 `serena@anthropic-plugin-directory` 플러그인은 `apm` stdio MCP와 이중 로드를 피하기 위해 비활성화한다.

## Layer 4: LSP

`apm`은 LSP 배포를 지원하지 않으므로 Claude 네이티브 플러그인 + 시스템 바이너리(`/infra:lsp`)로 유지한다.

- **Claude LSP 플러그인 (8종)**: `typescript-lsp`, `pyright-lsp`, `gopls-lsp`, `jdtls-lsp`, `kotlin-lsp`, `rust-analyzer-lsp`, `lua-lsp`, `terraform-lsp`
- **시스템 LSP 바이너리 (`/infra:lsp`)**: 위 8종 + `spring-boot-language-server`, `ansible-language-server`, `yaml-language-server`, `bash-language-server`, `vscode-langservers-extracted` (JSON/HTML/CSS), `marksman` (Markdown)

## 옵션 / 프로젝트 tier

업무나 프로젝트에 따라 repo root `apm.yml` 또는 `.mcp.json`에 선택 적용한다. 스니펫은 [프로젝트 선택적 MCP·plugin 추가](../how-to/2026-11-14-project-optional-mcp-plugin.md) 참조.

| 항목 | 종류 | 용도 |
| :--- | :--- | :--- |
| `playwright-mcp` | MCP | 브라우저 자동화·E2E 테스트 |
| `chrome-devtools-mcp` | MCP | Chrome DevTools 디버깅 |
| `appium-mcp` | MCP | 모바일(Android/iOS) UI 자동화 |
| `dbhub` | MCP | DB 조회/분석 |
| `cloudflare` | MCP | Cloudflare 인프라/Workers 관리 |
| `notion` | MCP | Notion 문서·스프린트 연동 |
| `figma` | MCP | 디자인 스펙 조회 |
| `kubernetes-mcp-server` | MCP | Kubernetes 클러스터 운영 |
| `proxmox-mcp-plus` | MCP | Proxmox Homelab 관리 |
| `doris-mcp-server` | MCP | Apache Doris 조회 |
| `terraform-mcp-server` | MCP | Terraform IaC 지원 |
| `firecrawl/anydoc` | Skill | 문서 → Markdown 변환 |

## 제거 tier

- `context7` — 전역 MCP·플러그인에서 제거
- `session-report`, `github` — Claude 네이티브 플러그인에서 제거
- `web-reader`, `web-search-prime`, `zread`, `zai-mcp-server` — native WebSearch/WebFetch로 대체 (2026-11-14)

---

기준일: 2026-11-26
