# walle SSH root login 차단 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** walle(Proxmox)에서 SSH 직접 root login을 차단하고, crong key 접속 + sudo 운영으로 전환한다.

**Architecture:** 기존 `walle-sudo` stow 패키지를 `/` target 계층 구조로 재편 — `etc/sudoers.d/user`(기존 이동) + `etc/ssh/sshd_config.d/10-root-login.conf`(신규). `sudo stow -t / walle-sudo` 로 `/etc` 하위 배포.

**Tech Stack:** GNU Stow, OpenSSH (sshd_config.d drop-in), Debian sudoers, Proxmox VE 8.x / Debian 12 Bookworm

## Global Constraints

- **호스트**: walle — Proxmox VE 8.x / Debian 12 Bookworm (AOOSTAR WTR R1)
- **SSH unit명**: `ssh.service` (Debian, `sshd.service` 아님)
- **sshd drop-in 규칙**: `/etc/ssh/sshd_config.d/*.conf` — "first obtained value wins", lexical order
- **sudoers**: `/etc/sudoers.d/user` — `crong ALL=(ALL) NOPASSWD: ALL`
- **두 환경 분리**: repo 변경은 dotfiles 작업 디렉토리, 배포/검증은 **walle 서버** (crong SSH 세션)
- **lockout 방지**: 현재 SSH 세션을 유지한 채 reload, 새 터미널로 사전 검증 후 기존 세션 종료
- **범위 외**: `PasswordAuthentication` 변경 없음, `install_nvtools.sh`(Fedora 잔재) 별개

**참조 spec**: `docs/superpowers/specs/2026-06-27-walle-ssh-root-login-block-design.md`

---

## File Structure

| 파일 | 변경 | 책임 |
| :--- | :--- | :--- |
| `walle-sudo/user` → `walle-sudo/etc/sudoers.d/user` | 이동 | sudoers 유지 + `/` target 계층화 |
| `walle-sudo/etc/ssh/sshd_config.d/10-root-login.conf` | 생성 | `PermitRootLogin no` drop-in |
| `README.md` | 수정 | `walle-sudo` 배포 명령 문서화 |

배포 결과(walle): `/etc/sudoers.d/user` + `/etc/ssh/sshd_config.d/10-root-login.conf`

---

### Task 1: walle 사전 상태 확인 (read-only)

**목적**: 현재 `walle-sudo` 실제 배포 target 확정 + sshd 전제 검증. design의 미확정 사항(배포 target)을 이 단계에서 확정한다.

**환경**: walle 서버 (crong SSH 세션)

**Files:** (변경 없음, read-only 확인)

- [ ] **Step 1: 현재 sudoers 배포 상태 확인**

```bash
ls -l /etc/sudoers.d/user 2>/dev/null && echo "--- user content ---" && sudo cat /etc/sudoers.d/user
```

Expected: `/etc/sudoers.d/user` 존재, 내용 `crong ALL=(ALL) NOPASSWD: ALL`.
(존재하지 않으면 현재 배포 target이 다른 것 — 이 plan의 전제가 깨짐, 중단 후 재검토)

- [ ] **Step 2: sudoers 전체 유효성 확인**

```bash
sudo visudo -c
```

Expected: `parsed OK` (기준선 확보 — 변경 후와 비교용)

- [ ] **Step 3: sshd include 존재 확인**

```bash
grep -nE '^\s*Include\s+/etc/ssh/sshd_config.d' /etc/ssh/sshd_config
```

Expected: `Include /etc/ssh/sshd_config.d/*.conf` 라인 존재.
(없으면 drop-in이 적용되지 않음 — 이 경우 메인 `sshd_config`에 include 추가 필요, 본 plan 범위 확장)

- [ ] **Step 4: ssh.service unit 확인**

```bash
systemctl cat ssh.service >/dev/null 2>&1 && echo "ssh.service OK" || echo "ssh.service MISSING"
systemctl cat sshd.service >/dev/null 2>&1 && echo "sshd.service alias EXISTS" || echo "sshd.service alias NONE"
```

