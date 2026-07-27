# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory extendedhistory hist_ignore_space

# Completion
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zcompdump"

# Prompt: starship
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# Aliases
source "$HOME/.alias"

# Editor
export EDITOR="nvim"
export VISUAL="nvim"

# Key bindings (emacs 모드)
bindkey -e

# mise
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi
