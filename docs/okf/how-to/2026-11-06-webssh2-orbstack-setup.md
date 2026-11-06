# WebSSH2 OrbStack 설치 (axiom SSH 게이트웨이)

WebSSH2를 axiom의 OrbStack에 띄워 태블릿 브라우저에서 axiom으로 자동로그인 SSH 접속하는 게이트웨이 구축·운영 절차. 타 호스트(eve, brla)는 axiom 셸 안에서 `ssh eve`로 접속한다. 설계 배경과 스파이크 근거는 [설계 문서](../../superpowers/specs/2026-11-06-webssh2-gateway-design.md) 참조.

## 전제 조건

- axiom에 OrbStack 설치 (Brewfile `orbstack` cask — `brew bundle`으로 설치됨)
- stow 배포 완료 (`stow --no-folding -t ~ axiom`)
- `jq`, `ssh-keygen` 사용 가능 (macOS 기본)
- 접속 키: `~/.ssh/id_ed25519` (passphrase 없음)

## 구성

```text
axiom/.config/webssh2/           # repo (stow 배포)
  docker-compose.yml             # 컨테이너 1개, 2222 → axiom 고정
  gen-hosts.sh                   # ~/.ssh 키 → config.json 생성 (시크릿 포함)
  gen-client.sh                  # client.htm에 웹폰트 주입

~/.local/share/webssh2/          # local (repo 외부 — 시크릿·파생물)
  hosts/axiom.json               # privateKey + session.secret 포함
  client.htm / client.htm.orig   # 웹폰트 주입본 / 원본 백업
```

repo에는 시크릿이 없다. 키의 SoT는 `~/.ssh`이며 생성물은 전부 XDG data 경로에 둔다.

## 설치 절차

```bash
# 1. config 생성 — 인자: <alias> <host> <user> [keypath]
~/.config/webssh2/gen-hosts.sh axiom axiom.bun-bull.ts.net crong

# 2. 웹폰트 주입 (이미지에서 client.htm 추출 → Hack Nerd Font @font-face 주입)
~/.config/webssh2/gen-client.sh

# 3. 기동
docker compose -f ~/.config/webssh2/docker-compose.yml up -d
```

OrbStack이 로그인 시 기동되고 `restart: unless-stopped`로 컨테이너가 자동 복구된다.

## 접속

```text
http://axiom:2222/ssh/host/axiom.bun-bull.ts.net   # tailnet — 브라우저 북마크 권장
```

로그인 폼 없이 바로 axiom 터미널이 열린다 (서버 자격증명 자동로그인). 첫 접속 시 host key 미등록이면 SSH 클라이언트와 동일하게 수락 절차가 필요할 수 있다. 타 호스트는 이 터미널에서 `ssh eve`, `ssh brla` (`~/.ssh/config` 별칭).

## 검증

```bash
# 1. HTTP 응답 — 200이어야 함
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:2222/ssh/host/axiom.bun-bull.ts.net

# 2. 웹폰트 주입 확인 — 1 이상 출력
curl -s http://localhost:2222/ssh/host/axiom.bun-bull.ts.net | grep -c hack-nerd-font

# 3. 컨테이너 상태 — running
docker compose -f ~/.config/webssh2/docker-compose.yml ps
```

브라우저에서 접속해 p10k 프롬프트 글리프가 정상 렌더링되는지 확인한다 (태블릿 등 로컬 폰트 없는 기기는 첫 로드에 웹폰트 다운로드로 약간 지연).

## 운영

| 작업 | 절차 |
| :--- | :--- |
| 키 로테이션 | `gen-hosts.sh` 재실행 → `docker compose restart` |
| 이미지 업데이트 | `docker compose pull` → `gen-client.sh` 재실행(클라이언트 원본 갱신) → `up -d` |
| 완전 재구축 | `gen-hosts.sh` + `gen-client.sh` → `up -d --force-recreate` (host key 스토어는 named volume `webssh2-data`에 유지) |
| 호스트 추가 (eve/brla 직접 진입) | `gen-hosts.sh <alias> <fqdn> <user>` 실행 + compose에 서비스 블록 추가(포트 2223~, 403 정책상 호스트당 컨테이너 필요) |

## 문제 해결

- **403 Forbidden**: 서버 자격증명이 설정된 컨테이너는 `ssh.host`로 고정된 호스트만 접속 허용 — URL의 호스트가 config의 host와 일치하는지 확인
- **기본 설정으로 뜸 (자동로그인 안 됨)**: config.json 마운트 경로 확인 — 이미지 WorkingDir는 `/srv/webssh2`
- **`${HOME}` 미전개**: `docker compose config`로 볼륨 경로가 절대경로인지 확인
- **authorized_keys 미등록**: `ssh -o BatchMode=yes -i ~/.ssh/id_ed25519 crong@axiom.bun-bull.ts.net hostname`으로 사전 검증, 실패 시 공개키 등록
- **이미지 업데이트 후 폰트 깨짐**: `gen-client.sh` 재실행 (클라이언트 HTML이 원본으로 교체됨)
