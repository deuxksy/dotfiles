# Dotfiles

Cross-platform dotfiles managed by GNU Stow with sops encryption.

## Hosts

| Host | Hardware | OS | Stow Packages |
| :--- | :--- | :--- | :--- |
| axiom | Mac Studio (M1 Max, 64GB) | macOS | `base` + `axiom` |
| eve | Mac mini (M4, 16GB) | macOS | `base` + `eve` |
| mo | AyaNEO AM02 (Ryzen 7840HS, 32GB) | NixOS | `base` + `mo` |
| walle | AOOSTAR WTR R1 (Intel N100, 8GB) | Fedora | `base` + `walle` |
| girl | Steam Deck (256GB) | SteamOS | `base` + `girl` |
| ava | Surface Pro 6 (8GB) | Windows 10 (WSL) | `base` + `ava` |

### Other Devices

- iPad Pro 12.9 (M1, 1TB)
- Asus Zenbook 14 UX3405C — 회사 노트북

### Host Roles

- **axiom**: Local LLM 서버 (LM Studio, MLX) + 개발
- **eve**: iOS/AOS 개발 전용
- **mo**: NixOS 개발 워크스테이션

## Install

```bash
git clone git@github.com:deuxksy/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles

# macOS / Fedora / SteamOS / WSL
stow -t ~ base eve  # 호스트에 맞게 선택

# macOS (Brewfile)
cd ~ && brew bundle

# NixOS (mo)
sudo nixos-rebuild switch --flake ~/git/dotfiles/nix/nixos#mo
```

## Stow Adopt

기존 dotfiles를 stow 패키지로 가져올 때 사용.

```bash
cd ~/git/dotfiles
stow --adopt -t ~ base  # 예: base 패키지로 가져오기
```

> `--adopt`은 `$HOME`에 있는 파일을 stow 디렉토리로 이동시키고 심볼릭 링크로 대체한다.

## Structure

- `base/` — 공통 설정 (git, nvim, tmux, wezterm, .claude/rules)
- `axiom/` — macOS (mise, zsh, Brewfile)
- `eve/` — macOS (mise, zsh, Brewfile)
- `mo/` — NixOS (zsh, `.gitconfig.local`)
- `walle/` — Fedora (mise, zsh)
- `girl/` — SteamOS (mise, zsh)
- `ava/` — Windows WSL (현재 미사용)
- `nix/` — nix-darwin + NixOS 설정
- `.ai/` — AI 에이전트 공유 설정 (AGENTS.md)

## Secrets

[sops](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age) 로 암호화.

```bash
# secrets 복호화 (zshrc에서 자동 실행)
eval "$(sops -d ~/.key)"
```

## NixOS (mo)

```bash
# 시스템 rebuild
sudo nixos-rebuild switch --flake ~/git/dotfiles/nix/nixos#mo
# 또는 alias 사용
rebuild
```

## macOS (nix-darwin)

```bash
sudo darwin-rebuild switch --flake ~/.config/nix-darwin
```
