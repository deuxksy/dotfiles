# AI Project Rules

Cross-platform dotfiles managed by GNU Stow with sops encryption.

## Hosts

| Host | OS | Stow Packages |
| :--- | :--- | :--- |
| Mac Mini M4 | MacOS | `base` + `eve` |
| AyaNEO AM-02 | NixOS | `base` + `eve` |
| Surface Pro 6 | Windows (WSL) | `base` + `ava` |
| AOOSTAR WTR R1 | Fedora | `base` + `walle` |
| Steam Deck | SteamOS | `base` + `girl` |

## Commands

```bash
# 패키지 배포 (호스트에 맞게 선택)
stow -t ~ base eve

# 기존 파일을 stow 패키지로 가져오기
stow --adopt -t ~ base

# secrets 복호화
eval "$(sops -d ~/.key)"

# Nix
sudo darwin-rebuild switch --flake ~/.config/nix-darwin
```

## Structure

- `base/` — 공통 설정 (git, nvim, tmux, wezterm, .claude/rules)
- `eve/` — MacOS (mise, zsh)
- `mo/` — NixOS (mise, zsh)
- `walle/` — Fedora (mise, zsh)
- `girl/` — SteamOS (mise, zsh)
- `nix/` — nix-darwin 설정
- `.ai/` — AI 에이전트 공유 설정 (AGENTS.md, AI.ignore)

## Gotchas

- `CLAUDE.md`, `GEMINI.md`, `.clinerules` 모두 `.ai/AGENTS.md`로 symlink → AI 설정은 이 파일에서만 수정
- `.sops.yaml`로 age 키 관리, `.key` 파일은 sops 암호화됨
- `base/.claude/rules/`에 10개 규칙 파일 (00~09)
- `base/.claude/CLAUDE.md`는 stow 배포용 공통 파일 (이 repo의 프로젝트 설정이 아님)
- `.githooks/`에 커스텀 Git hooks, `.gitleaks.toml`로 시크릿 스캔
