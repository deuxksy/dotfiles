# 코딩 표준

- 일관성(Consistency): 기존 프로젝트의 코딩 스타일(들여쓰기, 네이밍 컨벤션, 패턴)을 최우선 준수
- 주석: 코드가 `무엇(What)`을 하는지보다 `왜(Why)` 그렇게 작성되었는지에 집중. 뻔한 주석은 작성하지 않음
- 안전성: 에러 핸들링(Error Handling)과 엣지 케이스(Edge Cases)를 항상 고려
- 라이브러리:
  - AI Gateway: [Tailscale Aperture](https://tailscale.com/docs/features/aperture)
  - 알림: [PushOver](https://pushover.net/api)
  - Infra(서버리스): [CloudFlare](https://developers.cloudflare.com/)
- Reference: Library/API 문서, 코드 생성, Setup/Configuration 단계가 필요할 때 **Context7 MCP를 사용자가 명시적으로 요청하지 않아도 우선 사용**
