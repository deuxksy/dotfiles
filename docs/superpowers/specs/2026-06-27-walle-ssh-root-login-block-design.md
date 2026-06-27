# walle SSH root login 차단 — Design

> **Date**: 2026-06-27 (옵션 2 walle-sudo 통합 구조로 확정)
> **Host**: walle (Proxmox VE 8.x / Debian 12 Bookworm, AOOSTAR WTR R1)
> **Status**: Approved (옵션 2 — `walle-sudo` 통합)

## 배경

walle를 Fedora → Proxmox(Debian) 마이그레이션 완료. Homelab 서버 보안 강화를 위해 SSH 직접 root login 차단. crong 사용자 key 접속 + sudo 로 운영.

## 범위

- SSH `PermitRootLogin no` 적용 (drop-in conf)
- Proxmox web UI(`root@pam`, PAM 인증)는 영향 없음 — SSH만 해당
- `PasswordAuthentication` 변경 없음 (요청 범위 외, YAGNI)

## Approach

**선택: 기존 `walle-sudo` 패키지에 sshd drop-in 통합 (옵션 2)**

새 패키지 생성 없이, 이미 root 영역(`/etc/sudoers.d`)을 담당하는 `walle-sudo`에 sshd drop-in을 추가. target을 `/`로 통일하여 `/etc` 하위 전체를 패키지 하나로 관리.

### 구조 변경

```text
기존:
  walle-sudo/user

변경 후:
  walle-sudo/etc/sudoers.d/user                           (기존 user 이동)
  walle-sudo/etc/ssh/sshd_config.d/10-root-login.conf     (신규)
```

신규 파일 내용:

```text
# SSH root direct login 차단 — walle(Proxmox) 보안 강화
# crong 사용자 key 접속 + sudo 로 운영
PermitRootLogin no
```

### 배포

```bash
sudo stow -t / walle-sudo
# → /etc/sudoers.d/user + /etc/ssh/sshd_config.d/10-root-login.conf
```

## 왜 `walle` 패키지가 아닌가

`walle` 패키지는 target `~` (홈). `/etc/` 설정은 stow 구조상 홈에 배포되어 sshd가 읽지 않음 (`~/etc/ssh/...`). target `/` 로 전환은 패키지 전체 재편(`walle/home/crong/...`)이 필요한 대공사. 따라서 이미 root 영역을 담당하는 `walle-sudo`를 활용.

## Codex 검증 반영

- **Blocker 해결**: `walle-sudo`를 `/` target 계층 구조로 통일 → 배포 충돌 제거
- **Risk 반영**: Debian unit명, effective config 검증, include 사전 확인, 차단 원인 증명 (아래 적용 순서에 반영)

## 적용 순서 (lockout 방지 + Codex Risk 반영)

1. **사전 확인 — sudoers**:
   - 현재 `user` 파일이 실제 `/etc/sudoers.d/user` 에 존재하는지 확인 (현재 배포 target 확정)
   - `sudo visudo -c` 로 기존 sudoers 유효성 확인
2. **사전 확인 — sshd**:
   - crong SSH key 접속 보장 (✅ 완료)
   - include 존재: `grep -nE '^\s*Include\s+/etc/ssh/sshd_config.d' /etc/ssh/sshd_config`
   - unit명: `systemctl cat ssh.service` (Debian은 `ssh.service`, `sshd.service` 아님)
   - drop-in 충돌: `grep -rnE 'PermitRootLogin|Match' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/`
3. **구조 변경 (repo)**: `walle-sudo/user` → `walle-sudo/etc/sudoers.d/user` 이동 + drop-in 파일 추가
4. **배포 (walle)**: `sudo stow -t / walle-sudo` (target `/` 로 통일)
5. **sudoers 재검증**: `sudo visudo -c` (이동 후 `/etc/sudoers.d/user` 유효성)
6. **sshd syntax**: `sudo sshd -t` (exit 0 선행 필수)
7. **sshd effective config**: `sudo sshd -T -C user=root,host=walle,lport=22 | grep '^permitrootlogin no$'`
8. **reload**: `sudo systemctl reload ssh.service` (reload 로 현재 SSH 세션 유지)
9. **이중 확인 (새 터미널)**:
   - `ssh crong@walle 'id && sudo -n true'` 성공
   - `ssh root@walle` 실패 + `/var/log/auth.log` root 거부 원인 확인

## 검증 기준 (Goal-Driven)

- [ ] `/etc/sudoers.d/user` 유지 (이동 후 정상, `visudo -c` 통과)
- [ ] `/etc/ssh/sshd_config` 에 `Include /etc/ssh/sshd_config.d` 존재
- [ ] `systemctl cat ssh.service` 정상 (unit명 확정)
- [ ] `sudo sshd -t` exit code 0
- [ ] `sudo sshd -T -C user=root,...` 출력 `permitrootlogin no`
- [ ] `ssh crong@walle` 성공 (새 연결)
- [ ] `ssh root@walle` Permission denied + `auth.log` root 거부 로그 존재
- [ ] Proxmox web UI `root@pam` 로그인 정상

## 리스크 / 비고

- **Lockout**: crong key 접속 보장됨. reload 로 현재 세션 유지. 새 터미널로 사전 검증 후에만 기존 세션 종료 권장.
- **배포 방식 변경**: 기존 `walle-sudo` target(`/etc/sudoers.d` 추정) → `/` 로 통일. README에 배포 명령 업데이트 필요.
- **sudoers 이동**: `user` 파일을 `etc/sudoers.d/user` 로 이동 — `visudo -c` 로 반드시 재검증.
- **Fedora 잔재**: `install_nvtools.sh`가 dnf 기반 — 별개 이슈, 본 spec 범위 외.
