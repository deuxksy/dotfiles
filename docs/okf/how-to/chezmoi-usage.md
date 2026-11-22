# Chezmoi Usage Guide

이 저장소에서 `chezmoi`로 dotfiles(현재 Phase 1: `claude`, `codex`, `agy`, `apm`)를 관리하는 기본 사용법입니다.

> 전환 기간 중에는 저장소 내 `chezmoi/` 디렉토리를 소스로 사용하므로 `--source ./chezmoi` 옵션을 함께 사용합니다.

## 1. 초기 설정 및 적용

```bash
cd ~/git/dotfiles

# 1) 호스트/OS 설정 초기화 (~/.config/chezmoi/chezmoi.toml 생성)
chezmoi --source ./chezmoi init

# 2) 홈 디렉토리에 적용될 변경 사항 미리보기
chezmoi --source ./chezmoi diff

# 3) 실제 홈 디렉토리에 반영 (apm.yml 변경 시 apm install -g 자동 실행)
chezmoi --source ./chezmoi apply
```

기존 Stow symlink를 덮어써야 할 때는 `--force`를 붙입니다:

```bash
chezmoi --source ./chezmoi apply --force
```

## 2. 로컬 변경 사항 저장소로 역반영 (`re-add`)

`chezmoi`는 symlink가 아닌 일반 파일을 배치하므로, `apm install -g` 등이 `~/.apm/apm.lock.yaml`을 수정한 뒤에는 `re-add`로 저장소에 반영합니다.

```bash
# 특정 파일만 저장소(chezmoi/)로 역반영
chezmoi --source ./chezmoi re-add ~/.apm/apm.lock.yaml

# 변경된 관리 대상 전체 역반영
chezmoi --source ./chezmoi re-add
```

## 3. 자주 쓰는 명령어

| 명령어 | 설명 |
| :--- | :--- |
| `chezmoi --source ./chezmoi status` | 저장소와 `$HOME` 간 차이가 있는 파일 목록 확인 |
| `chezmoi --source ./chezmoi diff` | 실제 반영 전 diff 미리보기 |
| `chezmoi --source ./chezmoi apply` | 저장소 내용을 `$HOME`에 적용 |
| `chezmoi --source ./chezmoi re-add <path>` | `$HOME`에서 수정된 파일을 저장소로 가져오기 |
| `chezmoi --source ./chezmoi edit <path>` | 저장소 원본 파일을 에디터로 열기 |
| `chezmoi --source ./chezmoi managed` | 현재 `chezmoi`가 관리 중인 파일 목록 확인 |
| `chezmoi doctor` | `chezmoi` 환경 및 의존성 진단 |

## 4. 자동 실행 스크립트 (`run_onchange_`)

- [run_onchange_after_apm-install.sh.tmpl](../../../chezmoi/run_onchange_after_apm-install.sh.tmpl)은 `dot_apm/apm.yml`의 SHA256 해시가 바뀔 때만 `chezmoi apply` 후 `apm install -g`를 자동 실행합니다.
- `apm.yml`이 변경되지 않았다면 재실행되지 않습니다.
