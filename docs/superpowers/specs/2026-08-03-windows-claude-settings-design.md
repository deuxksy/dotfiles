# Windows Claude 로컬 설정 분리 설계

- [배경](#배경)
- [목표](#목표)
- [레이어 구조](#레이어-구조)
- [변경 내용](#변경-내용)
- [배포 절차](#배포-절차)
- [검증](#검증)
- [주의사항](#주의사항)

## 배경

repo 루트 `.claude/settings.local.json`이 git symlink(mode 120000)로 추적되며 target은 `/home/deck/.claude/settings.local.json`(deck 호스트 전용)이다. Windows는 `core.symlinks=false`로 체크아웃되어 symlink target 경로가 텍스트로 materialize되고, Claude Code가 이를 JSON으로 파싱하지 못해 `/doctor`가 "Invalid or malformed JSON"을 보고한다.

Windows에서는 stow를 사용할 수 없으므로 `windows/install.ps1`(관리자 권한, SymbolicLink/Junction)이 배포를 담당한다.

## 목표

- Windows 회사 노트북(hostname kyolim, 사용자 crong)의 Claude 로컬 설정을 OS 레이어로 분리: `windows/` = Windows 공통
- deck 등 기존 호스트의 동작 변경 없음

> repo 루트 `.claude/settings.local.json`의 malformed JSON(`/doctor` 이슈)은 이 설계에서 처리하지 않는다. 별도 처리 필요.

## 레이어 구조

```text
base/     → OS 공통 + non-Windows (deck, mac 등) — 이번 범위에서 변경 없음
windows/  → Windows 공통 (모든 Windows 머신)
kyolim/   → 이 PC 전용 (현재 설정 파일 없음, 필요 시 추가)
```

## 변경 내용

1. `windows/.claude/settings.local.json` (신규)
   - `base/.claude/settings.local.json` 내용을 시드로 복사
2. `base/.claude/settings.local.json`
   - 변경 없음 (surgical change 원칙 — Windows 전용 항목 정리는 별도 작업)
3. `windows/install.ps1` 수정
   - 글로벌 링크 `$env:USERPROFILE\.claude\settings.local.json`의 target을 `base\.claude\settings.local.json` → `windows\.claude\settings.local.json`으로 변경
   - repo 루트 배포는 추가하지 않음

## 배포 절차

1. `windows/.claude/settings.local.json` 파일 생성
2. `windows/install.ps1` 링크 target 수정
3. 사용자가 관리자 권한 PowerShell에서 `windows/install.ps1` 실행 (symlink 생성은 관리자 권한 필요)

## 검증

1. `Get-Content $env:USERPROFILE\.claude\settings.local.json` → windows/ 파일 내용과 동일
2. `git ls-files -s .claude/settings.local.json` → mode 120000 유지 (deck symlink 보존, git 변경 없음)

## 주의사항

- repo 루트 `.claude/settings.local.json`은 git symlink(deck 전용) 그대로 유지. 이 PC에서는 텍스트로 보이며 `/doctor` 이슈가 지속됨 — 별도 처리
- 이 PC 전용 설정이 필요해지면 `kyolim/.claude/settings.local.json`을 추가하고 install.ps1에 링크를 배치 (YAGNI — 현재는 생성하지 않음)
