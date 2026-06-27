# walle SSH root login 차단 — Design

> **Date**: 2026-06-27 (Codex 검증 반영 update)
> **Host**: walle (Proxmox VE 8.x / Debian 12 Bookworm, AOOSTAR WTR R1)
> **Status**: Approved (Approach 1, 패키지 분리 구조)

## 배경

walle를 Fedora → Proxmox(Debian) 마이그레이션 완료. Homelab 서버 보안 강화를 위해 SSH 직접 root login 차단. crong 사용자 key 접속 + sudo 로 운영.

## 범위

- SSH `PermitRootLogin no` 적용 (drop-in conf)
- Proxmox web UI(`root@pam`, PAM 인증)는 영향 없음 — SSH만 해당
- `PasswordAuthentication` 변경 없음 (요청 범위 외, YAGNI)

## Codex 검증 반영

- **Blocker 해결**: `walle-sudo` 평면 구조(`user`)에 sshd drop-in 계층 추가 시 배포 충돌 → `walle-etc` 신규 패키지 분리로 해결
- **Risk 반영**: Debian unit명, effective config 검증, include 사전 확인, 차단 원인 증명 (아래 적용 순서에 반영)

## Approach

**선택: `walle-etc` 신규 패키지 + Drop-in conf + stow 배포**

Proxmox(Debian) 표준 `Include /etc/ssh/sshd_config.d/*.conf` 방식. 메인 `sshd_config` 무결, repo 버전 관리, `walle-sudo`(sudoers)와 관심사 분리.

### 신규 패키지/파일

`walle-etc/etc/ssh/sshd_config.d/10-root-login.conf`

```text
# SSH root direct login 차단 — walle(Proxmox) 보안 강화
# crong 사용자 key 접속 + sudo 로 운영
PermitRootLogin no
```

### 배포

```bash
sudo stow -t / walle-etc
# → /etc/ssh/sshd_config.d/10-root-login.conf (symlink)
```

## 적용 순서 (lockout 방지 + Codex Risk 반영)

1. **사전 확인**:
   - crong SSH key 접속 보장 (✅ 사전 확인 완료)
   - include 존재 확인: `grep -nE '^\s*Include\s+/etc/ssh/sshd_config.d' /etc/ssh/sshd_config`
   - unit명 확인: `systemctl cat ssh.service` (Debian은 `ssh.service`, `sshd.service` 아님)
   - drop-in 충돌 확인: `grep -rnE 'PermitRootLogin|Match' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/ 2>/dev/null`
2. **배포**: `sudo stow -t / walle-etc` (현재 세션 유지)
3. **syntax 검증**: `sudo sshd -t` (exit 0 선행 필수)
4. **effective config 검증**: `sudo sshd -T -C user=root,host=walle,lport=22 | grep '^permitrootlogin no$'`
   - (`-t`는 syntax만, `-T -C`는 Match 적용까지 포함한 effective 값)
5. **reload**: `sudo systemctl reload ssh.service` (reload 로 현재 SSH 세션 유지)
6. **이중 확인** (새 터미널):
   - `ssh crong@walle 'id && sudo -n true'` 성공
   - `ssh root@walle` 실패 + `/var/log/auth.log` 에서 root 거부 원인 확인

## 검증 기준 (Goal-Driven)

- [ ] `/etc/ssh/sshd_config` 에 `Include /etc/ssh/sshd_config.d` 존재
- [ ] `systemctl cat ssh.service` 정상 (unit명 확정)
- [ ] `sudo sshd -t` exit code 0
- [ ] `sudo sshd -T -C user=root,...` 출력 `permitrootlogin no`
- [ ] `ssh crong@walle` 성공 (새 연결)
- [ ] `ssh root@walle` Permission denied + `auth.log` root 거부 로그 존재
- [ ] Proxmox web UI `root@pam` 로그인 정상

## 리스크 / 비고

- **Lockout**: crong key 접속 보장됨. reload 로 현재 세션 유지. 새 터미널로 사전 검증 후에만 기존 세션 종료 권장.
- **walle-sudo 무결**: 본 작업은 `walle-etc` 신규 패키지에 한정. 기존 sudoers 배포 영향 없음.
- **README 문서화**: `walle-etc` 배포 명령(`sudo stow -t / walle-etc`)을 README에 추가 필요.
- **Fedora 잔재**: `install_nvtools.sh`가 dnf 기반 — 별개 이슈, 본 spec 범위 외.
