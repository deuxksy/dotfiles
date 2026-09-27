# apm Agent Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** dotfiles에 apm user-global manifest를 도입해 외부 skill 3종 + MCP 6개를 claude/codex/gemini 3에이전트에 선언적으로 배포하고, settings 소유권 분리로 plugin 자동 설치와 평문 token 제거를 완성한다.

**Architecture:** repo `base/.apm/`(manifest+lock)을 stow가 `~/.apm/`에 symlink하고 `apm install -g`가 3에이전트 설정에 배포한다. `base/.claude/settings.json`(stow 고정)이 plugin 매트릭스를 선언해 Claude Code 첫 세션에 자동 설치하고, provider 차이는 sops 암호화 env 프로파일 + `claude-profile()` 로더로 전환한다. 신규 장비는 `install.sh` / `windows/install.ps1` 한 번으로 재현한다.

**Tech Stack:** apm 0.32.x (microsoft/apm), GNU Stow, sops+age, jq, zsh, PowerShell(Pester)

**Spec:** [docs/okf/explanation/2026-09-27-apm-agent-layer-design.md](../../okf/explanation/2026-09-27-apm-agent-layer-design.md)

## Global Constraints

- apm은 **선언적 관리만** — steady-state에서 imperative install로 manifest 변경 금지. 예외: 최초 manifest 생성 시 CLI가 만든 YAML 채택(spec 리스크 #1 대응)
- 배포 단위는 **user scope** (`~/.apm/apm.yml`)만. repo root `apm.yml`(project scope)은 건드리지 않는다
- manifest에는 secret 리터럴 금지 — `${VAR}` placeholder만 (`APERTURE_MCP_URL`, `Z_AI_API_KEY`)
- stow는 항상 `--no-folding` (repo Gotcha 준수)
- git commit은 Conventional Commits (type 영어, 본문 한국어), token/secret 미커밋, gitleaks 통과
- 자체 제작 스킬 실디렉토리 `~/.claude/skills/multi-agent-verification`, `~/.claude/skills/omc-reference`, `~/.agents/skills/omc-reference`, `~/.agents/skills/microsoft-foundry`는 **삭제·변경 금지**
- 모든 작업은 호스트 eve(macOS)에서 먼저 검증. 타 호스트/kyolim 실행은 Task 8의 런북 참조

## Review Focus

1. **apm 배포가 기존 수동 mcpServers를 소실** — 배포 전후 `claude mcp list` 동등성으로 방어 (Task 4 Step 7)
2. **lock rewrite가 symlink를 실체 파일로 교체** — 매 install 후 `ls -la ~/.apm/` 검증 + `stow --restow` 복구 절차 (Task 3 Step 6)
3. **`enabled:false` plugin이 첫 세션에 설치됨** — 세션 후 `claude plugin list --json`에서 false 14개 미설치 확인 (Task 5 Step 8)
4. **평문 token 잔여** — `gitleaks detect` + `git grep ANTHROPIC_AUTH_TOKEN` 0건 (Task 6 Step 5)
5. **install.sh 재실행이 비멱등하게 실패** — eve에서 2회 연속 실행 무오류로 방어 (Task 7 Step 5)

---

### Task 1: Phase 0 — apm 거동 검증

**Files:**
- Create: `docs/superpowers/plans/2026-09-27-apm-agent-layer-phase0.md` (검증 기록)

**Interfaces:**
- Consumes: live `~/.claude.json` (읽기 전용), `apm` 0.32.x
- Produces: manifest 문법 확정 정보(Task 3~4가 사용), zai 마켓 처리 방침(Task 4)

- [ ] **Step 1: 백업**

```bash
cp ~/.claude.json ~/.claude.json.bak-phase0
cp ~/.claude/settings.json ~/.claude/settings.json.bak-phase0
```

- [ ] **Step 2: MCP 선언 문법 확인 (dry-run, 기록)**

```bash
# http 2종 + stdio 2종의 dry-run 출력에서 apm이 생성할 YAML 구조를 관찰한다
apm install -g --mcp zread --transport http --url "$(jq -r '.mcpServers.zread.url' ~/.claude.json)" --dry-run
apm install -g --mcp zai-mcp-server --transport stdio --env Z_AI_API_KEY=\${Z_AI_API_KEY} -- npx -y @z_ai/mcp-server --dry-run
```

기록할 것: `mcp:` 엔트리의 정확한 키명(name/transport/url/command/args/env), ${VAR} placeholder가 보존되는가.

- [ ] **Step 3: `~/.claude.json` merge 안전성 확인**

```bash
apm install -g --mcp zread --transport http --url "$(jq -r '.mcpServers.zread.url' ~/.claude.json)" --dry-run
diff <(jq -S . ~/.claude.json) <(jq -S . ~/.claude.json.bak-phase0) && echo "dry-run은 미변경 — OK"
```

실제 설치 1건으로 병합 확인(설치는 Task 3에서 수행하므로 여기선 dry-run만):

```bash
jq -r '.mcpServers | keys[]' ~/.claude.json | tr '\n' ' '   # 현재 6개 기록: aperture serena web-reader web-search-prime zai-mcp-server zread
```

- [ ] **Step 4: zai-coding-plugins 마켓 표현 조사**

```bash
jq '.extraKnownMarketplaces' ~/.claude/settings.json
ls ~/.claude/plugins/vendor/zai-coding-plugins/ | head
```

판정: source가 `{"source": "...", "path": "~/.claude/plugins/vendor/..."}` 형태로 directory 참조 가능하면 "directory source + vendor는 claude plugin install 시점 생성"을 채택. 불가하면 settings에서 zai 마켓 제외하고 glm-plan-usage 2종을 수동 예외로 둔다(Phase 3 런북에 기재).

- [ ] **Step 5: 검증 기록 커밋**

```bash
git add docs/superpowers/plans/2026-09-27-apm-agent-layer-phase0.md
git commit -m "docs(plans): apm Phase 0 거동 검증 기록"
```

---

### Task 2: `base/.apm/` 패키지 + 외부 skill manifest

**Files:**
- Create: `base/.apm/apm.yml`
- Create: `base/.apm/apm.lock.yaml` (apm 생성 후 repo로 이관)
- Create: `base/.stow-local-ignore` 없음 — `base/.apm/` 전체가 stow 대상

**Interfaces:**
- Consumes: 없음 (첫 task)
- Produces: `~/.apm/apm.yml` symlink(이후 모든 task의 배포 경로), manifest 구조(name/targets/dependencies.apm)

- [ ] **Step 1: manifest 작성**

`base/.apm/apm.yml`:

```yaml
name: global-agents
version: 1.0.0
description: User-global AI agent dependencies - external skills and MCP servers
author: Crong

targets:
  - claude
  - codex
  - gemini

dependencies:
  apm:
    - git: microsoft/azure-skills
    - git: firecrawl/anydoc
    - git: vercel-labs/skills
  mcp: []
```

- [ ] **Step 2: stow 배포 (머신 로컬 config.json과 공존)**

```bash
mkdir -p ~/.apm
stow --no-folding -t ~ base
ls -la ~/.apm/   # apm.yml이 symlink인지, config.json은 실체인지 확인
```

- [ ] **Step 3: 첫 설치 — lock 생성**

```bash
apm install -g
```

- [ ] **Step 4: lock을 repo로 이관 후 재배포**

```bash
# apm이 실체 파일로 만든 lock을 repo로 옮기고 다시 symlink
[[ -f ~/.apm/apm.lock.yaml && ! -L ~/.apm/apm.lock.yaml ]] && mv ~/.apm/apm.lock.yaml base/.apm/apm.lock.yaml
stow --no-folding -R -t ~ base
ls -la ~/.apm/apm.lock.yaml   # symlink 확인
```

- [ ] **Step 5: 검증 — skill 배포**

```bash
ls ~/.claude/skills/ ~/.agents/skills/ | grep -E 'convert-documents|find-skills|foundry'
# 기대: convert-documents-to-markdown, find-skills, microsoft-foundry 존재(또는 apm list에 표시)
apm list
```

자체 실디렉토리 보존 확인: `ls -d ~/.claude/skills/multi-agent-verification ~/.claude/skills/omc-reference`.

- [ ] **Step 6: Commit**

```bash
git add base/.apm/
git commit -m "feat(apm): user-global manifest 추가 - 외부 skill 3종"
```

---

### Task 3: MCP 6종 manifest 이관

**Files:**
- Modify: `base/.apm/apm.yml` (mcp: 블록)
- Modify: `base/.apm/apm.lock.yaml`

**Interfaces:**
- Consumes: `~/.apm/apm.yml` symlink(Task 2), Phase 0 문법(Task 1)
- Produces: 6개 MCP의 apm 선언(이후 install.sh가 재현), sops 변수 `APERTURE_MCP_URL`, `Z_AI_API_KEY`

- [ ] **Step 1: 배포 전 스냅샷**

```bash
claude mcp list > /tmp/mcp-before.txt 2>&1 || jq -r '.mcpServers | keys[]' ~/.claude.json > /tmp/mcp-before.txt
```

- [ ] **Step 2: CLI 생성 방식으로 manifest에 mcp 엔트리 추가 (최초 채택 예외)**

```bash
# ~/.apm/apm.yml이 repo symlink이므로 CLI가 곧 repo 파일에 기록한다
apm install -g --mcp zread --transport http --url "$(jq -r '.mcpServers.zread.url' ~/.claude.json)"
apm install -g --mcp web-reader --transport http --url "$(jq -r '.mcpServers["web-reader"].url' ~/.claude.json)"
apm install -g --mcp web-search-prime --transport http --url "$(jq -r '.mcpServers["web-search-prime"].url' ~/.claude.json)"
apm install -g --mcp aperture --transport http --url '${APERTURE_MCP_URL}'
apm install -g --mcp serena --transport stdio -- serena start-mcp-server --context=claude-code --project-from-cwd
apm install -g --mcp zai-mcp-server --transport stdio --env Z_AI_MODE="$(jq -r '.mcpServers["zai-mcp-server"].env.Z_AI_MODE // "claude"' ~/.claude.json)" --env Z_AI_API_KEY='${Z_AI_API_KEY}' -- npx -y @z_ai/mcp-server
```

- [ ] **Step 3: manifest 검토 — 리터럴 시크릿 제거**

```bash
cat base/.apm/apm.yml
# 확인: Z_AI_API_KEY는 ${Z_AI_API_KEY} placeholder, URL 3종(zread/web-reader/web-search-prime)은
# 공개 엔드포인트 리터럴, aperture는 ${APERTURE_MCP_URL}.
# 리터럴에 token/내부망 URL이 새어 있다면 ${VAR}로 수동 치환 후 재실행
```

- [ ] **Step 4: sops 변수 등록**

```bash
mkdir -p secrets
umask 077
{ echo "APERTURE_MCP_URL=$(jq -r '.mcpServers.aperture.url' ~/.claude.json)"; \
  echo "Z_AI_API_KEY=$(jq -r '.mcpServers["zai-mcp-server"].env.Z_AI_API_KEY' ~/.claude.json)"; } > secrets/mcp.env
sops -e secrets/mcp.env > secrets/mcp.env.sops
rm secrets/mcp.env
```

(secrets/*.sops는 기존 `.sops.yaml` path_regex `^secrets/.*` 매칭 — 규칙 변경 불필요)

- [ ] **Step 5: 전체 재설치 + 동등성 검증**

```bash
apm install -g
claude mcp list > /tmp/mcp-after.txt 2>&1 || jq -r '.mcpServers | keys[]' ~/.claude.json > /tmp/mcp-after.txt
diff <(sort /tmp/mcp-before.txt) <(sort /tmp/mcp-after.txt) && echo "동등 — OK"
# codex/gemini write 위치 실측 (spec 리스크 #4)
grep -A2 'mcp_servers.zread' ~/.codex/config.toml 2>/dev/null || echo "codex: 미기록"
jq '.mcpServers | keys' ~/.gemini/settings.json 2>/dev/null || echo "gemini: 미기록"
```

동등하지 않으면: 원인을 Phase 0 기록과 대조해 manifest 수정 후 재설치 (3-Strike: 2회 실패 시 중단하고 보고).

- [ ] **Step 6: symlink 생존 검증 (Review Focus #2)**

```bash
ls -la ~/.apm/apm.yml ~/.apm/apm.lock.yaml
# symlink가 실체로 교체되었다면: mv ~/.apm/apm.lock.yaml base/.apm/ && stow --no-folding -R -t ~ base
```

- [ ] **Step 7: Commit**

```bash
git add base/.apm/ secrets/mcp.env.sops
git commit -m "feat(apm): MCP 6종 user-global 이관 - sops 변수화"
```

---

### Task 4: settings.json 고정화 + plugin 선언적 설치

**Files:**
- Create: `base/.claude/settings.json` (live 파일 기준 생성)
- Delete: `eve/.claude/settings.json` (구 repo 템플릿)

**Interfaces:**
- Consumes: live `~/.claude/settings.json` (진실 원본), Phase 0 zai 마켓 판정(Task 1)
- Produces: stow 소유 고정 settings — `enabledPlugins` 28개 매트릭스, `extraKnownMarketplaces`

- [ ] **Step 1: live에서 고정 키만 추출해 repo 파일 생성**

```bash
# env는 제외(프로파일로 이동), tui 포함(provider 중립 UI 설정)
jq '{enabledPlugins, extraKnownMarketplaces, permissions, statusLine, language, autoCompactEnabled, editorMode, tui}' \
  ~/.claude/settings.json > base/.claude/settings.json
jq -r '.enabledPlugins | to_entries[] | select(.value==true) | .key' base/.claude/settings.json | wc -l   # 기대: 14
```

Phase 0에서 zai 마켓 directory-source 불가 판정이면: `jq 'del(.extraKnownMarketplaces["zai-coding-plugins"]) ...` 로 제거 후 재생성.

- [ ] **Step 2: live 파일 교체 — stow 소유로**

```bash
cp ~/.claude/settings.json ~/.claude/settings.json.bak-profile   # 프로파일 원본 보존
rm ~/.claude/settings.json
stow --no-folding -R -t ~ base
ls -la ~/.claude/settings.json   # → repo base/.claude/settings.json symlink
diff <(jq -S 'del(.env)' ~/.claude/settings.json.bak-profile) <(jq -S 'del(.env)' <(cat base/.claude/settings.json; echo '{}')) | head
# 또는 단순 키 대조:
jq -S 'del(.env)' ~/.claude/settings.json.bak-profile > /tmp/a.json
jq -S . base/.claude/settings.json > /tmp/b.json
diff /tmp/a.json /tmp/b.json   # env 외 동일해야 함(추가된 키 없음 확인)
```

- [ ] **Step 3: 구 repo 템플릿 제거**

```bash
git rm eve/.claude/settings.json
```

- [ ] **Step 4: 백업 보존 후 smoke — 세션 밖 CLI로 plugin 상태 확인**

```bash
claude plugin list --json | jq -r '.[] | .id' 2>/dev/null | sort > /tmp/plugins-cli.txt || claude plugin list
```

- [ ] **Step 5: 첫 세션 자동 설치 확인 (Review Focus #3)**

```bash
claude -p 'plugin sync check' --settings base/.claude/settings.json > /dev/null 2>&1 || true
claude plugin list --json | jq -r '.[] | select(.enabled==false) | .id' | sort > /tmp/plugins-disabled.txt
wc -l /tmp/plugins-disabled.txt   # false 항목이 설치되지 않았거나 disabled 상태여야 함
```

- [ ] **Step 6: Commit**

```bash
git add base/.claude/settings.json
git commit -m "feat(claude): settings 고정화 - plugin 매트릭스 stow 소유 전환"
```

---

### Task 5: provider 프로파일 → sops env + overlay

**Files:**
- Create: `base/.config/claude/profiles/zai.env.sops`, `kimi.env.sops`, `aperture.env.sops`
- Create: `base/.config/claude/profiles/aperture.overlay.json`
- Create: `base/.config/claude/profiles/env.example`
- Modify: `eve/.alias` (claude-profile 함수)
- Delete: `eve/.claude/settings.zai`, `settings.kimi`, `settings.aperture`

**Interfaces:**
- Consumes: `eve/.claude/settings.{zai,kimi,aperture}`의 env 블록, `~/.claude/settings.json.bak-profile`
- Produces: `claude-profile <zai|kimi|aperture> [args...]` 셸 함수

- [ ] **Step 1: env 추출 → dotenv → sops (패턴 2: 값만 암호화)**

```bash
mkdir -p /tmp/profiles base/.config/claude/profiles
umask 077
for p in zai kimi aperture; do
  jq -r '.env | to_entries[] | "\(.key)=\(.value|tostring)"' "eve/.claude/settings.$p" > "/tmp/profiles/$p.env"
  sops -e "/tmp/profiles/$p.env" > "base/.config/claude/profiles/$p.env.sops"
done
rm -rf /tmp/profiles   # 평문 삭제
```

(`.sops.yaml` path_regex `.*/\.env\.sops` 매칭 — 규칙 변경 불필요)

- [ ] **Step 2: overlay + env.example**

```bash
jq '{apiKeyHelper}' eve/.claude/settings.aperture > base/.config/claude/profiles/aperture.overlay.json
{ jq -r '.env|keys[]' eve/.claude/settings.zai; jq -r '.env|keys[]' eve/.claude/settings.kimi; jq -r '.env|keys[]' eve/.claude/settings.aperture; } | sort -u | sed 's/$/=/' > base/.config/claude/profiles/env.example
```

- [ ] **Step 3: 로더 함수 — `eve/.alias` 말미에 추가**

```zsh
# claude provider profile loader (apm agent layer 설계)
# usage: claude-profile zai|kimi|aperture [claude args...]
claude-profile() {
  local p="$1"; shift
  local d="$HOME/.config/claude/profiles"
  if [[ ! -r "$d/$p.env.sops" ]]; then
    echo "claude-profile: unknown profile '$p' (expected: zai|kimi|aperture)" >&2; return 1
  fi
  eval "$(sops -d "$d/$p.env.sops")"
  if [[ -r "$d/$p.overlay.json" ]]; then
    claude --settings "$d/$p.overlay.json" "$@"
  else
    claude "$@"
  fi
}
```

- [ ] **Step 4: 구 프로파일 제거 + 배포**

```bash
git rm eve/.claude/settings.zai eve/.claude/settings.kimi eve/.claude/settings.aperture
stow --no-folding -R -t ~ base eve
source ~/.zshrc 2>/dev/null || true
```

- [ ] **Step 5: smoke — 3 프로파일 전환**

```bash
claude-profile zai -p 'echo ok' 2>&1 | tail -1
claude-profile aperture -p 'echo ok' 2>&1 | tail -1
claude-profile kimi -p 'echo ok' 2>&1 | tail -1
# 각각 정상 응답하면 통과. token 오류 시 sops 복호화 결과 확인: sops -d base/.config/claude/profiles/zai.env.sops | head -2
```

- [ ] **Step 6: Commit**

```bash
git add base/.config/claude/profiles/ eve/.alias
git commit -m "feat(claude): provider 프로파일 sops env 전환 - 평문 token 제거"
```

주의: 구 token은 git history에 잔존 — 폐기/rotation은 별도 작업(Runbook 참조).

---

### Task 6: skills CLI 폐지 + drift 정리 (홈 영역, 커밋 없음)

**Files:**
- 없음 (repo 변경 없음 — 홈 상태 정리)

**Interfaces:**
- Consumes: Task 2의 apm 스킬 배포
- Produces: `~/.agents/.skill-lock.json` 제거, plugin cache debris 정리

- [ ] **Step 1: skills CLI lock 제거**

```bash
mv ~/.agents/.skill-lock.json ~/.agents/.skill-lock.json.bak   # 보존 후 관찰 기간
```

- [ ] **Step 2: skills-CLI symlink 잔여 정리 (자체 실디렉토리 보존!)**

```bash
# apm/skills-CLI 양쪽이 만든 symlink 중 repo가 미관리하는 것만 확인
ls -la ~/.claude/skills/
# multi-agent-verification, omc-reference (실디렉토리) 는 절대 건드리지 않는다
# apm이 배포한 스킬과 겹치는 symlink가 깨져 있으면 해당 symlink만 제거 후 apm install -g 재실행
```

- [ ] **Step 3: plugin cache debris 정리**

```bash
ls -d ~/.claude/plugins/cache/temp_* 2>/dev/null | wc -l   # ~40개 확인
rm -rf ~/.claude/plugins/cache/temp_git_*.clone ~/.claude/plugins/cache/temp_subdir_*.clone
```

- [ ] **Step 4: `~/.claude/CLAUDE.md` drift 재연결 (선택)**

```bash
diff ~/.claude/CLAUDE.md base/.claude/CLAUDE.md | head   # 분기 내용 확인 후
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak-omc
stow --no-folding -R -t ~ base
```

- [ ] **Step 5: 평문 token 최종 검증 (Review Focus #4)**

```bash
git grep -n 'ANTHROPIC_AUTH_TOKEN' -- ':!*.sops' || echo "repo 평문 없음 — OK"
gitleaks detect --source . --no-banner && echo "gitleaks clean"
```

---

### Task 7: `install.sh` + README Install 갱신

**Files:**
- Create: `install.sh` (repo root)
- Modify: `README.md` (Install 섹션)

**Interfaces:**
- Consumes: `base/.apm/`(Task 2~3), `base/.claude/settings.json`(Task 4), `base/.config/claude/profiles`(Task 5)
- Produces: `./install.sh <host> [--dry-run]` — 신규 장비 재현 CLI (kyolim 제외)

- [ ] **Step 1: 스크립트 작성**

`install.sh`:

```bash
#!/usr/bin/env bash
# dotfiles bootstrap - OS layer(stow/brew) + AI agent layer(apm)
# usage: ./install.sh <eve|axiom|bazzite|girl|auxo> [--dry-run]
set -euo pipefail

HOST="${1:?usage: ./install.sh <eve|axiom|bazzite|girl|auxo> [--dry-run]}"
DRY_RUN="${2:-}"
REPO="$(cd "$(dirname "$0")" && pwd)"

run() {
  if [[ "$DRY_RUN" == "--dry-run" ]]; then echo "[dry-run] $*"; else "$@"; fi
}

case "$HOST" in
  eve|axiom)   PKGS="base $HOST" ;;
  bazzite)     PKGS="base bazzite" ;;   # mo
  girl|auxo)   PKGS="base $HOST" ;;
  *) echo "install.sh: unknown host '$HOST'" >&2; exit 1 ;;
