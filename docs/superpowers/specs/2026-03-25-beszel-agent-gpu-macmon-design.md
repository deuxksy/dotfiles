# Beszel Agent GPU Monitoring - Apple Silicon

**Date**: 2026-03-25
**Status**: Approved
**Type**: Configuration Update

## Overview

Beszel-agent가 Apple Silicon GPU 정보를 수집할 수 있도록 `GPU_COLLECTOR="macmon"` 환경변수를 launchd 서비스 설정에 추가합니다.

## Current State

- **Service**: `modules/services/beszel-agent.nix` - launchd user agent로 실행 중
- **Dependencies**: `macmon` 패키지는 이미 `environment.systemPackages`에 설치됨
- **Environment Variables**: KEY, PORT, TOKEN, HUB_URL 설정됨

## Design

### Change

**File**: `nix/.config/nix-darwin/modules/services/beszel-agent.nix`

**Location**: `launchd.user.agents.beszel-agent.serviceConfig.EnvironmentVariables`

**Addition**:
```nix
GPU_COLLECTOR = "macmon";
```

### Complete Structure

```nix
launchd.user.agents.beszel-agent = {
  serviceConfig = {
    Label = "io.beszel.agent";
    ProgramArguments = [ "${pkgs.beszel}/bin/beszel-agent" ];

    EnvironmentVariables = {
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPo8CE9Y7ZScOXSEIOshSjYNTsHjp0vZ9XEuDQI59vSs";
      PORT = "45876";
      TOKEN = "REDACTED_BESZEL_KEY";
      HUB_URL = "https://heritage.bun-bull.ts.net/beszel";
      GPU_COLLECTOR = "macmon";  # Apple Silicon GPU monitoring
    };

    RunAtLoad = true;
    KeepAlive = true;
    ProcessType = "Background";
    StandardOutPath = "/Users/crong/.cache/beszel/beszel-agent.log";
    StandardErrorPath = "/Users/crong/.cache/beszel/beszel-agent.log";
  };
};
```

## Impact Analysis

### Benefits
- Apple Silicon GPU 사용량, 온도, 전력 소비 모니터링 가능
- 기존 모니터링 인프라에 GPU 메트릭 추가

### Risks
- **None**: macmon은 이미 설치된 상태, 환경변수만 추가
- 사이드 이펙트 없음

### Dependencies
- `pkgs.macmon` - ✅ Already in `environment.systemPackages`
- `pkgs.beszel` - ✅ Already in module

## Deployment

```bash
# Apply configuration
darwin-rebuild switch

# Verify service
launchctl list | grep beszel
launchctl print gui/$(id -u)/io.beszel.agent

# Check logs
tail -f ~/.cache/beszel/beszel-agent.log
```

## Verification

1. `darwin-rebuild switch` 실행 후 빌드 성공
2. `launchctl list`에서 beszel-agent 실행 중 확인
3. Beszel Hub에서 GPU 메트릭 수집 확인

## References

- Beszel GPU Guide: https://beszel.dev/guide/gpu
- macmon: Apple GPU monitoring tool (already installed)
