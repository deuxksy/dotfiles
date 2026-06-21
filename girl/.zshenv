# ~/.zshenv - 모든 zsh 세션(interactive/non-interactive)에서 로드
# sshd non-interactive 세션(scp, ssh remote command 등)은 좁은 기본 PATH(/bin:/usr/bin)로 시작하므로
# .zshrc의 brew shellenv(interactive only)가 로드되지 않아 여기서 PATH 보완.
case ":$PATH:" in
  *"/home/linuxbrew/.linuxbrew/bin"*) ;;
  *) export PATH="/home/deck/.local/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH" ;;
esac
