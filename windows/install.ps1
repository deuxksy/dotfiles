# Windows dotfiles install script
# Run as Administrator for file symlinks, or use Junction for directories

$dotfiles = "$env:USERPROFILE\git\dotfiles"
$base = "$dotfiles\base"

# --- Directories (Junction - no admin required) ---

# Neovim
New-Item -ItemType Junction -Path "$env:LOCALAPPDATA\nvim" -Target "$base\.config\nvim" -Force

# .claude (runtime data는 로컬에 두고 설정 파일만 링크)
$claudeDir = "$env:USERPROFILE\.claude"
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force }
New-Item -ItemType SymbolicLink -Path "$claudeDir\CLAUDE.md" -Target "$base\.claude\CLAUDE.md" -Force
New-Item -ItemType SymbolicLink -Path "$claudeDir\settings.local.json" -Target "$dotfiles\windows\.claude\settings.local.json" -Force

# .codex (runtime data는 로컬에 두고 설정 파일/폴더만 링크)
$codexDir = "$env:USERPROFILE\.codex"
if (-not (Test-Path $codexDir)) { New-Item -ItemType Directory -Path $codexDir -Force }
New-Item -ItemType SymbolicLink -Path "$codexDir\AGENTS.md" -Target "$base\.codex\AGENTS.md" -Force
$codexRulesDir = "$codexDir\rules"
if (-not (Test-Path $codexRulesDir)) { New-Item -ItemType Directory -Path $codexRulesDir -Force }
New-Item -ItemType SymbolicLink -Path "$codexRulesDir\default.rules" -Target "$base\.codex\rules\default.rules" -Force

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

New-Item -ItemType SymbolicLink -Path "$geminiDir\GEMINI.md" -Target "$base\.gemini\GEMINI.md" -Force
New-Item -ItemType Junction -Path "$geminiDir\rules" -Target "$base\.gemini\rules" -Force

$geminiAntigravityDir = "$geminiDir\antigravity-cli"
if (-not (Test-Path $geminiAntigravityDir)) {
    New-Item -ItemType Directory -Path $geminiAntigravityDir -Force
}
New-Item -ItemType SymbolicLink -Path "$geminiAntigravityDir\settings.json" -Target "$base\.gemini\antigravity-cli\settings.json" -Force

# --- Files (Symlink - requires admin) ---

# .gitconfig
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.gitconfig" -Target "$base\.gitconfig" -Force

# .wakatime.cfg
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.wakatime.cfg" -Target "$base\.wakatime.cfg" -Force

# .wezterm.lua
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.wezterm.lua" -Target "$base\.wezterm.lua" -Force

Write-Host "Windows dotfiles installed successfully!" -ForegroundColor Green
