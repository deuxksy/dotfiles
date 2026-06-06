# pnpm/uv Tool Declarative Management

## TL;DR

pnpm global 패키지와 uv tool을 plain text 파일로 선언형 관리. Brewfile과 동일한 패턴.

## Design

### 파일 구조

```
base/
  pnpm-global.txt     # stow → ~/pnpm-global.txt
  uv-tools.txt        # stow → ~/uv-tools.txt
```

### 파일 포맷

패키지명 한 줄씩, 버전 명시 없음 (항상 latest).

```
# pnpm-global.txt
@openai/codex
mcp-hub
oh-my-claude-sisyphus
oh-my-codex
```

```
# uv-tools.txt
holmesgpt
litellm
proxmox-mcp-plus
serena-agent
shell-gpt
```

### 설치/동기화

```bash
xargs pnpm add -g < ~/pnpm-global.txt
xargs uv tool install < ~/uv-tools.txt
```

- 이미 설치된 패키지는 스킵 (idempotent)
- 새 패키지 추가 시 파일에 한 줄 추가 후 커맨드 재실행

### 배포

기존 `stow -t ~ base`로 자동 배포. 별도 스크립트 없음.

## Decisions

- **Plain text over native format**: pnpm/uv 모두 파일 기반 일괄 설치를 네이티브로 지원하지 않아 포맷 차이 무의미
- **latest 고정**: dotfiles는 설치 "목록" 관리가 목적. 버전 고정은 mise로 관리하는 런타임에만 적용
- **base/ 배치**: 전 호스트 공통 도구이므로 base stow 패키지에 포함
