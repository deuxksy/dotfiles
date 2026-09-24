# ==============================================================================
# Bazzite Zsh Configuration (Pure Zsh + Starship, OMZ Free)
# ==============================================================================

# --- 1. Environment & Paths ---
export LANG="en_US.UTF-8"
export EDITOR="nvim"
export VISUAL="nvim"

# Load Homebrew environment
if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Load custom paths, aliases & sops secrets
[ -f "$HOME/.path" ] && source "$HOME/.path"
[ -f "$HOME/.alias" ] && source "$HOME/.alias"
[ -f "$HOME/.key" ] && command -v sops &>/dev/null && eval "$(sops -d "$HOME/.key" 2>/dev/null)"

# --- 2. History Settings ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt appendhistory sharehistory extendedhistory hist_ignore_space hist_ignore_dups hist_verify

# --- 3. Key Bindings (Emacs Mode) ---
bindkey -e

# --- 4. Completion System ---
autoload -Uz compinit && compinit
autoload -Uz bashcompinit && bashcompinit

# --- 5. Modern CLI Integrations ---
# Starship Prompt
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# Zoxide (Smart cd)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# Atuin (Shell History)
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
fi

# Mise (Runtime / SDK Manager)
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# --- 6. Syntax Highlighting & Autosuggestions (from Homebrew) ---
[ -f "/home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "/home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Syntax highlighting must be sourced last
[ -f "/home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "/home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# --- 7. PNPM ---
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
