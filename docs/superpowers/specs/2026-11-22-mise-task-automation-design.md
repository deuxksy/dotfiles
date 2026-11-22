# Dotfiles `mise.toml` Task Automation Design (Phase 1)

- **Date**: 2026-11-22
- **Status**: Approved
- **Scope**: Small Change (루트 `mise.toml` + `.ai/RULES.md` 문서화)

---

## 1. Intent & Why

dotfiles 저장소에서 사람과 AI Agent가 반복적으로 수행하는 검증(`shellcheck`, `gitleaks`, `stow` dry-run, Windows 회귀 테스트), 상태 진단(`doctor`, `sops` 복호화), 복구(`hooks:install`, `apm` R8 복구, `sops:edit`)를 루트 `mise.toml`의 선언적 `[tools]` + `[tasks]`로 고정한다. AI Agent의 non-interactive 셸에서도 동일하게 실행되도록 Task 기반(`mise run`)을 표준 인터페이스로 삼고, 기존 `[hooks] enter = "git pull --ff-only"`는 그대로 유지한다.

## 2. Goals, Non-Goals & Anti-Goals

- **Goals**
  - 루트 `mise.toml`에 기존 `[hooks]`를 유지한 채 `[tools]`(`gitleaks`, `shellcheck`)와 10개 핵심 `[tasks]`(검증 5 + 진단 2 + 복구/유지보수 3)를 선언한다.
  - AI Agent와 사람이 `mise run verify` / `mise run doctor` 단일 진입점으로 저장소 무결성을 검증할 수 있게 한다.
  - `.ai/RULES.md`에 표준 `mise run` 명령어를 반영한다.
- **Non-Goals (Phase 1 제외)**
  - 호스트별 `<host>/.config/mise/config.toml`(이미 7개 호스트에 존재)을 통합하거나 `base/.config/mise/config.toml`을 신설하지 않는다(stow 충돌 방지).
  - 배포/동기화 태스크(`stow:apply`, `apm:sync`, `brew:sync`, `nvtools:install`, `bootstrap`)와 `install.sh` / `windows/install.ps1` 변경은 Phase 1에서 제외하고 검증 성공 후 점진 확장한다.
  - `.githooks/post-merge`나 `[[watch_files]]` 같은 추가 자동 트리거는 도입하지 않는다.
- **Anti-Goals**
  - 기존 `[hooks] enter = "git pull --ff-only"` 동작을 깨뜨리지 않는다.
  - `pwsh`가 없는 POSIX 호스트에서 `mise run verify`가 실패하게 만들지 않는다(`test:windows`는 `pwsh` 미설치 시 안내 후 통과).

## 3. Constraints

- **Stow 충돌 방지**: `mise` 설정은 루트 `mise.toml`에만 둔다.
- **R8 규칙 준수**: `apm:repair`는 `~/.apm/apm.yml` symlink 깨짐 복구(`stow --no-folding -R -t ~ base`)와 `apm.lock.yaml` repo 이관을 모두 다룬다.
- **호스트 자동 감지**: `stow:check`는 현재 호스트명(`hostname -s` 등)으로 대응 호스트 패키지가 있으면 `base <host>`, 없으면 `base`만 dry-run 검사한다(인자 오버라이드 지원).
- **Non-interactive 호환**: 모든 검증·진단 태스크는 CI/AI Agent 환경에서 프롬프트 없이 종료 코드로 성공/실패를 반환한다.

## 4. Approaches Considered

| Approach | 포함 범위 | Trade-off |
| :--- | :--- | :--- |
| **1. 검증 + 진단/복구 중심 (Selected)** | `1 + 2 + 4` 그룹 (10개 태스크) — 루트 `mise.toml`만 수정 | 시스템 배포 흐름(`install.sh`/`stow`)에 영향 0. 기계적 자동화를 안전하게 검증 후 확장 가능. |
| 2. 검증 + 진단 + 핵심 배포 | Option 1 + `stow:apply`, `apm:sync` | 배포 실수 방지 효과는 크지만 Phase 1 변경·테스트 범위가 넓어짐. |
| 3. 16개 전체 통합 | `1 + 2 + 3 + 4` 그룹 전체 | 단일 인터페이스 완성도는 높지만 `brew`/`nvtools` 등 호스트 종속 분기가 많아 초기 복잡도 상승. |

**선택 이유**: 기계적 검증·진단·복구 자동화를 리스크 없이 먼저 안착시키고, 동작이 확인되면 배포 태스크로 점진 확장한다.

## 5. Decided Design (`mise.toml`)

### 5.1 `[hooks]` (기존 유지)
```toml
[hooks]
enter = "git pull --ff-only"
```

### 5.2 `[tools]` (Repo 검증 도구 고정)
- `aqua:gitleaks/gitleaks` (`latest` 또는 고정 버전)
- `aqua:koalaman/shellcheck` (`latest` 또는 고정 버전)

### 5.3 `[tasks]` (10개)

| 그룹 | Task | CLI 동작 | 비고 |
| :--- | :--- | :--- | :--- |
| **검증** | `lint:shell` | `shellcheck install.sh .githooks/pre-push */scripts/install_nvtools.sh` | `sources` 지정으로 증분 실행 |
| | `lint:secrets` | `gitleaks detect --no-banner` | 로컬 시크릿 누출 스캔 |
| | `stow:check` | `stow --no-folding -n -v -t ~ base [host]` | 호스트 패키지 존재 시 함께 dry-run |
| | `test:windows` | `pwsh -NoProfile -Command 'Invoke-Pester windows/tests/*.Tests.ps1'` | `pwsh` 미설치 시 skip 안내 후 exit 0 |
| | `verify` | `depends = ["lint:shell", "lint:secrets", "stow:check", "test:windows"]` | 통합 검증 게이트 |
| **진단** | `doctor` | `core.hooksPath`, `~/.apm/apm.yml`·`~/.claude/settings.json` symlink, `sops -d ~/.key`, 필수 바이너리 일괄 체크 | 실패 항목 요약 출력 |
| | `sops:check` | `~/.key` 및 `base/.config/claude/profiles/*.env.sops` 복호화 테스트 | dotenv 타입 플래그 포함 |
| **복구** | `hooks:install` | `git config core.hooksPath .githooks` | idempotent 설정 |
| | `apm:repair` | `~/.apm/apm.yml` 백업·제거 후 `stow --no-folding -R -t ~ base`, `apm.lock.yaml` 비-symlink 시 repo 이관 | R8 복구 절차 자동화 |
| | `sops:edit` | `sops --input-type dotenv --output-type dotenv base/.config/claude/profiles/<name>.env.sops` | 대상 파일명 인자 전달 |

### 5.4 문서화
- `.ai/RULES.md`의 `## Commands` 섹션에 `mise run verify`, `mise run doctor`, `mise run apm:repair`, `mise run hooks:install` 추가.

## 6. Left to the Builder

- `mise.toml`의 `aqua:` 정확한 패키지 식별자·버전 핀닝 확인 (`mise install`로 실제 설치 검증).
- `lint:shell` 실행 시 기존 `*/scripts/install_nvtools.sh`에서 기존 경고가 나올 경우 severity 옵션(`--severity=warning` 등) 조정 여부 판단.
- `sops:edit`의 인자 처리 방식(`mise` task 인자 전달 또는 `usage` 스펙).