Expected: `ssh.service OK`, `sshd.service alias NONE` (Debian 표준). reload 명령은 `ssh.service` 사용.

- [ ] **Step 5: 기존 drop-in 충돌 확인**

```bash
grep -rnE 'PermitRootLogin|^[[:space:]]*Match' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/ 2>/dev/null
```

Expected: 아무것도 출력되지 않거나, 기본값(`#PermitRootLogin prohibit-password` 주석)만. `Match` block이 root에 영향 주면 사전 평가 필요.

- [ ] **Step 6: 사전 결과 기록**

Step 1~5 결과를 메모. 특히 Step 1 결과(배포 target 확정)와 Step 3(include 존재)은 Task 3 진행 조건.

---

### Task 2: repo 구조 변경

**목적**: `walle-sudo` 패키지를 `/` target 계층 구조로 재편 — `user` 이동 + sshd drop-in 추가.

**환경**: dotfiles repo (작업 디렉토리 `/home/crong/git/dotfiles`)

**Files:**
- Move: `walle-sudo/user` → `walle-sudo/etc/sudoers.d/user`
- Create: `walle-sudo/etc/ssh/sshd_config.d/10-root-login.conf`

**Interfaces:**
- Produces: `walle-sudo/etc/sudoers.d/user` (내용 변경 없음), `walle-sudo/etc/ssh/sshd_config.d/10-root-login.conf` (`PermitRootLogin no`)

- [ ] **Step 1: 디렉토리 생성 + user 파일 이동**

```bash
mkdir -p walle-sudo/etc/sudoers.d walle-sudo/etc/ssh/sshd_config.d
git mv walle-sudo/user walle-sudo/etc/sudoers.d/user
```

Expected: `walle-sudo/user` 제거, `walle-sudo/etc/sudoers.d/user` 생성. 내용은 동일 (`crong ALL=(ALL) NOPASSWD: ALL`).

- [ ] **Step 2: 이동 후 내용 확인**

```bash
cat walle-sudo/etc/sudoers.d/user
```

Expected:
```text
crong ALL=(ALL) NOPASSWD: ALL
```

- [ ] **Step 3: sshd drop-in 파일 생성**

파일 `walle-sudo/etc/ssh/sshd_config.d/10-root-login.conf` 내용:

```text
# SSH root direct login 차단 — walle(Proxmox) 보안 강화
# crong 사용자 key 접속 + sudo 로 운영
PermitRootLogin no
```

(파일 권한은 stow symlink가 가리키므로 repo 파일 소유권 따름. 배포 후 walle에서 권한 검증 — Task 3 Step 5)

- [ ] **Step 4: 생성 파일 확인**

```bash
cat walle-sudo/etc/ssh/sshd_config.d/10-root-login.conf
```

Expected: Step 3 내용 그대로.

- [ ] **Step 5: repo 구조 확인**

```bash
find walle-sudo -type f | sort
```

Expected:
```text
walle-sudo/etc/ssh/sshd_config.d/10-root-login.conf
walle-sudo/etc/sudoers.d/user
```

- [ ] **Step 6: Commit**

```bash
git add walle-sudo
git commit -m "feat: walle-sudo 패키지 sshd root login 차단 drop-in 추가 및 계층 구조로 재편"
```

---

### Task 3: walle 배포 + sudoers/sshd 검증

**목적**: walle에 변경사항을 배포하고, sudoers/sshd 설정이 유효한지 reload 전에 검증한다.

**환경**: walle 서버 (crong SSH 세션, dotfiles `/home/crong/git/dotfiles`)

**진행 조건**: Task 1 Step 1(`/etc/sudoers.d/user` 존재) + Step 3(include 존재) 모두 OK.

**Files:** (배포만, repo 변경 없음)

- [ ] **Step 1: walle dotfiles 최신화**

```bash
cd ~/git/dotfiles && git pull
```

Expected: Task 2 commit이 반영됨 (`feat: walle-sudo 패키지 ...`).

