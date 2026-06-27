# walle SSH root login 차단 — Design (구현 완료)

> **Date**: 2026-06-27
> **Status**: ✅ 구현 완료 (SSH root 차단 달성)
> **Host**: walle (Proxmox VE 8.x / Debian 12, AOOSTAR WTR R1)

## 결과

SSH 직접 root login 차단 완료. auth.log `ROOT LOGIN REFUSED` 로그로 검증.

## 실제 적용 방식 (실행 결과)

| 영역 | 방식 | 비고 |
| :--- | :--- | :--- |
| drop-in (SSH 차단) | `sudo stow -t / walle-sudo` (symlink) | `walle-sudo/etc/ssh/sshd_config.d/10-root-login.conf` (`PermitRootLogin no`). sshd는 symlink+owner 관대 → 작동 |
| sudoers | 수동 (기존 `/etc/sudoers.d/crong`) | stow symlink **불가** (visudo owner root 검사, repo 파일 crong 소유). `chmod 440` bad perms 해결 |
| user 파일 (repo) | stow 제외 | `walle-sudo/.stow-local-ignore` — 다음 `stow -R` 시 user 재생성 방지 |

## design 대비 변경 (옵션 2 → 실제)

원안 옵션 2 (commit 05c3dcc): walle-sudo 재편(user 이동 + drop-in). 실행 중 발견:

1. **walle-sudo 미배포** (repo에만 존재) → "첫 배포"
2. **sudoers는 stow symlink 불가** (visudo owner root 검사) → user 배포 제외, 기존 crong 유지
3. **stow 미설치** → `apt install stow` 선행
4. **crong bad perms (644)** → `chmod 440` 해결

결과: drop-in만 stow, sudoers는 수동 관리.

## 검증 결과 (2026-06-27)

- `sudo sshd -t` OK
- `sudo sshd -T -C user=root` → `permitrootlogin no`
- `systemctl reload ssh.service` OK, active
- crong 새 연결 OK (lockout 없음, uid 101000)
- root `Permission denied` + auth.log `ROOT LOGIN REFUSED` ✅
- root 성공 로그 없음 (차단 확정)
- `visudo -c` parsed OK (crong 0440)

## 비고

- crong uid 101000 (Proxmox uid 매핑)
- 백업: `/root/crong.sudoers.bak.*` 3개
- `PasswordAuthentication yes` (password 프롬프트 원인, root는 거부됨) — 별개 보안 이슈, 범위 외
