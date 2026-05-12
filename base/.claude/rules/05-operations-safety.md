# 운영 및 안전

- 파일 경로: 절대 경로보다는 프로젝트 루트 기준의 상대 경로를 사용한다.
- 파괴적 명령어: 사용자에게 확인 받은 후에만 실행. 대상 예시:
  - 파일/디렉토리 삭제: `rm`, `del`, `rmdir`, `rd`, `rm -rf`
  - 되돌릴 수 없는 git 작업: `git reset --hard`, `git clean -fd`, `git push --force`, `git rebase`, `git checkout --` (변경사항 폐기)
  - 시스템/디스크: `format`, `mkfs`, `dd`, `diskpart`
  - 프로세스/서비스: `kill -9`, `taskkill /F`, `shutdown`, `reboot`
  - 데이터베이스: `DROP`, `TRUNCATE`, `DELETE` (WHERE 없음)
  - 권한 변경: `chmod 777`, `chown`, `icacls`
- Proxmox API: Read(GET)은 자유롭게 실행. Create(POST), Update(PUT), Delete(DELETE)는 사용자 승인 후 실행.
- K8S(kubectl): get, describe, logs 등 읽기 전용은 자유롭게 실행. create, delete, edit, patch, apply, drain, cordon, uncordon 등 변경 작업은 사용자 승인 후 실행.
- Notion: search, fetch, get 등 읽기 전용은 자유롭게 실행. 페이지 생성/수정/삭제, 댓글 작성 등 쓰기 작업은 사용자의 명시적 요청 또는 승인이 있을 때만 실행
