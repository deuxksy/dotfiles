# Chezmoi Migration Roadmap

현재 `GNU Stow` + `install.sh` + `windows/install.ps1` 기반 dotfiles를 **chezmoi** 단일 소스로 단계적 전환하기 위한 로드맵입니다.

## 목표

1. **AI Agent 설정 단일화**: `claude`, `codex`, `agy`, `apm` symlink 깨짐(`apm:repair`) 해소 및 OS/호스트별 중복 제거
2. **크로스플랫폼 통합**: `macOS` (`axiom`, `eve`), `Linux` (`walle`, `girl`, `auxo`), `Windows` (`kyolim`, `ava`)를 `chezmoi apply` 하나로 통합
3. **시크릿·부트스트랩 내장**: `sops`/`age` 복호화 및 `brew bundle`, `apm install -g`를 `chezmoi` 스크립트(`run_onchange_`)로 통합
4. **무중단 전환**: 각 Phase별 `chezmoi diff` 검증 후 점진적 이관 (기존 Stow 환경과 충돌 방지)

---

## Phase 0: 준비 및 기준선 확보

- [x] `chezmoi` 설치 (macOS `Brewfile`, Linux, Windows `winget`/`scoop`)
- [x] `.chezmoi.toml.tmpl` 설계 — 호스트 식별(`axiom`, `eve`, `walle`, `girl`, `auxo`, `kyolim`, `ava`) 및 OS별 변수 정의
- [x] `sops` / `age` 연동 방식 확정 (`~/.key` 기반 `chezmoi` 암호화/복호화 테스트)
- [x] 전환 기간 중 Stow와의 충돌 방지를 위해 `chezmoi --source ./chezmoi` 또는 전용 브랜치 전략 확정

## Phase 1: AI Agent Layer PoC (`claude`, `codex`, `agy`, `apm`)

가장 불편함이 큰 AI agent 영역부터 우선 전환합니다.

- [x] `dot_apm/` 이관 (`apm.yml`, `apm.lock.yaml`) — symlink 제거로 `apm:repair` 불필요화
- [x] `run_onchange_after_apm-install.sh.tmpl` 작성 (`apm.yml` 해시 변경 시 `apm install -g` 자동 실행)
- [x] `dot_claude/` 통합 (`base/.claude/`, `windows/.claude/`, `kyolim/.claude/` → `settings.json.tmpl` + 공통 `rules/`)
- [x] `dot_codex/` 이관 (`AGENTS.md`, `rules/`)
- [x] `dot_gemini/` 이관 (`GEMINI.md`, `rules/`, `antigravity-cli/settings.json.tmpl`)
- [x] ~~`dot_config/claude/profiles/` (`*.env.sops`) 복호화·배치 검증~~ — 2026-11-28 제거 (Claude Code 지원 기능 아님, provider 설정은 `settings.json` `env` 블록으로)
- [x] `eve`(macOS)에서 `chezmoi diff` 및 `chezmoi apply` 실검증

## Phase 2: `base/` 공통 POSIX 설정 이관

- [ ] 셸 설정 이관 (`.zshrc`, `.alias`, `.function`, `.path`)
- [ ] 개발 도구 설정 이관 (`.gitconfig`, `.tmux.conf`, `.wezterm.lua`, `.config/nvim/`, `.config/ghostty/`, `.config/himalaya/`, `.config/starship.toml`, `.config/atuin/`, `.config/mise/`)
- [ ] 기존 `base/` Stow symlink 해제(`stow -D -t ~ base`) 후 `chezmoi apply` 전환

## Phase 3: 호스트별 패키지 및 Windows 통합

- [ ] macOS (`axiom`, `eve`) — `.homebrew/Brewfile` 연동 (`run_onchange_`로 `brew bundle -g` 실행), `.tmuxp/`, `.holmes/`, `axiom` `ttyd`/`webssh2`
- [ ] Linux (`walle`, `girl`, `auxo`) — 호스트별 오버라이드 `.tmpl` 통합 (`walle-sudo/`는 root 권한 특성상 별도 유지 여부 결정)
- [ ] Windows (`windows/`, `kyolim`, `ava`) — `install.ps1` 로직을 `chezmoi` 템플릿 + PowerShell `run_onchange_` 스크립트로 통합

## Phase 4: 정리 및 레거시 제거

- [ ] `mise.toml` 업데이트 (`stow:check`, `apm:repair` 제거 → `chezmoi diff --check` / `chezmoi doctor` 연동)
- [ ] `install.sh`, `windows/install.ps1`, Stow 패키지 디렉토리 정리 또는 아카이브
- [ ] `README.md`, `.ai/RULES.md`, `docs/` 문서를 `chezmoi` 기준으로 최종 갱신

---

## 검증 기준 (각 Phase 완료 조건)

- `chezmoi diff` 실행 시 의도치 않은 변경 0건
- `mise run lint:secrets` (gitleaks) 통과 — 평문 시크릿 유출 없음
- 대상 호스트에서 신규 클론 후 `chezmoi init --apply` 1커맨드 재현 가능
