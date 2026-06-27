# walle SSH root login 차단 — Design

> **Date**: 2026-06-27
> **Host**: walle (Proxmox VE / Debian, AOOSTAR WTR R1)
> **Status**: Approved (Approach 1)

## 배경

walle를 Fedora → Proxmox(Debian) 마이그레이션 완료. Homelab 서버 보안 강화를 위해 SSH 직접 root login 차단. crong 사용자 key 접속 + sudo 로 운영.

## 범위

- SSH `PermitRootLogin no` 적용 (drop-in conf)
- Proxmox web UI(PAM root 인증)는 영향 없음 — SSH만 해당
- `PasswordAuthentication` 변경 없음 (요청 범위 외, YAGNI)

## Approach

**선택: Drop-in conf로 repo 관리**

Proxmox(Debian) 표준 `Include /etc/ssh/sshd_config.d/*.conf` 방식. 메인 `sshd_config` 무결, repo 버전 관리, 기존 `walle-sudo` 패키지 패턴과 일관.

### 신규 파일

`walle-sudo/etc/ssh/sshd_config.d/10-root-login.conf`

```text
# SSH root direct login 차단 — walle(Proxmox) 보안 강화
# crong 사용자 key 접속 + sudo 로 운영
PermitRootLogin no
```

### 배포 경로

`/etc/ssh/sshd_config.d/10-root-login.conf` (기존 `walle-sudo` 배포 메커니즘)

## 적용 순서 (lockout 방지 중심)

1. 사전 확인: crong SSH key 접속 보장 (✅ 사전 확인 완료)
2. 파일 배포 (root 권한)
3. `sudo sshd -t` — config 유효성 검증 (반드시 선행)
4. `sudo systemctl reload sshd` — reload 로 현재 세션 유지 (restart 아님)
5. 새 터미널에서 crong 접속 성공 + root 차단 이중 확인

## 검증 기준 (Goal-Driven)

- [ ] `sudo sshd -t` exit code 0
- [ ] `ssh crong@walle` 성공 (기존 세션과 별개 새 연결)
- [ ] `ssh root@walle` Permission denied (차단) 실패
- [ ] Proxmox web UI root login 정상 동작

## 리스크 / 비고

- **Lockout**: crong key 접속 보장됨 (사전 확인 완료). reload 로 현재 세션 유지.
- **walle-sudo 구조**: 기존 평면 구조(`user`)와 달리 `etc/...` 계층 추가 → 기존 배포 방식(sudo stow 또는 스크립트)과 호환성 확인 필요 (implementation 단계에서 확정).
- **Fedora 잔재**: `install_nvtools.sh`가 dnf 기반 — 별개 이슈, 본 spec 범위 외.
