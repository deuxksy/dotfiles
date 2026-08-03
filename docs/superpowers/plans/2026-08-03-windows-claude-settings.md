# Windows Claude 로컬 설정 분리 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `windows/.claude/settings.local.json`을 Windows 공통 설정으로 신설하고, install.ps1의 글로벌 링크 target을 base → windows로 변경한다.

**Architecture:** dotfiles repo의 OS 레이어 분리. `base/`(모든 OS) → `windows/`(Windows 공통). Windows 배포는 `windows/install.ps1`(관리자 권한 SymbolicLink)이 담당. 테스트는 기존 `windows/tests/` 패턴(install.ps1 내용 문자열 assertion)을 따른다.

**Tech Stack:** PowerShell, git

**Spec:** `docs/superpowers/specs/2026-08-03-windows-claude-settings-design.md`

---

### Task 1: windows/.claude/settings.local.json 생성 (base 시드)

**Files:**
- Create: `windows/.claude/settings.local.json`
- Seed: `base/.claude/settings.local.json` (워킹트리 현재 상태 — hooks 정리 반영본)

- [ ] **Step 1: base 내용을 그대로 복사**

```bash
mkdir -p windows/.claude
cp base/.claude/settings.local.json windows/.claude/settings.local.json
```

- [ ] **Step 2: 유효한 JSON이며 base와 동일한지 검증**

```bash
node -e "JSON.parse(require('fs').readFileSync('windows/.claude/settings.local.json','utf8')); console.log('valid JSON')"
diff base/.claude/settings.local.json windows/.claude/settings.local.json && echo "identical"
```

Expected: `valid JSON` + `identical`

- [ ] **Step 3: Commit**

```bash
git add windows/.claude/settings.local.json
git commit -m "feat(windows): Windows 공통 Claude 로컬 설정 추가

base 시드 복사. install.ps1 글로벌 링크가 이 파일을 가리키게 후속 변경.

crong@kyolimsoft.com"
```

### Task 2: install.ps1 링크 target 변경 테스트 (failing)

**Files:**
- Create: `windows/tests/install-claude-links.Tests.ps1`

- [ ] **Step 1: 실패하는 테스트 작성**

```powershell
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) "install.ps1"
$scriptContent = Get-Content $scriptPath -Raw

function Assert-Contains {
    param(
        [string]$Expected,
        [string]$Message
    )

    if (-not $scriptContent.Contains($Expected)) {
        throw $Message
    }
}

Assert-Contains '-Target "$dotfiles\windows\.claude\settings.local.json"' "글로벌 settings.local.json은 windows 패키지를 가리켜야 합니다"

$baseTarget = '-Target "$base\.claude\settings.local.json"'
if ($scriptContent.Contains($baseTarget)) {
    throw "글로벌 settings.local.json이 base를 가리키면 안 됩니다"
}

Write-Host "PASS: 글로벌 settings.local.json이 windows 패키지를 사용합니다" -ForegroundColor Green
```

- [ ] **Step 2: 테스트 실행하여 실패 확인**

```bash
pwsh -ExecutionPolicy Bypass -File windows/tests/install-claude-links.Tests.ps1
```

Expected: FAIL — `글로벌 settings.local.json이 base를 가리키면 안 됩니다` throw

### Task 3: install.ps1 링크 target 수정

**Files:**
- Modify: `windows/install.ps1:14` (settings.local.json SymbolicLink 라인)

- [ ] **Step 1: target 변경**

변경 전:

```powershell
New-Item -ItemType SymbolicLink -Path "$claudeDir\settings.local.json" -Target "$base\.claude\settings.local.json" -Force
```

변경 후:

```powershell
New-Item -ItemType SymbolicLink -Path "$claudeDir\settings.local.json" -Target "$dotfiles\windows\.claude\settings.local.json" -Force
```

- [ ] **Step 2: 테스트 실행하여 통과 확인**

```bash
pwsh -ExecutionPolicy Bypass -File windows/tests/install-claude-links.Tests.ps1
```

Expected: `PASS: 글로벌 settings.local.json이 windows 패키지를 사용합니다`

- [ ] **Step 3: 기존 테스트 회귀 확인**

```bash
pwsh -ExecutionPolicy Bypass -File windows/tests/install-gemini-links.Tests.ps1
```

Expected: `PASS: Gemini 설정이 부분 연결 구조를 사용합니다`

- [ ] **Step 4: Commit**

```bash
git add windows/install.ps1 windows/tests/install-claude-links.Tests.ps1
git commit -m "feat(windows): 글로벌 settings.local.json 링크를 windows 패키지로 전환

base → windows/.claude/settings.local.json. OS 레이어 분리의 일환.

crong@kyolimsoft.com"
```

### Task 4: 배포 및 검증 (사용자 실행)

symlink 생성은 관리자 권한이 필요하므로 사용자가 직접 실행한다.

- [ ] **Step 1: 관리자 PowerShell에서 install.ps1 실행**

```powershell
Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File "$env:USERPROFILE\git\dotfiles\windows\install.ps1"'
```

- [ ] **Step 2: 글로벌 링크 target 검증**

```powershell
(Get-Item "$env:USERPROFILE\.claude\settings.local.json").Target
```

Expected: `C:\Users\deuxk\git\dotfiles\windows\.claude\settings.local.json`
