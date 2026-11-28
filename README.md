# Dotfiles

macOS, SteamOS, Debian, Windows 등 이종 운영체제 환경을 GNU Stow 및 sops 암호화로 일관되게 관리하는 크로스플랫폼 dotfiles 프로젝트입니다.

## Documentation

상세 설계, 가이드 및 레퍼런스는 [docs/README.md](docs/README.md) 및 [OKF Hub](docs/okf/README.md)를 참조하세요.

- **🟢 Tutorials**: [Install Guide](#install) | [Windows Setup Guide](windows/README.md)
- **🟡 How-To**: [sops Implementation Plan](docs/okf/how-to/2026-04-03-sops-key-encryption-implementation.md) | [ttyd LaunchAgent Setup](docs/okf/how-to/ttyd-brew-launchagent-setup.md) | [WebSSH2 OrbStack Setup](docs/okf/how-to/2026-11-06-webssh2-orbstack-setup.md) | [Project Optional MCP·plugin](docs/okf/how-to/2026-11-14-project-optional-mcp-plugin.md)
- **🔵 Reference**: [Docs Sub-Hub](docs/README.md) | [OKF Hub](docs/okf/README.md) | [Infrastructure Reference](docs/okf/reference/infrastructure.md) | [Neovim Config Guide](base/.config/nvim/README.md) | [AI Agent 의존성 인벤토리](docs/okf/reference/ai-agent-dependencies.md)
- **🟣 Explanation**: [Stow Structure Design](docs/okf/explanation/2026-03-03-stow-structure-design.md) | [sops Encryption Design](docs/okf/explanation/2026-04-03-sops-key-encryption-design.md) | [apm Agent Layer Design](docs/okf/explanation/2026-09-27-apm-agent-layer-design.md)
  - [chezmoi 전환 로드맵](./ROADMAP.md) - 호스트별 전환 목표와 단계별 진행 상황

## Hosts

| Host | Model | OS | Config | Role |
| :--- | :--- | :--- | :--- | :--- |
| axiom | Mac Studio | macOS | stow: `base` + `axiom` | Local LLM 서버 (LM Studio, MLX) + 개발 |
| eve | Mac mini | macOS | stow: `base` + `eve` | iOS/AOS 개발 전용 |
| walle | AOOSTAR WTR R1 | Proxmox (Debian) | stow: `base` + `walle` | Homelab 서버 (K8s, VM) |
| girl | Steam Deck | SteamOS | stow: `base` + `girl` | 휴대용 서버 / 게임·개발 |
| auxo | Raspberry Pi 3 Model B | Debian 13 (trixie) | stow: `base` + `auxo` | 휴대용 헤드리스 서버 |
| ava | Surface Pro 6 | Windows 10 | pwsh | SSH 클라이언트 |
| kyolim | Asus Zenbook 14 UX3405C | Windows 11 | pwsh | 개발/일상 |
| pad | iPad Pro 12.9 | iPadOS | - | 미디어 소비, 원격접속 |
| arv | GL.iNet GL-MT3000 | OpenWrt | - | 휴대용 Wi-Fi 6 라우터 |
| steward | GL.iNet GL-MT2500 | OpenWrt | - | 상주 네트워크 서버 / VPN 라우터 |

## Install

```bash
git clone git@github.com:deuxksy/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles

# macOS / Linux 호스트 — 1커맨드 bootstrap (stow + brew + apm)
./install.sh eve     # 또는 axiom | bazzite | girl | auxo

# walle (Proxmox)
sudo apt install -y stow
stow --no-folding -t ~ base walle
sudo stow -t / walle-sudo
```

### Stow adopt

홈 디렉터리의 기존 파일을 `base/`로 가져올 때 실행합니다. 가져온 내용은 `git diff`로 확인하세요.

```bash
stow --no-folding --adopt -t ~ base
```

### 검증 및 관리 (`mise` tasks)

```bash
mise run verify           # shellcheck, gitleaks, stow dry-run, Windows tests
mise run doctor           # hooksPath, symlink, sops, 필수 바이너리 점검
mise run sops:check       # ~/.key 복호화 점검
mise run hooks:install    # git config core.hooksPath .githooks
mise run apm:repair       # ~/.apm/apm.yml symlink 복구 및 lock 이관
```

- **AI Agent Layer**: `apm install -g`가 외부 skill·MCP를 `claude`/`codex`에 배포합니다(`base/.apm/`).
- **Secrets**: [sops](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age)로 암호화되며 `eval "$(sops -d ~/.key)"`로 복호화합니다.

## Structure

| 디렉토리 | 대상 | 설명 |
| :--- | :--- | :--- |
| `base/` | non-Windows 전체 | POSIX 공통 설정 (`.zshrc`, `.gitconfig`, `.tmux.conf`, `.apm/`, `.claude/`, `.codex/`, `.gemini/`, `.config/nvim/`, `ghostty`, `himalaya`) |
| `axiom/`, `eve/` | macOS | 호스트별 Brewfile, `.tmuxp/`, `.holmes/`, `ttyd`/`webssh2` (`axiom`) |
| `walle/`, `girl/`, `auxo/` | Linux / SteamOS | 호스트별 환경 설정 (`walle-sudo/`는 `/etc/ssh/sshd_config.d/`용) |
| `windows/`, `kyolim/`, `ava/` | Windows | PowerShell 배포(`windows/install.ps1`) 및 호스트별 설정 |
| `nix/` | NixOS | 이전 NixOS `mo` 설정 아카이브 |
| `docs/` | - | 설계/구현 문서 (OKF, superpowers specs & plans) |
| `.ai/`, `.githooks/`, `.github/` | - | AI 공유 규칙, Git hooks, Dependabot |