- [ ] **Step 2: 기존 배포 정리 (잔여 symlink 제거)**

이전 target(`/etc/sudoers.d`) 배포 잔여가 있을 수 있으므로, 기존 symlink를 먼저 제거한다.

```bash
sudo stow -D -t /etc/sudoers.d walle-sudo 2>/dev/null || true
sudo stow -D -t / walle-sudo 2>/dev/null || true
ls -l /etc/sudoers.d/user 2>/dev/null || echo "user symlink removed"
```

Expected: `/etc/sudoers.d/user` 가 symlink면 제거됨 (실제 파일이면 보존 — 이 경우 수동 백업 후 진행). `user symlink removed` 또는 실제 파일 존재 알림.

> ⚠️ 만약 `/etc/sudoers.d/user`가 symlink가 아닌 실제 파일이면, stow가 만든 것이 아님. 이 경우 백업 후 진행: `sudo cp /etc/sudoers.d/user /etc/sudoers.d/user.bak.$(date +%Y%m%d)`

- [ ] **Step 3: 새 구조 배포 (/ target)**

```bash
cd ~/git/dotfiles && sudo stow -v -t / walle-sudo
```

Expected: `LINK: etc/sudoers.d/user` + `LINK: etc/ssh/sshd_config.d/10-root-login.conf` 로 `/etc/sudoers.d/user` + `/etc/ssh/sshd_config.d/10-root-login.conf` symlink 생성.

- [ ] **Step 4: 배포 결과 확인**

```bash
ls -l /etc/sudoers.d/user /etc/ssh/sshd_config.d/10-root-login.conf
```

Expected: 두 파일 모두 symlink → `~/git/dotfiles/walle-sudo/etc/...` 가리킴.

- [ ] **Step 5: 파일 권한 확인**

```bash
ls -lL /etc/ssh/sshd_config.d/10-root-login.conf
```

Expected: 권한 `644` 이하 (sshd_config.d 파일은 group/other 쓰기 금지). repo 파일이 `rw-r--r--`(644)이면 OK. 쓰기 권한 과다 시 `sudo chmod 644` 필요.

- [ ] **Step 6: sudoers 유효성 재검증**

```bash
sudo visudo -c
```

Expected: `parsed OK` (Task 1 Step 2 기준선과 동일 — user 이동 후에도 유효).

- [ ] **Step 7: sshd syntax 검증**

```bash
sudo sshd -t && echo "sshd config syntax OK"
```

Expected: `sshd config syntax OK` (exit 0). 에러 시 절대 reload 금지 — 메시지 확인 후 수정.

- [ ] **Step 8: sshd effective config 검증 (Match 적용 포함)**

```bash
sudo sshd -T -C user=root,host=walle,lport=22 2>/dev/null | grep '^permitrootlogin'
```

Expected: `permitrootlogin no`. (`prohibit-password` 등 다른 값이면 drop-in이 우선 적용되지 않은 것 — 충돌 원인 확인)

> ✅ 여기까지 통과하면 reload 가능. 현재 SSH 세션은 아직 유지됨.

---

### Task 4: sshd reload + 최종 차단 검증

**목적**: sshd를 reload 하고, crong 접속 보장 + root 차단을 이중 검증한다.

**환경**: walle 서버 (현재 세션 유지 + 새 터미널 2개 사용)

**주의**: 현재 SSH 세션을 닫지 말 것. 새 터미널로 검증 완료 후에만 종료.

- [ ] **Step 1: sshd reload (현재 세션 유지)**

```bash
sudo systemctl reload ssh.service
systemctl is-active ssh.service
```

Expected: `active` (reload 성공, 현재 세션 유지).

- [ ] **Step 2: 새 터미널 — crong 접속 + sudo 확인**

**별도 터미널**에서 (mo/axiom 등에서):

```bash
ssh crong@walle 'id && sudo -n true && echo "crong access + sudo OK"'
```

Expected: `uid=1000(crong)...` + `crong access + sudo OK`.
(실패 시 즉시 `sudo systemctl reload ssh.service` 롤백 영역 점검 — drop-in 제거 후 재검토)

