# WebSSH2 Gateway Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** axiom OrbStack에 WebSSH2 컨테이너 1개를 띄워 태블릿 브라우저에서 axiom으로 자동로그인 SSH 게이트웨이 구축.

**Architecture:** 동일 이미지(`ghcr.io/billchurch/webssh2:latest`) 컨테이너 1개가 config.json 마운트로 `ssh.host=axiom.bun-bull.ts.net`에 잠김. 키는 repo 밖 `~/.local/share/webssh2/hosts/`에 gen-hosts.sh가 `~/.ssh`에서 생성. repo에는 compose와 스크립트만 stow 배포.

**Tech Stack:** OrbStack(Docker Compose), bash, jq, stow, Playwright(검증)

**Spec:** [docs/superpowers/specs/2026-11-06-webssh2-gateway-design.md](../specs/2026-11-06-webssh2-gateway-design.md)

## Global Constraints

- 이미지: `ghcr.io/billchurch/webssh2:latest` (v6.0.1) 고정
- repo에 시크릿 물리적 존재 금지 — 생성물은 `~/.local/share/webssh2/hosts/`만 (XDG data)
- stow 배포는 `--no-folding` 필수 (repo Gotcha)
- 접속 URL: `http://axiom:2222/ssh/host/axiom.bun-bull.ts.net` (tailnet)
- 커밋: Conventional Commits, 머리글 영어·본문 한국어, `Co-Authored-By: Claude Code <noreply@anthropic.com>` footer
- 문서: markdown 테이블 좌측 정렬 ` :--- `, mermaid는 `graph` 키워드만

## Review Focus

| 입력/조건 | 기대 동작 | 소유 태스크 |
| :--- | :--- | :--- |
| id_ed25519에 passphrase 있음 | gen 시점 발각 — passphrase 없는 키만 config 생성 가능 | Task 1 |
| 컨테이너 config 경로가 /app 아님 | Task 1 실측으로 경로 확정, Task 3이 200으로 확인 | Task 1, 3 |
| compose `${HOME}` 미전개 | `docker compose config`으로 전개 확인 후 기동 | Task 3 |
| /data named volume 권한(uid 1000) | 재시작 후 /data 파일 존재로 영속 확인 | Task 3 |
| axiom authorized_keys에 키 미등록 | BatchMode ssh 사전검증에서 발견, 등록 후 재검 | Task 1 |

---

### Task 1: 사전 검증 — 키·도달성·컨테이너 경로

**Files:**
- Modify: 없음 (검증만) — 단 `axiom/.ssh/config`의 기존 미커밋 변경(mo 제거)을 커밋

**Interfaces:**
- Produces: 컨테이너 내 config 경로(`/app/config.json` 가설 확정), ssh 접속 가능 사실 — Task 3이 소비

- [ ] **Step 1: passphrase 없음 확인**

Run: `ssh-keygen -y -P "" -f ~/.ssh/id_ed25519 >/dev/null && echo NO-PASSPHRASE`
Expected: `NO-PASSPHRASE` — 실패하면 passphrase 있는 키라 계속 불가: 사용자에게 보고 후 중단

- [ ] **Step 2: axiom FQDN 자기 자신에 키 로그인 검증**

Run: `ssh -o BatchMode=yes -i ~/.ssh/id_ed25519 crong@axiom.bun-bull.ts.net hostname`
Expected: 출력에 `axiom` 포함. 실패 시 `~/.ssh/id_ed25519.pub` 내용을 `~/.ssh/authorized_keys`에 추가 후 재실행 (authorized_keys가 stow 추적 파일이면 repo 변경분을 Task 4에서 커밋)

- [ ] **Step 3: 컨테이너 작업 디렉토리 확인**

Run: `docker inspect --format '{{.Config.WorkingDir}}' ghcr.io/billchurch/webssh2:latest`
Expected: `/app` — 다르면 Task 3의 마운트 대상 경로를 이 값으로 치환

- [ ] **Step 4: 기존 ssh config 변경 커밋 (mo 제거)**

Run: `git add axiom/.ssh/config && git commit -m "chore(axiom): ssh config에서 폐기된 mo 호스트 제거"`

---

### Task 2: gen-hosts.sh

**Files:**
- Create: `axiom/.config/webssh2/gen-hosts.sh`

**Interfaces:**
- Produces: `gen-hosts.sh <alias> <host> <user> [keypath=~/.ssh/id_ed25519]` → `~/.local/share/webssh2/hosts/<alias>.json` 생성, 성공 시 exit 0 + `written: <경로>` 출력

- [ ] **Step 1: 스크립트 작성**

`set -euo pipefail`, 인자 개수 검증(3~4개, 위배 시 usage 출력 exit 1), 키파일 존재 검증, `mkdir -p $HOME/.local/share/webssh2/hosts`. 핵심은 PEM의 JSON escape를 jq에 위임:

```bash
jq -n --arg h "$host" --arg u "$user" --arg k "$(cat "$keypath")" \
  '{ssh:{host:$h}, user:{name:$u, privateKey:$k}}' > "$outdir/$alias_name.json"
```

변수명 `alias_name` 사용 (`alias`는 셸 빌트인 충돌 회피).

- [ ] **Step 2: 임시 키페어로 라운드트립 검증**

```bash
tmp=$(mktemp -d) && ssh-keygen -t ed25519 -N "" -f "$tmp/testkey" -q
axiom/.config/webssh2/gen-hosts.sh testhost 10.0.0.1 testuser "$tmp/testkey"
jq -e '.ssh.host=="10.0.0.1" and .user.name=="testuser"' ~/.local/share/webssh2/hosts/testhost.json
jq -r '.user.privateKey' ~/.local/share/webssh2/hosts/testhost.json > "$tmp/roundtrip" && chmod 600 "$tmp/roundtrip"
diff <(ssh-keygen -y -f "$tmp/testkey") <(ssh-keygen -y -f "$tmp/roundtrip")
```

