# Windows 공통 + kyolim host 관리 설계

> **Date**: 2026-07-23
> **Status**: 설계 승인, 구현 전
> **Host**: kyolim (Windows 11 / Asus Zenbook 14 UX3405C)

## 목표

Windows 11 노트북 `kyolim`을 다음 두 방식으로 재현 가능하게 관리한다.

- 설정 파일은 repository 원본을 Windows 실제 경로에 symlink 또는 Junction으로 연결한다.
- 애플리케이션과 PowerShell module은 선언된 manifest를 기준으로 설치한다.

GNU Stow의 디렉토리 투영 방식을 Windows에 그대로 적용하지 않는다. PowerShell, Windows Terminal, Git, SSH 등 각 도구의 Windows known path를 명시적으로 mapping한다.

## 소유권

| 디렉토리 | 책임 |
| :--- | :--- |
| `base/` | OS 간 공유 가능한 설정 원본 |
| `windows/` | `base/` 설정의 Windows 경로 mapping, 공통 package, 공통 installer |
| `kyolim/` | kyolim 전용 설정 원본, host 경로 mapping, host package |

핵심 규칙은 다음과 같다.

- `windows/`는 **Windows에서 공통으로 어떻게 설치하고 연결할지** 관리한다.
- `kyolim/`은 **kyolim에만 무엇을 설치하고 연결할지** 관리한다.
- 공통 설정을 `kyolim/`에 복제하지 않는다.
- host 전용 설정을 `windows/`에 넣지 않는다.

## 제안 구조

```text
windows/
├── install.ps1
├── links.psd1
├── packages.json
├── powershell-modules.psd1
└── README.md

kyolim/
├── links.psd1
├── packages.json
├── powershell-modules.psd1
├── Documents/
│   └── PowerShell/
│       └── Microsoft.PowerShell_profile.ps1
├── .gitconfig.local
└── .ssh/
    └── config
```

필요한 파일만 추가한다. 빈 manifest나 미래 사용을 위한 directory는 만들지 않는다.

## 설치 흐름

```powershell
.\windows\install.ps1 -HostName kyolim
```

`install.ps1`은 다음 순서로 동작한다.

1. 실행 위치와 `kyolim/` 존재 여부를 검증한다.
2. `windows/links.psd1`을 읽어 `base/` 원본을 Windows 공통 경로에 연결한다.
3. `kyolim/links.psd1`을 읽어 host 전용 원본을 Windows 경로에 연결한다.
4. 공통 package manifest를 적용한다.
5. kyolim package manifest를 적용한다.
6. 공통 및 host PowerShell module manifest를 적용한다.
7. 생성, 유지, 충돌, 실패 결과를 요약한다.

## Link 정책

- 파일은 `SymbolicLink`를 기본값으로 사용한다.
- 정적 설정 directory는 필요할 때만 `Junction`을 사용한다.
- runtime data와 설정이 섞인 directory 전체를 Junction으로 연결하지 않는다.
- 기존 경로가 올바른 link이면 유지한다.
- 기존 경로가 일반 파일, 일반 directory 또는 다른 target의 link이면 덮어쓰지 않고 실패한다.
- `-Force`로 사용자 파일을 교체하거나 삭제하지 않는다.
- 관리자 권한을 기본 요구사항으로 만들지 않는다. file symlink가 필요한 경우 Windows Developer Mode를 전제로 한다.

대표 mapping은 환경변수와 known path를 사용한다.

| 설정 | 대상 경로 기준 |
| :--- | :--- |
| PowerShell 7 profile | `$PROFILE.CurrentUserAllHosts` 또는 `$PROFILE.CurrentUserCurrentHost` |
| Git | `$env:USERPROFILE\.gitconfig`, host 설정은 include 사용 |
| OpenSSH | `$env:USERPROFILE\.ssh\config` |
| Neovim | `$env:LOCALAPPDATA\nvim` |
| Windows Terminal | package별 LocalState 경로를 탐지한 뒤 명시적으로 선택 |

## Package 정책

- Windows application은 `winget` manifest로 관리한다.
- 모든 Windows host에 필요한 package만 `windows/packages.json`에 둔다.
- 회사 노트북에만 필요한 package는 `kyolim/packages.json`에 둔다.
- 설치 여부를 먼저 검사하여 반복 실행을 허용한다.
- package 제거와 upgrade 강제 실행은 범위에서 제외한다.
- 회사 정책으로 설치할 수 없는 package는 실패 원인을 보고하고 나머지 항목을 계속 처리한다.

PowerShell module도 동일하게 공통과 host manifest를 분리한다. module version pinning은 실제 재현성 요구가 확인된 항목에만 적용한다.

## Secret 정책

- API key, token, credential, private key를 link manifest나 package manifest에 넣지 않는다.
- secret 원본은 기존 `sops` + `age` 정책을 따른다.
- Windows Credential Manager, Git Credential Manager 등 runtime credential 저장소는 repository 관리 대상에서 제외한다.
- `.ssh/config`는 관리할 수 있지만 private key는 관리하지 않는다.

## 검증 기준

구현 완료 조건은 다음과 같다.

1. PowerShell 7에서 installer를 일반 사용자 권한으로 실행할 수 있다.
2. `windows/` 공통 link와 `kyolim/` host link가 올바른 target을 가리킨다.
3. installer를 두 번 실행해도 기존의 올바른 link가 유지된다.
4. 충돌 파일을 준비한 dry-run 또는 test에서 기존 파일이 변경되지 않는다.
5. 공통 및 host package manifest가 구문 검사를 통과한다.
6. README의 Windows 설치 절차와 repository 구조 설명이 실제 구현과 일치한다.

## 범위 제외

- Registry, Windows services, Group Policy, Windows feature 변경
- 회사 보안 정책 우회
- package 자동 제거 또는 강제 upgrade
- WSL 내부 dotfiles 관리
- `ava` host 구조 변경
- secret 평문 저장

## 결정

`windows/` 단독 관리나 `kyolim/` 단독 관리 대신 공통 installer와 host 선언을 분리한다. 이 구조는 현재 `base + host` repository 모델을 Windows known path 방식으로 확장하며, 공통 로직 중복과 host 설정 혼합을 동시에 피한다.
