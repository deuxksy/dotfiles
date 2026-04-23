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
New-Item -ItemType SymbolicLink -Path "$claudeDir\settings.local.json" -Target "$base\.claude\settings.local.json" -Force

# .gemini
New-Item -ItemType Junction -Path "$env:USERPROFILE\.gemini" -Target "$base\.gemini" -Force

# --- Files (Symlink - requires admin) ---

# .gitconfig
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.gitconfig" -Target "$base\.gitconfig" -Force

# .wakatime.cfg
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.wakatime.cfg" -Target "$base\.wakatime.cfg" -Force

# .wezterm.lua
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.wezterm.lua" -Target "$base\.wezterm.lua" -Force

Write-Host "Windows dotfiles installed successfully!" -ForegroundColor Green