esac

echo "==> [1/5] stow 배포: $PKGS"
run mkdir -p "$HOME/.apm" "$HOME/.claude"
run stow --no-folding -d "$REPO" -t ~ $PKGS
# 호스트에 실재하는 ~/.claude/settings.json이 있으면 백업 후 재배포
if [[ ! -L "$HOME/.claude/settings.json" && -f "$HOME/.claude/settings.json" && "$DRY_RUN" != "--dry-run" ]]; then
  cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.bak-$(date +%Y%m%d%H%M%S)"
  rm "$HOME/.claude/settings.json"
  stow --no-folding -R -d "$REPO" -t ~ $PKGS
fi

echo "==> [2/5] brew bundle (brew 있는 호스트)"
if command -v brew >/dev/null 2>&1; then
  run brew bundle -g
elif [[ "$HOST" == "girl" || "$HOST" == "auxo" ]]; then
  echo "    (brew 없음 — mise/apt는 수동, apm은 다음 단계에서 curl 설치)"
fi

echo "==> [3/5] apm CLI"
if ! command -v apm >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    run brew install apm
  else
    run bash -c 'curl -sSL https://aka.ms/apm-unix | sh'
  fi
fi

echo "==> [4/5] sops 키 확인"
if [[ -f "$HOME/.key" ]] && command -v sops >/dev/null 2>&1; then
  sops -d "$HOME/.key" >/dev/null 2>&1 && echo "    sops 복호화 OK" || echo "    (경고) ~/.key 복호화 실패 — MCP 인증 env는 미설정"
