# AI Project Rules

Cross-platform dotfiles managed by GNU Stow with sops encryption.

## Hosts

| Host | Model | CPU | Memory | Disk | OS | Config |
| :--- | :--- | :--- | :--- | :--- | :--- |
| axiom (Mac Studio) | M1 Max | 64GB | 512GB | macOS | stow: `base` + `axiom` |
| eve (Mac mini) | M4 | 16GB | 256GB | macOS | stow: `base` + `eve` |
| mo (AyaNEO AM02) | Ryzen 7840HS | 32GB | 1TB | NixOS | stow: `base` + `mo` / flake |
| walle (AOOSTAR WTR R1) | Intel N100 | 8GB | 2TB | Fedora | stow: `base` + `walle` |
| girl (Steam Deck) | — | — | 256GB | SteamOS | stow: `base` + `girl` |
| ava (Surface Pro 6) | — | 8GB | 128GB | Windows 10 | pwsh |
| kyolim (Zenbook 14) | — | — | — | Windows 11 | pwsh |
| iPad Pro 12.9 | M1 | — | 1TB | iPadOS | 미디어 소비, 원격접속 |

### Other Devices

- iPad Pro 12.9 (M1, 1TB) — 이동형 업무, 원격접속, 미디어 소비

### Host Roles

- **axiom (Mac Studio)**: Local LLM 서버 (LM Studio, MLX) + 개발
- **eve (Mac mini)**: iOS/AOS 개발 전용

## Commands

```bash
# 패키지 배포 (호스트에 맞게 선택)
stow -t ~ base eve

# Brewfile 설치 (stow 배포 후 홈에서 실행)
cd ~ && brew bundle

# 기존 파일을 stow 패키지로 가져오기
stow --adopt -t ~ base

# secrets 복호화
eval "$(sops -d ~/.key)"

# Nix (macOS)
sudo darwin-rebuild switch --flake ~/.config/nix-darwin

# NixOS (mo)
sudo nixos-rebuild switch --flake ~/git/dotfiles/nix/nixos#mo
```

## Structure

- `base/` — 공통 설정 (git, nvim, tmux, wezterm, .claude/rules)
- `axiom/` — MacOS (mise, zsh)
- `eve/` — MacOS (mise, zsh)
- `mo/` — NixOS (zsh, tools managed by Nix)
- `walle/` — Fedora (mise, zsh)
- `girl/` — SteamOS (mise, zsh)
- `nix/` — nix-darwin 설정
- `.ai/` — AI 에이전트 공유 설정 (AGENTS.md, AI.ignore)

## Gotchas

- `CLAUDE.md`, `GEMINI.md`, `.clinerules` 모두 `.ai/AGENTS.md`로 symlink → AI 설정은 이 파일에서만 수정
- `.sops.yaml`로 age 키 관리, `.key` 파일은 sops 암호화됨
- `.githooks/`에 커스텀 Git hooks, `.gitleaks.toml`로 시크릿 스캔
- `base/.claude/rules/`에 10개 규칙 파일 (00~09)
- `base/.claude/CLAUDE.md`는 stow 배포용 공통 파일 (이 repo의 프로젝트 설정이 아님)
- Brewfile은 각 호스트 패키지 폴더에 위치 (`axiom/Brewfile`, `eve/Brewfile`)
- `stow` 충돌 시 기존 파일을 백업 후 제거, 또는 `--adopt` 사용
- `base/.claude/.omc/hud-config.json` — OMC HUD 설정 (stow로 연결)
- NixOS(mo): `npm install -g`, `corepack enable` 불가 (read-only nix store). pnpm 글로벌 사용
- NixOS(mo): `nodePackages.*` 최신 nixpkgs에서 제거됨 — 최상위 패키지(`pnpm` 등) 사용
- NixOS(mo): mise 제거됨 — 모든 도구는 `environment.systemPackages`로 관리
- NixOS(mo): Claude Code는 pnpm으로 설치 (`~/.local/share/pnpm`), Nix이 아닌 pnpm으로 버전 관리
- NixOS(mo): fcitx5 KDE Wayland 설정은 GUI 필요 (KDE 시스템 설정 → 가상 키보드 → Fcitx 5)
- `.gitconfig` credential helper는 각 호스트 `.gitconfig.local`에서 관리 (base는 `[include]` 사용)
