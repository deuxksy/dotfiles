# Windows dotfiles install script
# Run as Administrator for file symlinks, or use Junction for directories

$dotfiles = "$env:USERPROFILE\git\dotfiles"
$windows = "$dotfiles\windows"
$kyolim = "$dotfiles\kyolim"

# --- Directories (Junction - no admin required) ---

# Neovim
New-Item -ItemType Junction -Path "$env:LOCALAPPDATA\nvim" -Target "$windows\.config\nvim" -Force

# .claude (runtime data는 로컬에 두고 설정 파일/폴더만 링크)
$claudeDir = "$env:USERPROFILE\.claude"
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force }
New-Item -ItemType SymbolicLink -Path "$claudeDir\CLAUDE.md" -Target "$windows\.claude\CLAUDE.md" -Force
New-Item -ItemType Junction -Path "$claudeDir\rules" -Target "$windows\.claude\rules" -Force
New-Item -ItemType SymbolicLink -Path "$claudeDir\settings.local.json" -Target "$windows\.claude\settings.local.json" -Force

# Claude settings.* 프리셋 링크 (settings.json은 로컬 임시/런타임 파일로 유지)
Get-ChildItem "$kyolim\.claude\settings.*" | Where-Object { $_.Name -ne "settings.local.json" -and $_.Name -ne "settings.json" } | ForEach-Object {
    New-Item -ItemType SymbolicLink -Path "$claudeDir\$($_.Name)" -Target $_.FullName -Force
}

# .codex (runtime data는 로컬에 두고 설정 파일/폴더만 링크)
$codexDir = "$env:USERPROFILE\.codex"
if (-not (Test-Path $codexDir)) { New-Item -ItemType Directory -Path $codexDir -Force }
New-Item -ItemType SymbolicLink -Path "$codexDir\AGENTS.md" -Target "$windows\.codex\AGENTS.md" -Force
New-Item -ItemType Junction -Path "$codexDir\rules" -Target "$windows\.codex\rules" -Force
New-Item -ItemType SymbolicLink -Path "$codexDir\config.toml" -Target "$kyolim\.codex\config.toml" -Force

# .gemini (runtime data는 로컬에 두고 설정 파일/폴더만 링크)
$geminiDir = "$env:USERPROFILE\.gemini"
if (Test-Path $geminiDir) {
    $geminiItem = Get-Item $geminiDir -Force
    if ($geminiItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        throw "기존 .gemini Junction을 제거한 후 다시 실행하세요: $geminiDir"
    }
} else {
    New-Item -ItemType Directory -Path $geminiDir -Force
}

New-Item -ItemType SymbolicLink -Path "$geminiDir\GEMINI.md" -Target "$windows\.gemini\GEMINI.md" -Force
New-Item -ItemType Junction -Path "$geminiDir\rules" -Target "$windows\.gemini\rules" -Force

$geminiAntigravityDir = "$geminiDir\antigravity-cli"
if (-not (Test-Path $geminiAntigravityDir)) {
    New-Item -ItemType Directory -Path $geminiAntigravityDir -Force
}
New-Item -ItemType SymbolicLink -Path "$geminiAntigravityDir\settings.json" -Target "$kyolim\.gemini\antigravity-cli\settings.json" -Force

# --- Files (Symlink - requires admin) ---

# .gitconfig
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.gitconfig" -Target "$windows\.gitconfig" -Force

# .wakatime.cfg (시크릿 파일이므로 로컬에 존재할 때만 링크)
if (Test-Path "$windows\.wakatime.cfg") {
    New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.wakatime.cfg" -Target "$windows\.wakatime.cfg" -Force
}

# .wezterm.lua
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.wezterm.lua" -Target "$windows\.wezterm.lua" -Force

# --- AI agent layer (apm) ---
# 선언적 콘텐츠(OS 무관)는 base 패키지 직접 참조 — windows/ 중복 배제 예외

# settings.json 고정 파일 (plugin 매트릭스 선언, env는 sops 프로파일로 분리)
New-Item -ItemType SymbolicLink -Path "$claudeDir\settings.json" -Target "$dotfiles\base\.claude\settings.json" -Force

# ~/.apm manifest
$apmDir = "$env:USERPROFILE\.apm"
if (-not (Test-Path $apmDir)) { New-Item -ItemType Directory -Path $apmDir -Force }
New-Item -ItemType SymbolicLink -Path "$apmDir\apm.yml" -Target "$dotfiles\base\.apm\apm.yml" -Force
New-Item -ItemType SymbolicLink -Path "$apmDir\apm.lock.yaml" -Target "$dotfiles\base\.apm\apm.lock.yaml" -Force

# provider profiles (~/.config/claude)
if (-not (Test-Path "$env:USERPROFILE\.config")) { New-Item -ItemType Directory -Path "$env:USERPROFILE\.config" -Force }
if (-not (Test-Path "$env:USERPROFILE\.config\claude")) {
    New-Item -ItemType Junction -Path "$env:USERPROFILE\.config\claude" -Target "$dotfiles\base\.config\claude" -Force
}

if (-not (Get-Command apm -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.APM --exact --source winget
}
# codex/gemini 미설치 시 frozen 실패 가능 — fallback plain install
apm install -g --frozen
if ($LASTEXITCODE -ne 0) { apm install -g }

Write-Host "Windows dotfiles installed successfully!" -ForegroundColor Green
