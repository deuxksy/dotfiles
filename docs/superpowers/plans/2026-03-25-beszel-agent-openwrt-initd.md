# Beszel Agent OpenWrt Init.d Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** OpenWrt 서버에 beszel-agent를 init.d 서비스로 등록하여 부팅 시 자동 시작 및 프로세스 관리

**Architecture:** UCI 설정 분리(/etc/config/beszel), procd 기반 init.d 스크립트, 표준 바이너리 위치(/usr/bin/beszel)

**Tech Stack:** OpenWrt 21.02+, procd, UCI (Unified Configuration Interface), SSH

---

## File Structure

**Target Server:** arv.bun-bull.ts.net (OpenWrt)

**Files to create:**
- `/etc/config/beszel` - UCI 설정 (port, ssh_key, token, hub_url)
- `/etc/init.d/beszel-agent` - procd init.d 서비스 스크립트

**Files to copy:**
- `/root/.local/bin/beszel` → `/usr/bin/beszel` (바이너리 복사)

No new files created locally. All work is remote file operations on arv server.

---

## Task 1: Connect and Verify Environment

**Target:** arv.bun-bull.ts.net

- [ ] **Step 1: SSH to arv server**

```bash
ssh root@arv.bun-bull.ts.net
```

Expected: Successful shell access, root@arv prompt

- [ ] **Step 2: Verify OpenWrt version**

```bash
cat /etc/openwrt_release
```

Expected: OpenWrt 21.02 or higher (procd available)

- [ ] **Step 3: Verify source binary exists**

```bash
ls -la /root/.local/bin/beszel
```

Expected: File exists and is executable

- [ ] **Step 4: Verify procd available**

```bash
which procd
/etc/init.d/boot status
```

Expected: procd is running, init.d system operational

---

## Task 2: Create UCI Configuration

**Target:** `/etc/config/beszel`

- [ ] **Step 1: Create UCI config file**

```bash
cat > /etc/config/beszel <<'EOF'
config agent 'main'
    option port '45876'
    option ssh_key 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPo8CE9Y7ZScOXSEIOshSjYNTsHjp0vZ9XEuDQI59vSs'
    option token 'ad9392ba-5090-4adc-815d-a686f968e67f'
    option hub_url 'https://heritage.bun-bull.ts.net/beszel'
EOF
```

Expected: File created without errors

- [ ] **Step 2: Verify UCI config**

```bash
uci show beszel
cat /etc/config/beszel
```

Expected: Output shows agent.main with all options

- [ ] **Step 3: Test UCI config read**

```bash
uci get beszel.main.port
uci get beszel.main.ssh_key
uci get beszel.main.token
uci get beszel.main.hub_url
```

Expected: Each command returns the configured value

---

## Task 3: Copy Binary to Standard Location

**Source:** `/root/.local/bin/beszel`
**Target:** `/usr/bin/beszel`

- [ ] **Step 1: Copy binary**

```bash
cp /root/.local/bin/beszel /usr/bin/beszel
```

Expected: No errors

- [ ] **Step 2: Set executable permission**

```bash
chmod +x /usr/bin/beszel
```

Expected: No errors

- [ ] **Step 3: Verify binary**

```bash
ls -la /usr/bin/beszel
file /usr/bin/beszel
```

Expected: File exists, executable permissions, correct file type

---

## Task 4: Create Init.d Script

**Target:** `/etc/init.d/beszel-agent`

- [ ] **Step 1: Create init.d script**

```bash
cat > /etc/init.d/beszel-agent <<'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10
USE_PROCD=1

PROG="/usr/bin/beszel"
LOG_FILE="/var/log/beszel-agent.log"
CONFIG="/etc/config/beszel"

start_service() {
    mkdir -p /var/log

    local port=$(uci get beszel.main.port 2>/dev/null)
    local ssh_key=$(uci get beszel.main.ssh_key 2>/dev/null)
    local token=$(uci get beszel.main.token 2>/dev/null)
    local hub_url=$(uci get beszel.main.hub_url 2>/dev/null)

    [ -z "$port" ] && echo "Error: port not configured" && return 1
    [ -z "$ssh_key" ] && echo "Error: ssh_key not configured" && return 1
    [ -z "$token" ] && echo "Error: token not configured" && return 1
    [ -z "$hub_url" ] && echo "Error: hub_url not configured" && return 1

    procd_open_instance
    procd_set_param command $PROG \
        -p "$port" \
        -k "$ssh_key" \
        -t "$token" \
        -url "$hub_url"
    procd_set_param respawn 3600 5 5
    procd_set_param stdout $LOG_FILE
    procd_set_param stderr $LOG_FILE
    procd_close_instance
}

status_service() {
    if procd_status beszel-agent; then
        echo "✓ beszel-agent: running"
    else
        echo "✗ beszel-agent: stopped"
    fi

    echo ""
    echo "=== Latest 50 log lines ==="
    if [ -f "$LOG_FILE" ]; then
        tail -n 50 "$LOG_FILE"
    else
        echo "Log file not found: $LOG_FILE"
    fi
}

stop_service() {
    # procd handles cleanup automatically
}

shutdown() {
    stop_service
}
EOF
```

