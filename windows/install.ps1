# Windows dotfiles install script
# Run as Administrator for file symlinks, or use Junction for directories

$dotfiles = "$env:USERPROFILE\git\dotfiles"
$base = "$dotfiles\base"

# --- Directories (Junction - no admin required) ---

# Neovim
New-Item -ItemType Junction -Path "$env:LOCALAPPDATA\nvim" -Target "$base\.config\nvim" -Force

# .claude
New-Item -ItemType Junction -Path "$env:USERPROFILE\.claude" -Target "$base\.claude" -Force

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