else
  echo "    (건너뜀) ~/.key 없음 — 신규 호스트면 age key 복원 먼저"
fi

echo "==> [5/5] apm install -g (AI agent layer)"
run apm install -g --frozen || { echo "    frozen 실패 — lock 갱신 필요. 'apm install -g' 후 lock 커밋"; run apm install -g; }

echo "완료. 첫 claude 세션에서 plugin이 자동 설치됩니다. provider 전환: claude-profile zai|kimi|aperture"
```

- [ ] **Step 2: 문법·정적 검증**

```bash
chmod +x install.sh
bash -n install.sh && echo "syntax OK"
command -v shellcheck >/dev/null && shellcheck install.sh || echo "(shellcheck 없음 — skip)"
```

- [ ] **Step 3: dry-run 검증**

```bash
./install.sh eve --dry-run
# 기대: 각 단계가 [dry-run]으로 표시되고 시스템 변경 없음. exit 0
```

- [ ] **Step 4: README.md Install 섹션 갱신**

`## Install` 코드 블록을 아래로 교체(기존 stow 상세 설명은 `## Stow Adopt`와 중복最小化, walle는 기존 수동 절차 유지):

```markdown
## Install

```bash
git clone git@github.com:deuxksy/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles

# macOS / Linux 호스트 — 1커맨드 bootstrap (stow + brew + apm)
./install.sh eve     # 또는 axiom | bazzite | girl | auxo