- [ ] **Step 3: 새 터미널 — root 차단 확인**

```bash
ssh -o BatchMode=yes root@walle true 2>&1 | head -3
```

Expected: `Permission denied (publickey).` 또는 로그인 거부. (`root@walle's password:` 프롬프트는 key 미사용 폴백이지 차단 아님 — `PermitRootLogin no`이면 거부되어야 함)

- [ ] **Step 4: root 거부 원인 로그 확인**

walle 세션에서:

```bash
sudo journalctl -u ssh.service --since "3 min ago" --no-pager | grep -i 'root\|denied\|refused' | tail -10
```

Expected: root login 시도에 대한 거부 로그 (`Connection closed by authenticating user root` 또는 유사). 이것이 `PermitRootLogin no` 적용의 객관적 증거.

- [ ] **Step 5: Proxmox web UI 영향 확인**

Proxmox web UI(`https://<walle-ip>:8006`)에서 `root@pam` realm 로그인 + node 조회 (read-only) 확인.

Expected: 정상 로그인, node/VM 목록 조회 가능 (SSH 차단과 무관 확인).

- [ ] **Step 6: 기존 세션 종료 허용**

Step 2~5 모두 통과 시, 기존 SSH 세션을 안전하게 종료 가능.

---

### Task 5: README 문서화 + push

**목적**: `walle-sudo` 배포 방식 변경(`/` target)을 README에 반영하고 push.

**환경**: dotfiles repo

**Files:**
- Modify: `README.md`

- [ ] **Step 1: README 현재 walle 배포 섹션 확인**

```bash
grep -n 'stow.*walle\|walle.*stow\|sudoers\|walle-sudo' README.md
```

Expected: `stow -t ~ base walle` 라인 확인. `walle-sudo` 배포 명령은 (아마) 없음.

- [ ] **Step 2: walle-sudo 배포 명령 추가**

README의 walle 배포 섹션(또는 Commands 섹션)에 추가:

```markdown
# walle root 영역 설정 (sudoers, sshd drop-in) 배포
sudo stow -t / walle-sudo
```

기존 `stow -t ~ base walle` 아래에 배치. (정확한 삽입 위치는 README 구조에 맞춤 — Edit tool 사용)

- [ ] **Step 3: README 검증**

```bash
grep -n 'stow -t / walle-sudo' README.md
```

Expected: 추가한 라인 1회 매칭.

- [ ] **Step 4: Commit + push**

```bash
git add README.md
git commit -m "docs: walle-sudo root 영역 배포 명령 README 추가"
git push
```

---

## Self-Review

**1. Spec coverage:**
- `PermitRootLogin no` drop-in → Task 2 Step 3 ✅
- 기존 `user` 이동 (`/` target 계층화) → Task 2 Step 1 ✅
- Codex Risk(ssh.service) → Task 1 Step 4 + Task 4 Step 1 ✅
- Codex Risk(sshd -T -C effective) → Task 3 Step 8 ✅
- Codex Risk(include 사전 확인) → Task 1 Step 3 ✅
- Codex Risk(auth.log 원인 증명) → Task 4 Step 4 ✅
- lockout 방지(reload, 새 터미널) → Task 4 전체 ✅
- visudo -c 양쪽 검증 → Task 1 Step 2 + Task 3 Step 6 ✅
- README 문서화 → Task 5 ✅
- Proxmox web UI 무관 확인 → Task 4 Step 5 ✅

**2. Placeholder scan:** TBD/TODO 없음. 모든 step에 실제 명령 + 예상 출력 명시. ⚠️ 표시는 조건부 분기(rollback 조건)로 정당함.

**3. Consistency:**
- 파일 경로 `walle-sudo/etc/sudoers.d/user` ↔ Task 2 ↔ Task 3 배포 결과 일치 ✅
- `10-root-login.conf` ↔ Task 2 생성 ↔ Task 3 배포 ↔ Task 4 검증 일치 ✅
- `ssh.service` 전 task 일관 ✅
