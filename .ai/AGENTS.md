# AI Project Rules

Cross-platform dotfiles managed by GNU Stow with sops encryption. Hosts/Hardware/Install → [README.md](README.md)

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

# NixOS (mo)
sudo nixos-rebuild switch --flake ~/git/dotfiles/nix/nixos#mo

# hermes-agent (mo)
sudo systemctl restart hermes-agent
sudo journalctl -u hermes-agent --since "1 min ago" --no-pager
hermes config show   # CLI 모드 설정 확인
```

## Structure

- `base/` — 공통 설정 (git, nvim, tmux, wezterm, .claude/rules)
- `axiom/` — MacOS (mise, zsh)
- `eve/` — MacOS (mise, zsh)
- `mo/` — NixOS (zsh, tools managed by Nix)
- `walle/` — Fedora (mise, zsh)
- `girl/` — SteamOS (mise, zsh)
- `ava/` — Windows 10 (pwsh)
- `kyolim/` — Windows 11 회사 노트북 (pwsh)
- `nix/` — NixOS flake 설정 (`nix/nixos/`만 사용, 향후 `nix/darwin/`, `nix/ubuntu/` 추가 가능)
- `.ai/` — AI 에이전트 공유 설정 (AGENTS.md, AI.ignore)

## Gotchas

- `CLAUDE.md`, `GEMINI.md`, `.clinerules` 모두 `.ai/AGENTS.md`로 symlink → AI 설정은 이 파일에서만 수정
- `.sops.yaml`로 age 키 관리, `.key` 파일은 sops 암호화됨

## Key Files (mo/NixOS)

- `nix/nixos/flake.nix` — flake inputs + module imports
- `nix/nixos/hosts/mo/default.nix` — mo 호스트 설정
- `nix/nixos/hosts/mo/hermes.nix` — hermes-agent NixOS 서비스 + sops secret
- `nix/nixos/secrets/hermes.yaml` — sops 암호화 (ANTHROPIC_API_KEY, TELEGRAM_BOT_TOKEN)
- `mo/.hermes/config.yaml` — hermes CLI config (stow 배포)
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
- 네트워크: steward (192.168.222.0/24) + arv (192.168.221.0/24) Tailscale로 연결
- kyolim: 회사 노트북, stow 미사용, pwsh만 사용
- ava: Windows 10, WSL 미사용, pwsh만 사용
- arv/steward: GL.iNet OpenWrt 라우터, dotfiles 미배포
- 전 호스트 git `core.ignoreCase = false`, credential helper `store` 통일
- hermes-agent: built-in `anthropic` provider는 `ANTHROPIC_BASE_URL` 무시 — `custom_providers` + `api_mode: anthropic_messages` 필수 (Tailscale Aperture 등 프록시 사용 시)
- hermes-agent: model명의 점(.)을 하이픈(-)로 자동 변환 — 점 없는 모델명 사용 (예: `glm-5-turbo`)
- hermes-agent: API key는 sops secret(`secrets/hermes.yaml`)에서만 관리, `hermes.nix` `environment`에 평문 금지
- hermes-agent: CLI config(`~/.hermes/config.yaml`)와 gateway config(`/var/lib/hermes/.hermes/config.yaml`)는 독립적 — 둘 다 `custom_providers` 설정 필요
