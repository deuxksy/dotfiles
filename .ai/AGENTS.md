# AI Project Rules

Cross-platform dotfiles managed by GNU Stow with sops encryption.

## Hosts

| Host | OS | Stow Packages |
| :--- | :--- | :--- |
| Mac Studio (M1 Max, 64GB, 512GB) | MacOS 26 | `base` + `axiom` |
| Mac mini (M4, 16GB, 256GB) | MacOS 26 | `base` + `eve` |
| AyaNEO AM02 (Ryzen 7840HS, 32GB, 1TB) | NixOS | `base` + `mo` |
| Surface Pro 6 (8GB, 128GB) | Windows 10 Home (WSL) | `base` + `ava` |
| AOOSTAR WTR R1 (Intel N100, 8GB, 2TB) | Fedora (NAS) | `base` + `walle` |
| Steam Deck (256GB) | SteamOS | `base` + `girl` |
| Asus Zenbook 14 UX3405C | Windows 11 | 회사 노트북 |

### Other Devices

- iPad Pro 12.9 (M1, 1TB) — 이동형 업무, 원격접속, 미디어 소비

### Host Roles

- **axiom (Mac Studio)**: Local LLM 서버 (LM Studio, MLX) + 개발
- **eve (Mac mini)**: iOS/AOS 개발 전용

## Commands

```bash
# 패키지 배포 (호스트에 맞게 선택)
stow -t ~ base eve

# Brewfile 설치 (호스트 패키지 폴더에서)
cd ~/git/dotfiles/axiom && brew bundle

# 기존 파일을 stow 패키지로 가져오기
stow --adopt -t ~ base

# secrets 복호화
eval "$(sops -d ~/.key)"

# Nix
sudo darwin-rebuild switch --flake ~/.config/nix-darwin
```

## Structure

- `base/` — 공통 설정 (git, nvim, tmux, wezterm, .claude/rules)
- `axiom/` — MacOS (mise, zsh)
- `eve/` — MacOS (mise, zsh)
- `mo/` — NixOS (mise, zsh)
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
