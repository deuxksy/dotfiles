# Work-Log 관리

- **중앙 repo**: `C:\Users\deuxk\git\KyoLim-Labs\work-log` (독립 git repo)
- **구조**: `YY주차/MMDD.md` (같은 날 다른 작업은 `MMDD-{task}.md`)
- **Symlink**: 각 프로젝트 `docs/work-log/` → 중앙 repo (`.gitignore`에 `docs/work-log/` 추가)
- **기록 시점**: 작업 완료 후 일일 세션 로그 작성
- **Notion 업데이트**: 개인 작업 기록(주차 페이지)에 일일 요약 반영
- **팀 보고**: 사용자 요청 시(보통 금요일) 해당 주차 작업을 팀 주간 업무 보고에 작성
- **상세 URL**: Claude Memory `reference_notion_work-log.md` 참조

## Notion 갱신 원칙

- **추가 원칙(Additive Update)**: 주차별 링크 등 기존 목록을 갱신할 때는 **추가(Append)만** 한다. 전체 덮어쓰기(Overwrite) 금지
- **작업 순서**:
  1. Notion에서 현재 하위 페이지 목록을 fetch
  2. README.md의 기존 항목과 비교하여 누락된 항목만 식별
  3. 누락된 항목만 `Edit`으로 추가
