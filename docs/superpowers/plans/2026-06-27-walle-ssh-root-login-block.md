# walle SSH root login 차단 Implementation Plan (구현 완료)

> **Status**: ✅ 구현 완료 (2026-06-27)
> **Goal**: walle SSH root login 차단 — 달성

## Task 실행 결과

| Task | 결과 | 비고 |
| :--- | :--- | :--- |
| 1. 사전 확인 | ✅ | 발견: walle-sudo 미배포, `/etc/sudoers.d/crong`(수동 644), `PermitRootLogin yes`, include OK, crong uid 101000 |
| 2. repo 구조 변경 | ✅ | user 이동 + drop-in 생성 (commit `6214731`) |
| 3. 배포 | ✅ (변경) | stow `apt install` → drop-in stow 배포. sudoers user stow 불가 → crong 유지 + 0440 |
| 4. reload + 검증 | ✅ | reload OK, `ROOT LOGIN REFUSED`, lockout 없음 |
| 5. README/문서 | ✅ | design/plan 동기화 + `.stow-local-ignore` |

## plan 대비 주요 차이

1. **sudoers는 stow symlink 불가** (visudo owner root 검사) → 수동 관리 (crong 0440)
2. **stow 미설치** → `apt install stow` 단계 추가
3. **user 파일 `.stow-local-ignore` 제외**

## 최종 검증 (모두 충족)

- [x] `sshd -t` exit 0
- [x] `sshd -T -C user=root` → `permitrootlogin no`
- [x] reload OK, ssh.service active
- [x] crong 새 연결 OK (lockout 없음)
- [x] root `Permission denied` + `ROOT LOGIN REFUSED` auth.log
- [x] root 성공 로그 없음
- [x] `visudo -c` parsed OK (crong 0440)
