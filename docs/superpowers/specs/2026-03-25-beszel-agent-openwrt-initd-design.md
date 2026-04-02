# Beszel Agent OpenWrt Init.d Service

**Date**: 2026-03-25
**Status**: Approved
**Type**: Configuration Update

## Overview

OpenWrt 서버(arv)에 beszel-agent를 init.d 서비스로 등록하여 프로세스 관리 및 부팅 시 자동 시작을 설정합니다.

## Current State

- **Server**: arv.bun-bull.ts.net (OpenWrt 21.02+)
- **Binary**: `/root/.local/bin/beszel` → `/usr/bin/beszel`로 복사 예정
- **Service**: 수동 실행 중, init.d 미등록

## Design

### Files

**UCI Configuration**: `/etc/config/beszel`
```sh
config agent 'main'
    option port '45876'
    option ssh_key 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPo8CE9Y7ZScOXSEIOshSjYNTsHjp0vZ9XEuDQI59vSs'
    option token 'ad9392ba-5090-4adc-815d-a686f968e67f'
    option hub_url 'https://heritage.bun-bull.ts.net/beszel'
```

**Init.d Script**: `/etc/init.d/beszel-agent`
**Permissions**: `755` (executable)
**Format**: OpenWrt procd init.d script with UCI integration

**Binary**: `/usr/bin/beszel` (복사본)

### Complete Script

```sh
#!/bin/sh /etc/rc.common

START=99
STOP=10
USE_PROCD=1

PROG="/usr/bin/beszel"
LOG_FILE="/var/log/beszel-agent.log"
CONFIG="/etc/config/beszel"

start_service() {
    mkdir -p /var/log

    # Read UCI config
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
```

### Architecture

**UCI Integration**:
- 설정 분리: `/etc/config/beszel`
- `uci` 명령어로 설정 관리
- init.d 스크립트에서 설정 읽기

**Procd Integration**:
- `USE_PROCD=1`: procd 서비스 관리 사용
- `procd_set_param respawn 3600 5 5`: 1시간당 5회, 5초 간격 재시작
- `procd_set_param stdout/stderr`: 로그 파일로 리다이렉션

**Start/Stop Priority**:
- `START=99`: 가능한 늦게 시작 (네트워크 완전 초기화 후)
- `STOP=10`: 가능한 빨리 종료

**Status Output**:
- 프로세스 상태 (running/stopped)
- 최신 로그 50줄 (`tail -n 50`)

**Log Persistence**:
- `/var/log/`는 재부팅 후에도 보존됨
- overlay filesystem에 저장

## Impact Analysis

### Benefits
- 부팅 시 자동 시작
- 프로세스 크래시 시 자동 재시작
- 표준 OpenWrt 서비스 명령어로 관리 (`/etc/init.d/beszel-agent start|stop|status|restart`)
- 통합된 로그 관리

### Risks
- **None**: 기존 바이너리 사용, 새로운 의존성 없음

### Dependencies
- OpenWrt 21.02+ (procd) - ✅ Confirmed
- `/root/.local/bin/beszel` - ✅ Source binary exists

## Deployment

```bash
# SSH to arv server
ssh root@arv.bun-bull.ts.net

# 1. Copy binary to standard location
cp /root/.local/bin/beszel /usr/bin/beszel
chmod +x /usr/bin/beszel

# 2. Create UCI config
cat > /etc/config/beszel <<'EOF'
config agent 'main'
    option port '45876'
    option ssh_key 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPo8CE9Y7ZScOXSEIOshSjYNTsHjp0vZ9XEuDQI59vSs'
    option token 'ad9392ba-5090-4adc-815d-a686f968e67f'
    option hub_url 'https://heritage.bun-bull.ts.net/beszel'
EOF

# 3. Create init.d script
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

# 4. Set executable permission
chmod +x /etc/init.d/beszel-agent

# 5. Enable service (auto-start on boot)
/etc/init.d/beszel-agent enable

# 6. Start service
/etc/init.d/beszel-agent start

# 7. Verify status
/etc/init.d/beszel-agent status
```

### UCI Configuration Management

```bash
# 설정 조회
uci show beszel

# 설정 수정
uci set beszel.main.port='45877'
uci commit beszel
/etc/init.d/beszel-agent restart
```

## Verification

1. 바이너리 복사 완료: `ls -la /usr/bin/beszel`
2. UCI config 생성 완료: `uci show beszel`
3. 스크립트 생성 및 권한 설정 완료: `ls -la /etc/init.d/beszel-agent`
4. `/etc/init.d/beszel-agent enable` 실행
5. `/etc/init.d/beszel-agent start`로 서비스 시작
6. `/etc/init.d/beszel-agent status`로 상태 확인:
   - "✓ beszel-agent: running" 표시
   - 로그 출력 정상 (`tail -n 50 /var/log/beszel-agent.log`)
7. 재부팅 후 자동 시작 확인

## Rollback (if needed)

```bash
# Disable and remove service
/etc/init.d/beszel-agent disable
rm /etc/init.d/beszel-agent
rm /etc/config/beszel
rm /usr/bin/beszel

# Restore manual execution
/root/.local/bin/beszel -p 45876 -k "ssh-ed25519 ..." -t "..." -url "..."
```

## References

- OpenWrt procd documentation: https://openwrt.org/docs/guide-developer/procd
- Beszel Agent Installation: https://beszel.dev/guide/hub-installation#_3-manual-compile-and-start-any-platform
