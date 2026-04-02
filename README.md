# Dotfiles

Cross-platform dotfiles managed by GNU Stow with sops encryption.

## Hosts

| Host            | OS              | Packages           |
| :-------------- | :-------------- | :----------------- |
| Mac Mini M4     | macOS           | `base` + `eve`     |
| Surface Pro 6   | Ubuntu (WSL)    | `base` + `ava`     |
| AOOSTAR WTR R1  | Fedora          | `base` + `walle`   |
| Steam Deck      | SteamOS         | `base` + `girl`    |

## Install

```bash
git clone git@github.com:deuxksy/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
stow -t ~ base eve  # 호스트에 맞게 선택
```

## Structure

- **base/** — 공통 설정 (git, nvim, tmux, wezterm)
- **eve/** — macOS (mise, shell_gpt, zsh)
- **walle/** — Fedora (mise, zsh)
- **girl/** — Steam Deck (mise, zsh)
- **nix/** — nix-darwin 설정
- **docs/** — 설계 문서

## Secrets

[sops](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age) 로 암호화.

```bash
# ~/.key 복호화 (zshrc에서 자동 실행)
eval "$(sops -d ~/.key)"
```

## Nix

```bash
sudo darwin-rebuild switch --flake ~/.config/nix-darwin#eve
```
