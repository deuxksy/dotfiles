# Documentation

## Markdown

- [Markdown Spec](https://github.github.com/gfm/)을 참조해서 문서를 작성한다.
  - Table 생성시 항상 좌측 정렬하고 ` :--- ` 3개만 사용 한다.
  - `Fenced Code Block` 의 Info String 에 특별히 정의 하지 않는 경우 `text` 로 사용 한다.
  - **목차(TOC)**: 제목(`#`)과 첫 섹션(`##`) 사이에 배치. 문서 길이에 따라 방식 선택:
    - ~150줄: 제목 밑 리스트 (`- [섹션명](#섹션명)`)
    - 150줄+: `## 목차` 섹션으로 분리

## Mermaid

- [Mermaid](https://mermaid.ai/open-source/intro/)을 적극 활용한다.
  - 설명이 길어질 경우 Mermaid 다이어그램(graph, sequence, class, state, ER 등)을 우선 작성한다.
  - 텍스트 나열보다 시각적 표현으로 이해도를 높인다.
  - **다이어그램 키워드**: `graph` 만 사용 (`flowchart` 금지 — GitLab 렌더러 미지원)
  - **방향**: 병렬 분기가 없는 단순 선형 흐름은 `graph LR`(좌→우). 병렬/분기가 있는 복합 흐름은 `graph TD`(상→하)
  - **노드 라벨 금지 문법** (렌더러 HTML 인코딩으로 파싱 에러 발생):
    - `①②③` 원문자 기호 금지 → `1. 2. 3.` 일반 숫자+마침표로 대체
    - `["텍스트"]` 따옴표 사용 금지 → `[텍스트]` 로 작성
    - `<br/>` HTML 태그 사용 금지 → `-` (대시) 로 줄바꿈 대체
    - `()`, `→` 등 특수기호 피하기 → 한글/영문+대시 조합으로 대체
  - **안전한 노드 라벨 예시**: `A[1. 앱 실행]`, `B[2. 권한동의 - 위치/카메라]`

## Notion

- 문서 상단에 Notion URL 링크가 포함된 경우, 해당 파일은 Notion과 동기화해야 하는 파일로 인식
- 형식: `> **Source**: [문서제목](https://www.notion.so/...)`
- 동기화 시 로컬 마크다운을 Notion 최신 내용으로 갱신

## README.md

- 프로젝트의 문서관리는 Notion을 중심으로 한다. `README.md`는 **Notion 문서 인덱스** 역할
- 상세 내용을 직접 작성하지 않고, Notion 문서 링크를 제공하여 "무엇이 어디에 있는지"만 안내
- 프로젝트 구조, 기술 스택 등은 필요 최소한만 유지
- **최신 정보는 항상 Notion에 있어야 한다**. 로컬 문서는 참조용 캐시
- **문서 간 중복 금지**. 동일한 내용이 여러 파일에 있으면 안 된다. 한 곳을 Source of Truth로 정하고 나머지는 링크로 참조

## Work-Log

- **중앙 repo**: `~/git/work-log` (독립 git repo)
- **구조**: `YY주차/MMDD.md` (같은 날 다른 작업은 `MMDD-{task}.md`)
- **기록 시점**: 작업 완료 후 일일 세션 로그 작성
- **Notion 업데이트**: 개인 작업 기록(주차 페이지)에 일일 요약 반영
- **팀 보고**: 사용자 요청 시(보통 금요일) 해당 주차 작업을 팀 주간 업무 보고에 작성
- **상세 URL**: Claude Memory `reference_notion_work-log.md` 참조
