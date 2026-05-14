# Dotfiles

Cross-platform dotfiles managed by GNU Stow with sops encryption.

## Hosts

| Host | Model | OS | Config |
| :--- | :--- | :--- | :--- |
| axiom | Mac Studio | macOS | stow: `base` + `axiom` |
| eve | Mac mini | macOS | stow: `base` + `eve` |
| mo | AyaNEO AM02 | NixOS | stow: `base` + `mo` / flake |
| walle | AOOSTAR WTR R1 | Fedora | stow: `base` + `walle` |
| girl | Steam Deck | SteamOS | stow: `base` + `girl` |
| ava | Surface Pro 6 | Windows 10 | pwsh |
| kyolim | Asus Zenbook 14 UX3405C | Windows 11 | pwsh |
| pad | iPad Pro 12.9 | iPadOS | 미디어 소비, 원격접속 |

### Host Roles

- **axiom**: Local LLM 서버 (LM Studio, MLX) + 개발
- **eve**: iOS/AOS 개발 전용
- **mo**: NixOS 개발 워크스테이션

## Hardware

| Host | CPU | GPU | NPU | Memory | Disk |
| :--- | :--- | :--- | :--- | :--- | :--- |
| axiom | Apple M1 Max (10-core) | M1 Max (24-core) | 16-core | 64GB | 512GB |
| eve | Apple M4 (10-core) | M4 (10-core) | 16-core | 16GB | 256GB |
| mo | AMD Ryzen 7840HS (8C/16T) | Radeon 780M | Ryzen AI | 32GB | 1TB |
| walle | Intel N100 (4C/4T) | Intel UHD (24EU) | — | 8GB | 2TB |
| girl | AMD Custom APU 0405 | AMD Custom GPU | — | 16GB | 256GB NVMe + 512GB eMMC |
| ava | Intel Core i5-8250U (4C/8T) | Intel UHD 620 | — | 8GB | 128GB |
| kyolim | Intel Core Ultra 5 228V | Intel Arc 130V | Intel AI Boost (6 NPU TOPS) | 32GB | 512GB |
| pad | Apple M1 (8-core) | M1 (8-core) | 16-core | 16GB | 1TB |

## Install

```bash
git clone git@github.com:deuxksy/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles

# Stow 배포 (호스트에 맞게 선택)
stow -t ~ base axiom    # macOS
stow -t ~ base eve      # macOS
stow -t ~ base mo       # NixOS
stow -t ~ base walle    # Fedora
stow -t ~ base girl     # SteamOS

# macOS (Brewfile)
cd ~ && brew bundle

# NixOS (mo) — stow 배포 후 flake rebuild
sudo nixos-rebuild switch --flake ~/git/dotfiles/nix/nixos#mo
# 또는 alias: rebuild

# macOS (nix-darwin)
sudo darwin-rebuild switch --flake ~/.config/nix-darwin
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
- `mo/` — NixOS (`.gitconfig.local`, tools managed by Nix)
- `walle/` — Fedora (mise, zsh)
- `girl/` — SteamOS (mise, zsh)
- `ava/` — Windows 10 (pwsh)
- `kyolim/` — Windows 11 (pwsh)
- `nix/` — nix-darwin + NixOS flake 설정
- `.ai/` — AI 에이전트 공유 설정 (AGENTS.md)

## Secrets

[sops](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age) 로 암호화.

```bash
# secrets 복호화 (zshrc에서 자동 실행)
eval "$(sops -d ~/.key)"
```

## Git Credential

`.gitconfig`는 `base/`에 공통 설정, credential helper는 각 호스트 `.gitconfig.local`에서 관리.

| 호스트 | Helper | 비고 |
| :--- | :--- | :--- |
| macOS (axiom, eve) | `store` | `~/.git-credentials` |
| Linux (mo, walle, girl) | `store` | `~/.git-credentials` |

> 전 호스트 `core.ignoreCase = false` 통일. 최초 1회 인증 후 자동 저장.

## NixOS (mo) Gotchas

- mise 제거됨 — 모든 도구는 `environment.systemPackages`로 관리
- `npm install -g`, `corepack enable` 불가 (read-only nix store). pnpm 글로벌 사용
- `nodePackages.*` 최신 nixpkgs에서 제거됨 — 최상위 패키지(`pnpm` 등) 사용
- Claude Code는 pnpm으로 설치 (`~/.local/share/pnpm`)
- fcitx5 KDE Wayland 설정은 GUI 필요 (KDE 시스템 설정 → 가상 키보드 → Fcitx 5)