Expected: File created without errors

- [ ] **Step 2: Set executable permission**

```bash
chmod +x /etc/init.d/beszel-agent
```

Expected: No errors

- [ ] **Step 3: Verify script**

```bash
ls -la /etc/init.d/beszel-agent
head -n 10 /etc/init.d/beszel-agent
```

Expected: Executable permission set, shebang line correct

---

## Task 5: Enable and Start Service

- [ ] **Step 1: Enable service (auto-start on boot)**

```bash
/etc/init.d/beszel-agent enable
```

Expected: No errors, symlink created in /etc/rc.d/

- [ ] **Step 2: Verify enable**

```bash
ls -la /etc/rc.d/*beszel*
```

Expected: Symlink K99beszel-agent and/or S99beszel-agent exists

- [ ] **Step 3: Start service**

```bash
/etc/init.d/beszel-agent start
```

Expected: Service starts without errors

- [ ] **Step 4: Verify service status**

```bash
/etc/init.d/beszel-agent status
```

Expected:
- "✓ beszel-agent: running" displayed
- Latest 50 log lines shown

- [ ] **Step 5: Check procd status**

```bash
procd_status beszel-agent
ps | grep beszel
```

Expected: Process running under procd supervision

---

## Task 6: Verify Log Persistence

- [ ] **Step 1: Check log file**

```bash
ls -la /var/log/beszel-agent.log
head -n 20 /var/log/beszel-agent.log
```

Expected: Log file exists, contains output from beszel-agent

- [ ] **Step 2: Verify respawn configuration**

```bash
procd_status beszel-agent | grep respawn
```

Expected: Respawn parameters shown (3600 5 5)

---

## Task 7: Test Service Restart

- [ ] **Step 1: Restart service**

```bash
/etc/init.d/beszel-agent restart
```

Expected: Service stops and starts cleanly

- [ ] **Step 2: Verify after restart**

```bash
/etc/init.d/beszel-agent status
```

Expected: "✓ beszel-agent: running"

- [ ] **Step 3: Stop service**

```bash
/etc/init.d/beszel-agent stop
```

Expected: Service stops

- [ ] **Step 4: Verify stopped**

```bash
/etc/init.d/beszel-agent status
ps | grep beszel
```

Expected: "✗ beszel-agent: stopped", no process running

- [ ] **Step 5: Start again**

```bash
/etc/init.d/beszel-agent start
/etc/init.d/beszel-agent status
```

Expected: Service running again

---

## Task 8: Test UCI Configuration Management

- [ ] **Step 1: Display current config**

```bash
uci show beszel
```

Expected: Shows all beszel configuration

- [ ] **Step 2: Test config modification**

```bash
uci set beszel.main.port='45877'
uci commit beszel
/etc/init.d/beszel-agent restart
```

Expected: Config changed, service restarted

- [ ] **Step 3: Restore original port**

```bash
uci set beszel.main.port='45876'
uci commit beszel
/etc/init.d/beszel-agent restart
```

Expected: Port restored to 45876

---

## Success Criteria

- [ ] UCI config `/etc/config/beszel` created
- [ ] Binary copied to `/usr/bin/beszel`
- [ ] Init.d script `/etc/init.d/beszel-agent` created
- [ ] Service enabled and running
- [ ] Status shows "✓ beszel-agent: running"
- [ ] Log file `/var/log/beszel-agent.log` contains output
- [ ] Service restart works correctly
- [ ] UCI config management functional

---

## Rollback (if needed)

If issues occur, rollback to manual execution:

```bash
# Disable and remove service
/etc/init.d/beszel-agent disable
rm /etc/init.d/beszel-agent
rm /etc/config/beszel
rm /usr/bin/beszel

# Restore manual execution
/root/.local/bin/beszel -p 45876 \
  -k "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPo8CE9Y7ZScOXSEIOshSjYNTsHjp0vZ9XEuDQI59vSs" \
  -t "ad9392ba-5090-4adc-815d-a686f968e67f" \
  -url "https://heritage.bun-bull.ts.net/beszel"
```
