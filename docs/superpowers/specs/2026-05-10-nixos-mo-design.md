# NixOS 25 (AyaNEO AM02) 설정 설계

- **Date**: 2026-05-10
- **Host**: mo (AyaNEO Retro Mini PC AM02, Ryzen 7840HS, 32GB, 1TB)
- **OS**: NixOS 25 (Linux Kernel 7)

## 아키텍처 결정

| 항목 | 선택 |
| :--- | :--- |
| 접근 방식 | NixOS Flakes + Home Manager (NixOS Module 통합) |
| DE/WM | KDE Plasma 6 (Wayland) |
| 입력기 | fcitx5 (libim hangul) |
| Boot | systemd-boot (UEFI) |
| Filesystem | Btrfs + subvolumes (snapper 스냅샷) |
| Flake 구조 | 기존 `nix/`에 통합 (nix-darwin + nixos 분리) |

## 디렉토리 구조

```
nix/
├── nix-darwin/                  # Mac mini (기존, 변경 없음)
│   ├── flake.nix
│   └── hosts/eve/
├── nixos/                       # AyaNEO (신규)
│   ├── flake.nix
│   ├── hosts/mo/
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   ├── modules/
│   │   ├── desktop/kde.nix
│   │   └── virtualization.nix
│   └── home/
│       └── crong.nix
└── shared/
    └── packages.nix             # 공통 패키지 (향후 nix-darwin과 공유)

mo/                              # Stow 패키지 (신규, 최소화)
├── .config/mise/
│   └── config.toml
└── .stow-local-ignore
```

## NixOS Flake

`nix/nixos/flake.nix`:

```nix
{
  description = "Crong's NixOS System Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations."mo" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/mo/default.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.crong = import ./home/crong.nix;
        }
      ];
    };
  };
}
```

## 시스템 설정 (`hosts/mo/default.nix`)

### Boot & Filesystem

- Bootloader: `boot.loader.systemd-boot.enable = true`
- Btrfs subvolumes: `@root`, `@home`, `@nix`, `@swap`
- Snapper: 자동 스냅샷 (hourly + pre/post nixos-rebuild)

### Kernel & Hardware

- `boot.kernelPackages = pkgs.linuxPackages_latest` (Linux 7)
- AMD GPU: `amdgpu` 드라이버 (Ryzen 7840HS 내장)
- Firmware: `hardware.enableAllFirmware = true`

### Desktop

- KDE Plasma 6 (Wayland 세션)
- SDDM 디스플레이 매니저
- fcitx5 + hangul 입력기, 한영 전환 (Shift-Space)

### 시스템 패키지

```nix
environment.systemPackages = with pkgs; [
  # Core
  git neovim tmux ripgrep fd fzf jq yq htop bat bottom btop yazi
  atuin direnv wget curl gnupg rclone curlie mosh fastfetch chafa glow
  # Development
  mise opentofu kubectl awscli2 pipx aria2
  # Network & Media
  ffmpeg mpv yt-dlp mitmproxy iperf3 lynis
  # AI & Tools
  tealdeer wakatime-cli gitleaks
  # NixOS
  sops age home-manager
];
```

### Virtualization

- Docker + docker-compose (개발용)
- Podman (rootless) 대안

## Home Manager (`home/crong.nix`)

- Shell: zsh + starship
- Editor: neovim (기존 base/ 설정과 연동)
- git: 사용자 글로벌 설정
- tmux: 사용자 설정
- KDE: 단축키, 테마 커스터마이징 (필요시)

## `mo/` Stow 패키지

HM으로 관리되지 않는 최소 설정만:

- `.config/mise/config.toml` — 글로벌 mise 설정

HM이 zsh, git, tmux 등의 dotfiles를 관리하므로, stow는 mise 등 특수 설정에만 사용.

## 배포 커맨드

```bash
# NixOS 시스템 + HM 동시 적용
sudo nixos-rebuild switch --flake .#mo

# stow (mise 설정 등)
stow -t ~ base mo
```

## 구현 순서

1. `nix/nixos/` 디렉토리 생성 및 flake.nix 작성
2. `hardware-configuration.nix` 생성 (NixOS 설치 시 자동 생성된 것 복사)
3. `hosts/mo/default.nix` 작성 (시스템 설정)
4. `modules/desktop/kde.nix` 작성 (KDE + fcitx5)
5. `modules/virtualization.nix` 작성
6. `home/crong.nix` 작성 (사용자 설정)
7. `mo/` stow 패키지 생성 (최소)
8. `nixos-rebuild switch` 로 검증
