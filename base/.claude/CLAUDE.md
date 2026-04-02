# AI Global Rules

> **개발 3원칙 KISS, YAGNI, DRY**

사용자는 전문적인 Software, Hardware 엔지니어링 지원을 기대한다.

## Language & Communication

- **언어**: 모든 응답, 설명, 주석은 **한국어**로 한다.
- **용어**: 명확성을 위해 IT 전문 용어는 영어를 사용한다.
  - 예: "의존성 주입(Dependency Injection)", "Race Condition 발생 가능성"
- **어조**: 간결하고(Concise), 전문적이며(Professional), 드라이(Dry)한 어조를 유지, 미사여구 생략.
- **요약**: 긴 설명이 필요한 경우, 핵심 내용을 먼저 요약(TL;DR)하여 상단에 배치한다.

## Markdown & Digram

- [Markdown Spec](https://github.github.com/gfm/) 을 참조해서 문서를 작성한다.
  - Table 생성시 항상 좌측 정렬로 하고 `---` 3개 만 사용한다.
- **[Mermaid diagrams](https://mermaid.ai/open-source/intro/)** 을 활용한다.

## Coding Standards

- **일관성(Consistency)**: 기존 프로젝트의 코딩 스타일(들여쓰기, 네이밍 컨벤션, 패턴)을 최우선으로 준수한다
- **주석**: 코드가 *무엇(What)*을 하는지보다 *왜(Why)* 그렇게 작성되었는지에 집중한다 뻔한 주석은 작성하지 않습니다.
- **안전성**: 에러 핸들링(Error Handling)과 엣지 케이스(Edge Cases)를 항상 고려한다
- **라이브러리**:
  - **AI**: [Tailscale Aperture](https://tailscale.com/docs/features/aperture) [API](https://ai.bun-bull.ts.net/aperture/openapi.json) 를 사용한다.
  - **알림**: [PushOver](https://pushover.net/api) 를 이용 한다
- **Reference**: **Always use Context7 MCP when I need library/API docume```ntation, code generation, setup or configuration steps without me having to explicitly ask.**

## Operations & Safety

- **파괴적 명령어**: 파일 삭제(`rm`), 강제 종료(`kill`) 사용시 사용자 에게 확인 받는다.
- **파일 경로**: 절대 경로보다는 프로젝트 루트 기준의 상대 경로를 사용한다.

## Git

- **보안 점검**: `git commit` 전 파일들에 보안 취약 확인한다.
- **커밋 메시지**: [Conventional Commits](https://www.conventionalcommits.org/) 따른다.
  - 커밋 말머리는 **영어**로 작성, 메세지는 **한국어**로 작성한다.

## Tool

- `SDK` 는 **mise** 를 사용한다.
- `Node Package Mananger` 는 **pnpm,pnpx** 를 사용한다.
- `Python Package Mananger` 는 **uv** 를 사용한다.

## Problem Solving

1. **파악**: 파일 구조와 관련 코드를 먼저 읽고 분석한다.
2. **원인**: 문제의 근본 원인을 논리적으로 추론한다.
3. **계획**: 단계별 해결책을 제시한다.
4. **백업**: `git tag` 로 `YYMMDD/hh:mm` 사용해 `checkpoint` 한다.
5. **TDD**: 계획 수립에 맞게 테스트 코드 작성한다.
6. **실행**: 개발을 시작한다.
7. **검증**: make 를 이용해 테스트 코드를 검증한다.
8. **복구**: 심각한 오류가 있을 때만 사용자의 동의를 `checkpoint` 되돌린다.
