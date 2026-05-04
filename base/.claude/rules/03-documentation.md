# Markdown and Mermaid

- [Markdown Spec](https://github.github.com/gfm/)을 참조해서 문서를 작성한다.
  - Table 생성시 항상 좌측 정렬하고 ` :--- ` 3개만 사용한다.
  - `Fenced Code Block` 의 Info String 에 특별히 정의 하지 않는 경우 `text` 로 사용 한다.
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
