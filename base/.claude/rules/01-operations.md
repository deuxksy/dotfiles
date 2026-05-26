# Operations

## Operations and Safety

- 파일 경로: 절대 경로보다는 프로젝트 루트 기준의 상대 경로를 사용한다.
- 파괴적 명령어: 사용자에게 확인 받은 후에만 실행. 대상 예시:
  - 파일/디렉토리 삭제: `rm`, `del`, `rmdir`, `rd`, `rm -rf`
  - 되돌릴 수 없는 git 작업: `git reset --hard`, `git clean -fd`, `git push --force`, `git rebase`, `git checkout --` (변경사항 폐기)
  - 시스템/디스크: `format`, `mkfs`, `dd`, `diskpart`
  - 프로세스/서비스: `kill -9`, `taskkill /F`, `shutdown`, `reboot`
  - 데이터베이스: `DROP`, `TRUNCATE`, `DELETE` (WHERE 없음)
- PostgreSQL(DBHub):
  - **읽기 (자유)**: SELECT, EXPLAIN, SHOW, health check 쿼리 (DBHub Custom Tools 15개)
  - **변경 (승인 필수)**: INSERT, UPDATE, CREATE INDEX, ALTER, VACUUM — 실행 전 SQL과 영향 범위 보고 후 승인
  - **삭제 (금지)**: DROP, TRUNCATE, DELETE (WHERE 없음) — 절대 실행하지 않음
  - **구조 변경 (금지)**: DROP TABLE, DROP INDEX, DROP DATABASE — 절대 실행하지 않음
  - 연결 정보: sops로 관리 (평문 금지)
  - 권한 변경: `chmod 777`, `chown`, `icacls`
- Proxmox API: Read(GET)은 자유롭게 실행. Create(POST), Update(PUT), Delete(DELETE)는 사용자 승인 후 실행.
- K8S(kubectl):
  - **읽기 (자유)**: get, describe, logs, top, explain, api-resources, api-versions
  - **변경 (승인 필수)**: apply, create, edit, patch, scale, rollout, label, annotate, set — 실행 전 구체적 명령어와 대상을 보고하고 승인 받기
  - **삭제 (금지)**: delete, deletecollection — 절대 실행하지 않음. 필요시 사용자가 직접 실행
  - **위험 (금지)**: drain, cordon, uncordon, taint, 파드 내 수정 — 절대 실행하지 않음
  - Telepresence: connect, list, status, intercept, leave, quit은 자유. helm install은 승인 필요
- Notion: search, fetch, get 등 읽기 전용은 자유롭게 실행. 페이지 생성/수정/삭제, 댓글 작성 등 쓰기 작업은 사용자의 명시적 요청 또는 승인이 있을 때만 실행
- SRE 도구:
  - `k8sgpt`: K8s 리소스 분석 — MCP 서버 모드(`k8sgpt serve --mcp`)로 `~/.claude/settings.json`에 등록
  - `holmes`: 인프라/로그 종합 조사 — MCP 미지원, Bash로 호출
    - 환경변수: `OPENAI_API_KEY` + `OPENAI_API_BASE=http://ai/v1`
    - 모델: `--model openai/<model>` (litellm provider prefix 필수)
    - `~/.holmes/config.yaml` pydantic 검증 엄격 → 환경변수 권장
