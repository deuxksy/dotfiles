# AI Project Rules

Cross-platform dotfiles managed by GNU Stow with sops encryption. Hosts/Hardware/Install → [README.md](README.md)

## Hosts

| Host | OS | Role | 패키지 관리 |
| :--- | :--- | :--- | :--- |
| mo | NixOS | 개발 워크스테이션 | nix, flake |
| axiom | macOS | 개발/일상 | Brewfile |
| eve | macOS | 개발/일상 | Brewfile |
| girl | SteamOS | 게임/개발 | mise |
| walle | Proxmox (Debian) | Homelab 서버 (K8s, VM) | stow: `base` + `walle` + `walle-sudo` (root) |
| ava | Windows 10 (Surface Pro 6) | SSH 클라이언트 | - |

## Commands

```bash
# 패키지 배포 (호스트에 맞게 선택)
stow -t ~ base eve
stow -t ~ base girl  # SteamOS
stow -t ~ base mo    # NixOS

# Brewfile 설치 (stow 배포 후 홈에서 실행)
cd ~ && brew bundle

# 기존 파일을 stow 패키지로 가져오기
stow --adopt -t ~ base
stow --no-folding -t ~ base  # Git symlink 깨짐 방지

# secrets 복호화
eval "$(sops -d ~/.key)"

# NixOS (mo)
sudo nixos-rebuild switch --flake ~/git/dotfiles/nix/nixos#mo

# walle (Proxmox) — 홈 + root 영역 배포
stow -t ~ base walle              # 홈
sudo apt install -y stow          # Proxmox 최소 설치엔 stow 없음
sudo stow -t / walle-sudo         # /etc/ssh/sshd_config.d/* (root)

# hermes-agent (mo)
sudo systemctl restart hermes-agent
sudo journalctl -u hermes-agent --since "1 min ago" --no-pager
hermes config show   # CLI 모드 설정 확인

# Git hooks 설치
git config core.hooksPath .githooks
```

## Key Files (mo/NixOS)

- `nix/nixos/flake.nix` — flake inputs + module imports
- `nix/nixos/hosts/mo/default.nix` — mo 호스트 설정
- `nix/nixos/hosts/mo/hermes.nix` — hermes-agent NixOS 서비스 + sops secret
- `nix/nixos/secrets/hermes.yaml` — sops 암호화 (ANTHROPIC_API_KEY, TELEGRAM_BOT_TOKEN)
- `mo/.hermes/config.yaml` — hermes CLI config (stow 배포)

## Key Files (axiom/macOS)

- `axiom/Brewfile` — macOS 패키지 정의 (stow 배포 후 `brew bundle`로 설치)

## Key Files (base — 전 호스트 공통, stow 배포)

- `base/.claude/rules/`에 6개 규칙 파일 (00~05) — profile, operations, verification, coding, documentation, multi-agent
- `base/.claude/CLAUDE.md`는 stow 배포용 공통 파일 (이 repo의 프로젝트 설정이 아님)
- `base/.gemini/rules/`에 6개 규칙 파일 (00~05) — Gemini 공통 규칙
- `base/.gemini/antigravity-cli/settings.json` — Antigravity CLI 설정

## Key Files (Codex — 전 호스트 공통, stow 배포)

- `base/.codex/AGENTS.md` — Codex 에이전트 오케스트레이션 설정
- `base/.codex/rules/` — Codex 규칙 파일

## Gotchas

- `CLAUDE.md`, `GEMINI.md` 모두 `.ai/RULES.md`로 symlink → AI 설정은 이 파일에서만 수정
- `.sops.yaml`로 age 키 관리, `.key` 파일은 sops 암호화됨
- `.githooks/`에 커스텀 Git hooks, `.gitleaks.toml`로 시크릿 스캔
- `stow --no-folding` 필수: Git은 symlink 디렉토리 내 파일 변경을 추적하지 않음
- `stow` 충돌 시 기존 파일을 백업 후 제거, 또는 `--adopt` 사용
- 구형 도구(`~/.gitconfig`, `~/.bashrc`)는 XDG 미지원 → `stow --adopt` 시 충돌 포인트. 신규 CLI는 `~/.config/<app>/` 우선 (basedir 0.8)
- walle `walle-sudo`: sudoers(`/etc/sudoers.d/`)는 stow symlink 불가 (visudo owner root 검사 ↔ repo 파일 crong 소유) → 수동 관리 + `.stow-local-ignore`. sshd drop-in은 stow OK
- walle: Proxmox 최소 설치에 stow 미포함 → `apt install stow` 선행
- Brewfile은 각 호스트 패키지 폴더에 위치 (`axiom/Brewfile`, `eve/Brewfile`)
- `base/.claude/.omc/hud-config.json` — OMC HUD 설정 (stow로 연결)
- hermes-agent: built-in `anthropic` provider는 `ANTHROPIC_BASE_URL` 무시 — `custom_providers` + `api_mode: anthropic_messages` 필수 (Tailscale Aperture 등 프록시 사용 시)
- hermes-agent: model명 점→하이픈 변환, API key는 sops only, CLI/gateway config 독립 (상세는 mo/.hermes/ 참조)
