# AI Agent 의존성 인벤토리

- [채널 분리 원칙](#채널-분리-원칙)
- [apm — hook 없는 skill·MCP](#apm--hook-없는-skillmcp)
- [자체 채널 — hook 포함 plugin·LSP](#자체-채널--hook-포함-pluginlsp)
- [프로젝트 tier](#프로젝트-tier)
- [제거 tier](#제거-tier)
- [특이사항](#특이사항)

## 채널 분리 원칙

2026-11-14 결정 — **hook 포함 plugin은 apm이 hook 설정을 신뢰성 있게 관리하지 못하므로**:

- hook 없는 skill bundle·MCP → **apm** (`base/.apm/apm.yml`)
- hook 포함 plugin·LSP → **자체 채널** (Claude marketplace `enabledPlugins` 등)

## apm — hook 없는 skill·MCP

`base/.apm/apm.yml` (v1.2.0). **설치 미실행** — 조사·기록만.

### Plugin (skill bundle)

| 항목 | 설치 | 최신 | 상태 |
| :--- | :--- | :--- | :--- |
| vercel-labs/skills | unknown | 1.8.1 (2026-11-10) | ⚠️ 확인 필요 |
| deuxksy/ai-agent-skill/plugins/dev | 2.0.0 | 2.0.0 | ✅ |
| deuxksy/ai-agent-skill/plugins/docs | 2.1.0 | 2.1.0 | ✅ |
| deuxksy/ai-agent-skill/plugins/git | 2.2.0 | 2.2.0 | ✅ |
| deuxksy/ai-agent-skill/plugins/infra | 2.4.1 | 2.4.1 | ✅ |
| deuxksy/ai-agent-skill/plugins/jmeter | 2.0.0 | 2.0.0 | ✅ |
| deuxksy/ai-agent-skill/plugins/kisa | 1.2.1 | 1.2.1 | ✅ |
| deuxksy/ai-agent-skill/plugins/l10n | 2.0.0 | 2.0.0 | ✅ |
| deuxksy/ai-agent-skill/plugins/review | 2.1.0 | 2.1.0 | ✅ |
| deuxksy/ai-agent-skill/plugins/rules | 2.0.0 | 2.0.0 | ✅ |
| deuxksy/ai-agent-skill/plugins/security | 2.0.0 | 2.0.0 | ✅ |
| deuxksy/ai-agent-skill/plugins/sessions | 2.0.0 | 2.0.0 | ✅ |
| deuxksy/ai-agent-skill/plugins/trackers | 2.0.0 | 2.0.0 | ✅ |

ai-agent-skill 개별 plugin 버전은 repo release tag(v1.14.0)가 아닌 **각 `plugin.json`이 SoT** — HEAD 기준 위 표와 전부 일치.

### MCP

| 항목 | 설치 | 최신 | 상태 |
| :--- | :--- | :--- | :--- |
| serena | 2.1.0 | 2.1.0 (2026-10-19) | ✅ |
| playwright-mcp | npx 최신 | 0.0.85 | ✅ 실행 시 자동 최신 |
| context7 | npx 최신 | 4.7.0 | ✅ 실행 시 자동 최신 |
| notion | hosted | - | ✅ (mcp.notion.com) |
| appium-mcp | 미설치 | 1.99.3 | ❌ 신규 등록 예정 |

## 자체 채널 — hook 포함 plugin·LSP

Claude `~/.claude/settings.json` `enabledPlugins` (2026-11-14 기준 20종).

### hook 포함 plugin

| 항목 | 설치(marketplace) | 최신 | hook |
| :--- | :--- | :--- | :--- |
| superpowers@claude-plugins-official | 7.0.2 | 7.0.2 (2026-11-03) | 4종 |
| remember@claude-plugins-official | 최신 자동 | 0.45.1 (2026-11-07) | 4종 |
| claude-code-wakatime@wakatime | 4.1.2 | 4.1.2 | SessionEnd·PreToolUse·PostToolUse |
| serena@anthropic-plugin-directory | 최신 자동 | 2.1.0 | serena-hooks 4종 |

### LSP (apm 경로 미지원 — marketplace 유지, 기존 결정)

gopls, jdtls, lua, pyright, rust-analyzer, terraform-lsp + kotlin 2벌(`kotlin-lsp-msapps-mobile`/`kotlin-lsp`) + typescript 2벌(`typescript-lsp`/`typescript-native-lsp`) — kotlin·typescript 이중 등록 점검 후보

### 이중 채널 잔여 — 정리 대기

| 그룹 | marketplace | apm | 조치 |
| :--- | :--- | :--- | :--- |
| zzizily 6종 (docs·git·infra·review·rules·sessions) | ON | 포함됨 | hook 없음 → marketplace OFF 권장 (apm 단일화) |
| serena MCP | plugin이 MCP 제공 | stdio MCP 포함 | claude에서 이중 로드 관측됨 — plugin 유지 시 apm MCP를 codex/agy 전용 targets로 조정 검토 |

## 프로젝트 tier

각 repo root `apm.yml`에 선택 적용 — snippet은 [프로젝트 선택적 MCP·plugin 추가](../how-to/2026-11-14-project-optional-mcp-plugin.md) 참조.

| 항목 | 종류 | 최신 |
| :--- | :--- | :--- |
| dbhub | MCP | npx 최신 |
| kubernetes-mcp-server | MCP | npx 최신 |
| proxmox-mcp-plus | MCP | uvx 최신 |
| doris-mcp-server | MCP | uvx 최신 |
| terraform-mcp-server | MCP | 로컬 바이너리 |
| cloudflare-api | MCP | hosted |
| chrome-devtools-mcp | MCP | npx 최신 |
| firecrawl/anydoc | plugin | orphan 제거됨 (프로젝트 이관) |

## 제거 tier

web-reader, web-search-prime, zread, zai-mcp-server — native WebSearch/WebFetch로 대체 (2026-11-14 GLM 환경 동작 확인).

## 특이사항

- hook 포함 3종(superpowers·claude-remember·wakatime)은 apm v1.2.0에서 제거 → 자체 채널 유지. superpowers untrusted baseline 충돌 해소
- 2026-11-14 global prune: azure-skills, anydoc(orphan) 제거
- `base/.apm/.mcp.json` (평문 시크릿 포함 stale artifact) → `.mcp.json.retired-20261114`로 retire, `.gitignore` 등록 완료
- **미결정**: manifest `targets`에 antigravity(agy) 추가 여부 — antigravity는 skills만 부분 지원
- **재설치 대기**: manifest v1.2.0과 배포 영역 불일치 — `apm install -g` 실행 시 lock 갱신

---

조사 기준일: 2026-11-14 (npm view / gh api / serena --version / plugin cache hooks.json)
