# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export SHORT_HOST="eve"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

plugins=(git)
source $ZSH/oh-my-zsh.sh

export LANG=en_US.UTF-8

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
. ~/.path
. ~/.alias
eval "$(sops -d ~/.key)"

# initialise completions with ZSH's compinit (with -C flag for speed)
autoload -Uz compinit && compinit -C
autoload -Uz bashcompinit && bashcompinit

eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"
eval "$(mise activate zsh)"
