# ttyd brew 설치 + LaunchAgent 상시 실행 (macOS)

- [전제 조건](#전제-조건)
- [구성](#구성)
- [설치 및 등록 절차](#설치-및-등록-절차)
- [접속](#접속)
- [검증](#검증)
- [문제 해결](#문제-해결)

macOS(axiom)에 ttyd를 brew로 설치하고 LaunchAgent로 상시 실행한다. 로그인 시 자동 시작, 크래시 시 재시작되며, Tailscale tailnet 기기에서 웹 브라우저로 셸에 접속할 수 있다.

> **Source**: 이 문서의 설정 원본은 dotfiles repo의 `axiom/Library/LaunchAgents/local.ttyd.plist`와 `axiom/.homebrew/Brewfile`이다.

## 전제 조건

- dotfiles repo의 `base` + `axiom` stow 패키지가 배포된 상태
- Homebrew (`/opt/homebrew`)
- Tailscale 가입 상태 (axiom = `100.79.223.84`, MagicDNS `axiom.bun-bull.ts.net`)

## 구성

| 구성 요소 | 역할 | 비고 |
| :--- | :--- | :--- |
| `axiom/.homebrew/Brewfile` | `brew "ttyd"` 설치 등록 | `brew bundle`으로 설치 |
| `axiom/Library/LaunchAgents/local.ttyd.plist` | 실행 정의 | stow 배포 → `~/Library/LaunchAgents/` |
| `axiom/.config/ttyd/index.html` | 커스텀 HTML (웹폰트) | jsdelivr CDN Hack Nerd Font @font-face |
| `launchctl load -w` | 활성화 (최초 1회) | 이후 부팅 시 자동 실행 |

**왜 `brew services`가 아닌가**: ttyd formula에 service stanza가 정의되어 있지 않아 `brew services start ttyd`가 동작하지 않는다 (`brew services info ttyd` → `Schedulable: false`). brew는 설치만 담당하고 실행은 launchd가 담당한다.

**실행 옵션**: `ttyd -W -t fontFamily='Hack Nerd Font' -I ~/.config/ttyd/index.html zsh`

- `-W`: 웹 클라이언트에서 키보드 입력 허용 (writable)
- `-t fontFamily=Hack Nerd Font`: xterm.js 클라이언트 렌더링 폰트 지정 — Powerlevel10k가 출력하는 Nerd Font 글리프를 브라우저에서 정상 표시
- `-I ~/.config/ttyd/index.html`: 커스텀 HTML 지정 — `font-family`가 로컬 설치 폰트만 참조하면 폰트 없는 기기(Android 등)에서 깨지므로, jsdelivr CDN의 Hack Nerd Font 웹폰트(gzip 약 1.4MB, 브라우저 캐시)를 `@font-face`로 로드한다. 어느 기기에서나 동일 렌더링. 첫 방문은 폰트 다운로드 동안 폴백 폰트로 표시되다 전환되며, 이후 캐시로 즉시 적용된다
- `zsh`: PTY 할당으로 interactive 셸 실행 (`~/.zshrc` 로드)
- 포트: 기본값 7681, 인터페이스: 기본값 모든 인터페이스
- 인증 없음 — tailnet 자체가 신뢰 경계

**커스텀 index.html 재생성** (ttyd 업그레이드로 원본 HTML이 바뀐 경우):

```bash
curl -s http://localhost:7681 -o /tmp/ttyd-index-orig.html
sed 's|<style type="text/css">|<style type="text/css">@font-face{font-family:"Hack Nerd Font";src:url(https://cdn.jsdelivr.net/gh/ryanoasis/nerd-fonts@v3.4.0/patched-fonts/Hack/Regular/HackNerdFont-Regular.ttf) format("truetype");font-display:swap;}|' /tmp/ttyd-index-orig.html > ~/.config/ttyd/index.html
launchctl unload ~/Library/LaunchAgents/local.ttyd.plist && launchctl load -w ~/Library/LaunchAgents/local.ttyd.plist
```

> 주의: `-I` 지정 상태에서는 원본 HTML을 다시 받을 수 없으므로, 재생성 시 일시적으로 plist에서 `-I`를 제거하거나 `ttyd -p 7683` 등 임시 포트로 원본을 받는다.

## 설치 및 등록 절차

dotfiles repo에서 이미 모두 반영된 상태라면 3번부터 수행하면 된다.

1. Brewfile 등록 (`axiom/.homebrew/Brewfile`):

```text
brew "mosh"
brew "ttyd"
```

2. 설치:

```bash
cd ~ && brew bundle
```

3. plist 배포 (repo root에서):

```bash
stow --no-folding -R -t ~ axiom
```

4. LaunchAgent 활성화:

```bash
launchctl load -w ~/Library/LaunchAgents/local.ttyd.plist
```

`-W` 플래그로 `RunAtLoad`가 활성화되어 로그인 시 자동 실행된다. plist 변경 시 unload 후 재load:

```bash
launchctl unload ~/Library/LaunchAgents/local.ttyd.plist
launchctl load -w ~/Library/LaunchAgents/local.ttyd.plist
```

## 접속

웹 브라우저에서:

| 위치 | URL |
| :--- | :--- |
| axiom 로컬 | `http://localhost:7681` |
| tailnet (MagicDNS) | `http://axiom:7681` |
| tailnet (IP) | `http://100.79.223.84:7681` |

ttyd가 모든 인터페이스(0.0.0.0:7681)를 리슨하므로 Tailscale 측 추가 설정은 불필요하다.

## 검증

```bash
# 1. 프로세스 확인 — PID가 출력되어야 함
launchctl list | grep ttyd

# 2. 로컬 응답 확인 — HTML 반환
curl -s http://localhost:7681 | head -1

# 3. tailnet IP 응답 확인
curl -s http://100.79.223.84:7681 | head -1
```

부팅 후 자동 실행 검증은 재부팅 후 1번을 다시 실행하면 된다.

## 문제 해결

| 증상 | 확인 |
| :--- | :--- |
| 실행 안 됨 | `launchctl list | grep ttyd` — exit code가 0이 아니면 `/tmp/ttyd.err` 확인 |
| 포트 충돌 | `lsof -i :7681` — 다른 프로세스가 접근 중인지 확인 |
| tailnet에서 접속 안 됨 | `tailscale status`로 axiom online 여부 확인 |
| plist 수정 반영 안 됨 | unload → load 재실행 (launchd는 로드 시점의 plist를 사용) |
| 로그 확인 | `/tmp/ttyd.log`, `/tmp/ttyd.err` |