Expected: 전부 exit 0 (diff 무출력 = PEM이 JSON 왕복에 무손실)
실패 시 스크립트 수정 후 재실행. 검증 후 `rm -rf "$tmp" ~/.local/share/webssh2/hosts/testhost.json`

- [ ] **Step 3: stow 배포**

Run: `chmod +x axiom/.config/webssh2/gen-hosts.sh && stow --no-folding -t ~ base axiom && ls -l ~/.config/webssh2/gen-hosts.sh`
Expected: symlink 표시

- [ ] **Step 4: Commit**

```bash
git add axiom/.config/webssh2/gen-hosts.sh
git commit -m "feat(axiom): webssh2 호스트 config 생성 스크립트 추가"
```

---

### Task 3: docker-compose 기동·검증

**Files:**
- Create: `axiom/.config/webssh2/docker-compose.yml`

**Interfaces:**
- Consumes: Task 2의 `gen-hosts.sh`, Task 1의 `/app` 경로
- Produces: 기동 중 `webssh2` 서비스 (restart: unless-stopped, named volume `webssh2-data`)

- [ ] **Step 1: compose 파일 작성**

```yaml
services:
  webssh2:
    image: ghcr.io/billchurch/webssh2:latest
    container_name: webssh2
    ports:
      - "2222:2222"
    volumes:
      - ${HOME}/.local/share/webssh2/hosts/axiom.json:/app/config.json:ro
      - webssh2-data:/data
    restart: unless-stopped

volumes:
  webssh2-data:
```

- [ ] **Step 2: 실제 config 생성**

Run: `~/.config/webssh2/gen-hosts.sh axiom axiom.bun-bull.ts.net crong`
Expected: `written: ~/.local/share/webssh2/hosts/axiom.json`

- [ ] **Step 3: stow 배포 + ${HOME} 전개 확인**

```bash
stow --no-folding -t ~ base axiom
docker compose -f ~/.config/webssh2/docker-compose.yml config | grep -A3 volumes
```

Expected: 볼륨 경로가 절대경로로 전개됨

- [ ] **Step 4: 기동 + HTTP 검증**

```bash
docker compose -f ~/.config/webssh2/docker-compose.yml up -d
sleep 3 && curl -s -o /dev/null -w "%{http_code}\n" http://localhost:2222/ssh/host/axiom.bun-bull.ts.net
```

Expected: `200`. `docker logs webssh2 --tail 20`에 config 관련 에러 없음. 403이 뜨면 config 미로드 → 마운트 경로 재점검

- [ ] **Step 5: 터미널 진입 검증 (Playwright)**

`http://localhost:2222/ssh/host/axiom.bun-bull.ts.net` 열기 → 터미널 프롬프트 표시 → `hostname` 입력 → 출력에 `axiom` 포함. 자동로그인이므로 로그인 폼 없이 바로 터미널이어야 함

- [ ] **Step 6: 재시작 영속 검증**

```bash
docker exec webssh2 ls /data >/dev/null && docker compose -f ~/.config/webssh2/docker-compose.yml restart
sleep 3 && curl -s -o /dev/null -w "%{http_code}\n" http://localhost:2222/ssh/host/axiom.bun-bull.ts.net
```

Expected: 재시작 후 `200` (host key 스토어는 named volume 유지)

- [ ] **Step 7: Commit**

```bash
git add axiom/.config/webssh2/docker-compose.yml
git commit -m "feat(axiom): webssh2 docker-compose 게이트웨이 추가"
```

---

### Task 4: 매뉴얼 + 인덱스

**Files:**
- Create: `docs/okf/how-to/2026-11-06-webssh2-orbstack-setup.md`
- Modify: `docs/okf/README.md`, `docs/README.md` (How-To 인덱스 라인)

**Interfaces:**
- Consumes: Task 1~3의 검증 명령들 (매뉴얼 절차로 재사용)

- [ ] **Step 1: 매뉴얼 작성**

ttyd 매뉴얼(`docs/okf/how-to/ttyd-brew-launchagent-setup.md`)과 동일 구조: 개요/전제(OrbStack·stow·jq), 설치(gen-hosts → compose up), 검증(HTTP 200·터미널), 접속 URL·태블릿 북마크(`http://axiom:2222/ssh/host/axiom.bun-bull.ts.net`), 운영(키 로테이션 = gen 재실행 + restart, OrbStack 부팅 자동기동), 확장(eve/brla = gen 1회 + 서비스 블록, 403 정책으로 호스트당 컨테이너), 문제해결(403·authorized_keys·`${HOME}` 미전개)

- [ ] **Step 2: 인덱스 2곳 갱신**

`docs/okf/README.md` How-To 섹션과 `docs/README.md` How-To 섹션에 ttyd 라인 다음 형식으로 추가:
`- [WebSSH2 OrbStack Setup](okf/how-to/2026-11-06-webssh2-orbstack-setup.md) - ...`

- [ ] **Step 3: Commit**

```bash
git add docs/okf/how-to/2026-11-06-webssh2-orbstack-setup.md docs/okf/README.md docs/README.md
git commit -m "docs: webssh2 OrbStack 설치 매뉴얼 및 인덱스 추가"
```

- [ ] **Step 4: 모바일 실사용 확인 요청 (spec 검증 6단계)**

사용자에게 X13 Chrome·iPad Safari에서 `http://axiom:2222/ssh/host/axiom.bun-bull.ts.net` 접속과 ttyd 비교 확인 요청 — 구현 종료 조건 (사용자 확인 완료까지 대기)
