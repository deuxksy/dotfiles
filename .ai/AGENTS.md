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

## Key Files (mo/NixOS)

- `nix/nixos/flake.nix` — flake inputs + module imports
- `nix/nixos/hosts/mo/default.nix` — mo 호스트 설정
- `nix/nixos/hosts/mo/hermes.nix` — hermes-agent NixOS 서비스 + sops secret
- `nix/nixos/secrets/hermes.yaml` — sops 암호화 (ANTHROPIC_API_KEY, TELEGRAM_BOT_TOKEN)
- `mo/.hermes/config.yaml` — hermes CLI config (stow 배포)
- `base/.claude/rules/`에 10개 규칙 파일 (00~09)
- `base/.claude/CLAUDE.md`는 stow 배포용 공통 파일 (이 repo의 프로젝트 설정이 아님)

## Gotchas

- `CLAUDE.md`, `GEMINI.md`, `.clinerules` 모두 `.ai/AGENTS.md`로 symlink → AI 설정은 이 파일에서만 수정
- `.sops.yaml`로 age 키 관리, `.key` 파일은 sops 암호화됨
- `.githooks/`에 커스텀 Git hooks, `.gitleaks.toml`로 시크릿 스캔
- `stow` 충돌 시 기존 파일을 백업 후 제거, 또는 `--adopt` 사용
- Brewfile은 각 호스트 패키지 폴더에 위치 (`axiom/Brewfile`, `eve/Brewfile`)
- `base/.claude/.omc/hud-config.json` — OMC HUD 설정 (stow로 연결)
- hermes-agent: built-in `anthropic` provider는 `ANTHROPIC_BASE_URL` 무시 — `custom_providers` + `api_mode: anthropic_messages` 필수 (Tailscale Aperture 등 프록시 사용 시)
- hermes-agent: model명의 점(.)을 하이픈(-)로 자동 변환 — 점 없는 모델명 사용 (예: `glm-5-turbo`)
- hermes-agent: API key는 sops secret(`secrets/hermes.yaml`)에서만 관리, `hermes.nix` `environment`에 평문 금지
- hermes-agent: CLI config(`~/.hermes/config.yaml`)와 gateway config(`/var/lib/hermes/.hermes/config.yaml`)는 독립적 — 둘 다 `custom_providers` 설정 필요