# walle (Proxmox) — 기존 수동 절차
sudo apt install -y stow
stow -t ~ base walle
sudo stow -t / walle-sudo
```

AI agent layer: `apm install -g`가 skill·MCP를 claude/codex/gemini에 배포하고, 첫 claude 세션에서 plugin이 자동 설치된다. 상세 설계는 [apm Agent Layer Design](docs/okf/explanation/2026-09-27-apm-agent-layer-design.md).
```

- [ ] **Step 5: 실사용 검증 — eve에서 2회 연속 실행 (Review Focus #5)**

```bash
./install.sh eve && echo "--- 2nd run ---" && ./install.sh eve
# 기대: 두 번 모두 exit 0, 변경 파일 없음(멱등). stow 충돌/에러 없음
```

- [ ] **Step 6: Commit**

```bash
git add install.sh README.md
git commit -m "feat(install): 신규 장비 bootstrap 스크립트 - stow+brew+apm 일원화"
```

---

### Task 8: Brewfile apm 등록 + kyolim install.ps1 확장

**Files:**
- Modify: `eve/.homebrew/Brewfile`, `axiom/.homebrew/Brewfile`, `bazzite/.homebrew/Brewfile`
- Modify: `windows/install.ps1`
- Create: `windows/tests/install-apm.Tests.ps1`
- Modify: `windows/README.md`

**Interfaces:**
- Consumes: `base/.apm/`, `base/.claude/settings.json`, `base/.config/claude/`(Task 2~5 산출물)
- Produces: kyolim 재현 CLI(`windows/install.ps1` apm 단계)

- [ ] **Step 1: Brewfile 3종에 apm 추가 (알파벳순 위치)**

각 파일의 `brew "..."` 목록에서 알파벳순 위치에 한 줄 추가:

```ruby
brew "apm"
```

- [ ] **Step 2: install.ps1에 apm 단계 추가**

`windows/install.ps1`의 claude 섹션 뒤에 추가(기존 "settings.json은 로컬 유지" 주석은 제거 — 고정 파일 방식으로 변경):

```powershell
# Claude settings.json 고정 파일 (stow 소유 분리 설계 - env는 프로파일로 분리)
New-Item -ItemType SymbolicLink -Path "$claudeDir\settings.json" -Target "$dotfiles\base\.claude\settings.json" -Force

# --- AI agent layer (apm) ---
$apmDir = "$env:USERPROFILE\.apm"
if (-not (Test-Path $apmDir)) { New-Item -ItemType Directory -Path $apmDir -Force }
New-Item -ItemType SymbolicLink -Path "$apmDir\apm.yml" -Target "$dotfiles\base\.apm\apm.yml" -Force
New-Item -ItemType SymbolicLink -Path "$apmDir\apm.lock.yaml" -Target "$dotfiles\base\.apm\apm.lock.yaml" -Force

# provider profiles (~/.config/claude)
$claudeCfg = "$env:USERPROFILE\.config\claude"
if (-not (Test-Path "$env:USERPROFILE\.config")) { New-Item -ItemType Directory -Path "$env:USERPROFILE\.config" -Force }
if (-not (Test-Path $claudeCfg)) { New-Item -ItemType Junction -Path $claudeCfg -Target "$dotfiles\base\.config\claude" -Force }

if (-not (Get-Command apm -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.APM --exact --source winget
}
# codex/gemini 미설치 시 targets 거동이 불확실하면 claude만 대상으로 (Phase 0 #8 판정 반영)
apm install -g --frozen
if ($LASTEXITCODE -ne 0) { apm install -g }
```

- [ ] **Step 3: Pester 테스트 작성**

`windows/tests/install-apm.Tests.ps1`:

```powershell
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) "install.ps1"
$scriptContent = Get-Content $scriptPath -Raw

function Assert-Contains {
    param([string]$Expected, [string]$Message)
    if (-not $scriptContent.Contains($Expected)) { throw $Message }
}

Assert-Contains '-Target "$dotfiles\base\.apm\apm.yml"' "apm manifest는 base 패키지를 junction/symlink로 가리켜야 합니다 (windows 중복 금지)"
Assert-Contains '-Target "$dotfiles\base\.claude\settings.json"' "settings.json은 base 고정 파일을 가리켜야 합니다"
Assert-Contains 'apm install -g' "apm install -g 단계가 있어야 합니다"
Assert-Contains 'Microsoft.APM' "apm CLI는 winget Microsoft.APM으로 설치해야 합니다"

Write-Host "install-apm tests passed"
```

- [ ] **Step 4: 테스트 실행**

```bash
pwsh -NoProfile -File windows/tests/install-apm.Tests.ps1
# 기대: "install-apm tests passed"
# 기존 회귀: pwsh -NoProfile -File windows/tests/install-claude-links.Tests.ps1
```

- [ ] **Step 5: windows/README.md에 apm 단계 설명 1문단 추가**

`windows/README.md`에 추가:

```markdown
## AI Agent Layer (apm)

`install.ps1`가 `base\.apm\` manifest를 `%USERPROFILE%\.apm\`에 symlink하고 `apm install -g`로
skill·MCP를 배포한다. provider 전환은 sops env 프로파일 기반(설계: [apm Agent Layer Design](../docs/okf/explanation/2026-09-27-apm-agent-layer-design.md)).
kyolim 실제 적용 순서: 관리자 pwsh → `install.ps1` → 첫 claude 세션(자동 plugin 설치) → `claude-profile` smoke.
```

- [ ] **Step 6: Commit**

```bash
git add eve/.homebrew/Brewfile axiom/.homebrew/Brewfile bazzite/.homebrew/Brewfile windows/install.ps1 windows/tests/install-apm.Tests.ps1 windows/README.md
git commit -m "feat(install): kyolim apm 배포 단계 및 Brewfile apm 등록"
```

---

## Phase 2/3 실행 런북 (repo 작업 완료 후, 각 호스트에서 수행)

각 호스트(axiom → mo → girl → auxo → kyolim 순서 권장 — 가장 단순한 macOS부터):

1. `git pull` 후 기존 `~/.claude/settings.json`이 실재하면 `install.sh`가 자동 백업·교체
2. `./install.sh <host>` (kyolim은 관리자 pwsh로 `windows/install.ps1`)
3. verify: `ls -la ~/.apm/apm.yml`(symlink), `claude mcp list`(6개), 첫 세션 후 `claude plugin list --json`(14 true)
4. girl/auxo: codex/gemini 설치 안 된 경우 `apm install -g --target claude` 필요 여부 확인 (Phase 0 #8)
5. kyolim: sops age key + `~/.key` 복원, `claude-profile` 부재 확인(로더는 eve/.alias에 있음 — kyolim은 필요시 수동 env)

## Self-Review 기록

- Spec coverage: manifest(T2-3), settings 분리(T4-5), skills CLI 폐지(T6), install.sh(T7), kyolim(T8), secrets(T3-5), 검증 체크포인트 6건(T2 S5/T3 S5/T4 S5/T6 S5/T7 S5/T8 S4), drift 치유(T4 S2/T6), README 갱신(T7 S4) — 전 항목 커버
- Placeholder: 없음 (모든 step에 실행 가능한 코드/명령/기대값 명시)
- Interface 일관성: `claude-profile zai|kimi|aperture`(T5 정의, T7 출력 메시지에서 동일), `~/.apm/apm.yml` symlink(T2 생성, T3/T7/T8 소비), `base/.claude/settings.json`(T4 생성, T7/T8 소비) — 일치
- Review Focus 5건 각각 방어 step 지정 완료
