# Chezmoi Phase 1 (AI Agent Layer PoC) Design

## Intent

`GNU Stow` 환경에서 가장 불편함이 큰 AI agent 설정(`claude`, `codex`, `agy`, `apm`)을 `chezmoi`로 우선 전환하여 symlink 깨짐(`apm:repair`), OS/호스트별 중복, `apm install -g` 수동 실행 문제를 검증·해소한다.

## Scope

- **포함**: `.chezmoiroot` (`chezmoi`), `chezmoi/.chezmoi.toml.tmpl`, `dot_apm/`, `dot_claude/`, `dot_codex/`, `dot_gemini/`, `run_onchange_after_apm-install.sh.tmpl`
- **제외**: `base/`의 나머지 셸·nvim 설정, 타 호스트 전체 이관, `mise.toml` 태스크 변경

## Architecture

- `.chezmoiroot`에 `chezmoi`를 지정하여 기존 Stow 디렉토리(`base/`, `eve/`, `windows/` 등)와 충돌 없이 공존
- `dot_apm/apm.yml` 변경 시 `run_onchange_after_apm-install.sh.tmpl`이 `sha256sum` 기반으로 `apm install -g` 자동 실행
- `dot_claude/settings.json.tmpl` 및 `dot_gemini/antigravity-cli/settings.json.tmpl`에서 OS/호스트별 차이 분기

## Verification

- `chezmoi --source ./chezmoi diff`로 현재 `eve` 홈 디렉토리와의 차이 검증
- `chezmoi --source ./chezmoi apply` 적용 후 `~/.apm/apm.yml`이 일반 파일로 배치되고 `apm` 동작이 정상인지 확인
