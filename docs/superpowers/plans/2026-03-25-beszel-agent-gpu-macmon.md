# Beszel Agent GPU Monitoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** beszel-agent가 Apple Silicon GPU 정보를 수집하도록 `GPU_COLLECTOR="macmon"` 환경변수 추가

**Architecture:** Nix darwin launchd user agent의 EnvironmentVariables에 GPU 수집기 설정 추가. macmon 바이너리는 이미 systemPackages에 설치됨.

**Tech Stack:** Nix darwin, launchd, beszel-agent, macmon

---

## File Structure

**Single file modification:**
- `nix/.config/nix-darwin/modules/services/beszel-agent.nix` - launchd user agent 서비스 정의

No new files created. This is a single-line addition to existing EnvironmentVariables block.

---

## Task 1: Add GPU_COLLECTOR Environment Variable

**Files:**
- Modify: `nix/.config/nix-darwin/modules/services/beszel-agent.nix:11-16`

- [ ] **Step 1: Verify current file state**

```bash
cat nix/.config/nix-darwin/modules/services/beszel-agent.nix
```

Expected: EnvironmentVariables block with KEY, PORT, TOKEN, HUB_URL

- [ ] **Step 2: Add GPU_COLLECTOR to EnvironmentVariables**

Edit the EnvironmentVariables block to include:

```nix
EnvironmentVariables = {
  KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPo8CE9Y7ZScOXSEIOshSjYNTsHjp0vZ9XEuDQI59vSs";
  PORT = "45876";
  TOKEN = "REDACTED_BESZEL_KEY";
  HUB_URL = "https://heritage.bun-bull.ts.net/beszel";
  GPU_COLLECTOR = "macmon";
};
```

Location: After `HUB_URL` line (line 15), before closing brace (line 16)

- [ ] **Step 3: Verify Nix syntax**

```bash
nix-instantiate --parse nix/.config/nix-darwin/modules/services/beszel-agent.nix
```

Expected: No syntax errors, valid Nix expression

- [ ] **Step 4: Commit configuration change**

```bash
git add nix/.config/nix-darwin/modules/services/beszel-agent.nix
git commit -m "feat: add GPU_COLLECTOR=macmon to beszel-agent

Enable Apple Silicon GPU monitoring through macmon integration

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Apply and Verify

**Files:**
- System configuration (no file modification)

- [ ] **Step 1: Build and switch configuration**

```bash
darwin-rebuild switch
```

Expected: Build succeeds, no errors

- [ ] **Step 2: Verify launchd agent is loaded**

```bash
launchctl list | grep beszel
```

Expected: `io.beszel.agent` listed with PID

- [ ] **Step 3: Check agent environment variables**

```bash
launchctl print gui/$(id -u)/io.beszel.agent
```

Expected: Environment section shows `GPU_COLLECTOR = "macmon"`

- [ ] **Step 4: Verify agent is running and collecting metrics**

```bash
tail -20 ~/.cache/beszel/beszel-agent.log
```

Expected: Agent running, no errors, GPU metrics being collected

- [ ] **Step 5: Optional - Verify in Beszel Hub**

1. Open https://heritage.bun-bull.ts.net/beszel
2. Navigate to the host (eve) dashboard
3. Check GPU metrics section for Apple Silicon data

Expected: GPU usage, temperature, power metrics visible

---

## Success Criteria

- [ ] `GPU_COLLECTOR = "macmon"` added to beszel-agent.nix
- [ ] `darwin-rebuild switch` completes successfully
- [ ] launchd agent running with new environment variable
- [ ] GPU metrics appear in Beszel Hub dashboard

---

## Rollback (if needed)

```bash
# Revert the commit
git revert HEAD

# Rebuild
darwin-rebuild switch
```
