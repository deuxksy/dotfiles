# 프로젝트 선택적 MCP·plugin 추가

전역(`~/.apm/apm.yml`)에는 항상 쓰는 의존성만 둔다. 프로젝트 성격의 MCP·plugin은 각 repo root `apm.yml`에 아래 snippet을 붙여넣어 선택한다.

## 사전 준비

- apm CLI 설치 (전역 세팅은 [apm Agent Layer Design](../explanation/2026-09-27-apm-agent-layer-design.md) 참조)
- 프로젝트 root에 `apm.yml`이 없으면 `apm init`으로 생성

## 카탈로그

| 항목 | 종류 | 용도 |
| :--- | :--- | :--- |
| dbhub | MCP | PostgreSQL 접속 (읽기/쓰기/삭제 권한 구분은 `~/.claude/rules/01-operations.md`) |
| kubernetes-mcp-server | MCP | K8s 리소스 조회·조작 |
| proxmox-mcp-plus | MCP | Proxmox VE API |
| doris-mcp-server | MCP | Apache Doris 쿼리 |
| terraform-mcp-server | MCP | Terraform/IaC |
| cloudflare-api | MCP | Cloudflare API |
| chrome-devtools-mcp | MCP | Chrome 성능·네트워크 디버깅 (자동화는 전역 playwright-mcp 사용) |
| firecrawl/anydoc | plugin | 문서→markdown 변환 skill |

## MCP snippets

`dependencies.mcp`에 추가:

```yaml
- name: dbhub
  registry: false
  transport: stdio
  command: npx
  args:
    - -y
    - '@bytebase/dbhub'
    - --config
    - /Users/crong/.config/dbhub/dbhub.toml
- name: kubernetes-mcp-server
  registry: false
  transport: stdio
  command: npx
  args:
    - -y
    - kubernetes-mcp-server
- name: proxmox-mcp-plus
  registry: false
  transport: stdio
  command: uvx
  args:
    - proxmox-mcp-plus
  env:
    PROXMOX_HOST: ${PROXMOX_HOST}
    PROXMOX_USER: ${PROXMOX_USER}
    PROXMOX_TOKEN_NAME: ${PROXMOX_TOKEN_NAME}
    PROXMOX_TOKEN_VALUE: ${PROXMOX_TOKEN_VALUE}
    PROXMOX_PORT: '8006'
    PROXMOX_VERIFY_SSL: 'true'
- name: doris-mcp-server
  registry: false
  transport: stdio
  command: sh
  args:
    - -c
    - cd "$HOME/.config/doris-mcp" && exec uvx doris-mcp-server --transport stdio
- name: terraform-mcp-server
  registry: false
  transport: stdio
  command: terraform-mcp-server
- name: cloudflare-api
  registry: false
  transport: http
  url: https://mcp.cloudflare.com/mcp
- name: chrome-devtools-mcp
  registry: false
  transport: stdio
  command: npx
  args:
    - -y
    - chrome-devtools-mcp@latest
```

proxmox 환경변수는 `eval "$(sops -d ~/.key)"`로 주입한다.

## plugin snippet

`dependencies.apm`에 추가:

```yaml
- git: firecrawl/anydoc
```

## 적용

```bash
apm install    # 프로젝트 root에서
```

설치 후 agent 세션을 재시작하면 MCP가 붙는다.
