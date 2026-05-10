# NixOS 25 (AyaNEO AM02) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** AyaNEO AM02에 NixOS 25 개발 워크스테이션 환경 구성 (KDE Plasma 6, Home Manager, fcitx5)

**Architecture:** NixOS Flakes + Home Manager (NixOS Module 통합). 기존 `nix/nix-darwin/`과 병렬로 `nix/nixos/` 디렉토리 생성. HM이 dotfiles를 관리하므로 `mo/` stow는 최소화.

**Tech Stack:** NixOS 25, Flakes, Home Manager, KDE Plasma 6 (Wayland), fcitx5, Docker/Podman

---

## File Structure

| Action | Path | Responsibility |
| :--- | :--- | :--- |
| Create | `nix/nixos/flake.nix` | NixOS flake 정의 (inputs, outputs) |
| Create | `nix/nixos/hosts/mo/default.nix` | 호스트 시스템 설정 |
| Create | `nix/nixos/hosts/mo/hardware-configuration.nix` | 하드웨어 설정 (설치 시 생성) |
| Create | `nix/nixos/modules/desktop/kde.nix` | KDE Plasma + fcitx5 + 폰트 |
| Create | `nix/nixos/modules/virtualization.nix` | Docker + Podman |
| Create | `nix/nixos/home/crong.nix` | Home Manager 사용자 설정 |
| Create | `mo/.stow-local-ignore` | stow 제외 패턴 |
| Create | `mo/.config/mise/config.toml` | 글로벌 mise 설정 |

---

### Task 1: 디렉토리 구조 및 Flake 생성

**Files:**
- Create: `nix/nixos/flake.nix`
- Create: `nix/nixos/hosts/mo/default.nix` (빈 골격)
- Create: `nix/nixos/home/crong.nix` (빈 골격)

- [ ] **Step 1: 디렉토리 생성**

```bash
mkdir -p nix/nixos/hosts/mo
mkdir -p nix/nixos/modules/desktop
mkdir -p nix/nixos/home
mkdir -p nix/shared
```

- [ ] **Step 2: `nix/nixos/flake.nix` 작성**

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

- [ ] **Step 3: `nix/nixos/hosts/mo/default.nix` 골격 작성**

```nix
{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop/kde.nix
    ../../modules/virtualization.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hardware
  hardware.enableAllFirmware = true;
  hardware.graphics.enable = true;

  # Networking
  networking.hostName = "mo";
  networking.networkmanager.enable = true;

  # Timezone & Locale
  time.timeZone = "Asia/Ho_Chi_Minh";
  i18n.defaultLocale = "en_US.UTF-8";

  # User
  users.users.crong = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "audio" ];
    shell = pkgs.zsh;
  };

  # Shell
  programs.zsh.enable = true;

  # Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "crong" ];
  nixpkgs.config.allowUnfree = true;

  # System Packages
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

  # Font
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # Snapper (Btrfs 자동 스냅샷)
  services.snapper = {
    configs = {
      root = {
        SUBVOLUME = "/";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 12;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 0;
        TIMELINE_LIMIT_MONTHLY = 0;
      };
      home = {
        SUBVOLUME = "/home";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 12;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 0;
        TIMELINE_LIMIT_MONTHLY = 0;
      };
    };
  };

  # Auto-login (개발 워크스테이션)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "crong";

  system.stateVersion = "25.05";
}
```

- [ ] **Step 4: `nix/nixos/home/crong.nix` 골격 작성**

```nix
{ config, pkgs, ... }: {
  home.username = "crong";
  home.homeDirectory = "/home/crong";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      gs = "git status";
      gc = "git commit";
      gd = "git diff";
      glog = "git log --oneline --graph --decorate";
      rebuild = "sudo nixos-rebuild switch --flake /home/crong/.config/nixos#mo";
    };
    initExtra = ''
      eval "$(mise activate zsh)"
      eval "$(atuin init zsh)"
    '';
  };

  # Starship
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character.success_symbol = "[➜](bold green)";
      character.error_symbol = "[➜](bold red)";
    };
  };

  # Git
  programs.git = {
    enable = true;
    userName = "Crong";
    userEmail = "deuxksy@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };

  # Direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
```

- [ ] **Step 5: hardware-configuration.nix 플레이스홀더 생성**

```nix
# NOTE: NixOS 설치 후 /etc/nixos/hardware-configuration.nix를 복사하세요
# cp /etc/nixos/hardware-configuration.nix nix/nixos/hosts/mo/
{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-UUID";
    fsType = "btrfs";
    options = [ "subvol=@root" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-UUID";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-UUID";
    fsType = "vfat";
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
}
```

- [ ] **Step 6: 커밋**

```bash
git add nix/nixos/
git commit -m "feat(nixos): NixOS 25 mo 호스트 flake 및 골격 설정 추가"
```

---

### Task 2: KDE Plasma + fcitx5 모듈

**Files:**
- Create: `nix/nixos/modules/desktop/kde.nix`

- [ ] **Step 1: `nix/nixos/modules/desktop/kde.nix` 작성**

```nix
{ pkgs, ... }: {
  # KDE Plasma 6 (Wayland)
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # fcitx5 입력기
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-hangul
      fcitx5-gtk
      fcitx5-qt
      fcitx5-configtool
    ];
  };

  # KDE Wayland 환경 변수
  environment.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
  };

  # 사운드 (PipeWire)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
```

- [ ] **Step 2: 커밋**

```bash
git add nix/nixos/modules/desktop/kde.nix
git commit -m "feat(nixos): KDE Plasma 6 + fcitx5 + PipeWire 모듈 추가"
```

---

### Task 3: Virtualization 모듈

**Files:**
- Create: `nix/nixos/modules/virtualization.nix`

- [ ] **Step 1: `nix/nixos/modules/virtualization.nix` 작성**

```nix
{ pkgs, ... }: {
  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  # Podman (rootless 대안)
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # KVM/libvirt (선택)
  virtualisation.libvirt.enable = true;
  users.extraGroups.libvirt = [ "libvirt" ];
}
```

- [ ] **Step 2: 커밋**

```bash
git add nix/nixos/modules/virtualization.nix
git commit -m "feat(nixos): Docker + Podman + libvirt 가상화 모듈 추가"
```

---

### Task 4: `mo/` Stow 패키지 생성

**Files:**
- Create: `mo/.stow-local-ignore`
- Create: `mo/.config/mise/config.toml`

- [ ] **Step 1: `mo/.stow-local-ignore` 작성**

```
scripts
```

- [ ] **Step 2: `mo/.config/mise/config.toml` 작성**

기존 `walle/.config/mise/config.toml` 참조하여 작성:

```bash
cp walle/.config/mise/config.toml mo/.config/mise/config.toml
```

- [ ] **Step 3: 커밋**

```bash
git add mo/
git commit -m "feat: mo 호스트 stow 패키지 (mise 설정) 추가"
```

---

### Task 5: 기존 설정 복사 및 마이그레이션

**Files:**
- Create: `mo/.ssh/config` (기존 walle에서 복사 후 수정)
- Create: `mo/.key` (sops 암호화)

- [ ] **Step 1: SSH config 복사**

```bash
mkdir -p mo/.ssh
cp walle/.ssh/config mo/.ssh/config
```

- [ ] **Step 2: `.key` 파일 복사 (sops 암호화 파일)**

```bash
cp walle/.key mo/.key
```

- [ ] **Step 3: 커밋**

```bash
git add mo/
git commit -m "feat: mo 호스트 SSH config 및 key 파일 추가"
```

---

### Task 6: 검증 — `nixos-rebuild switch`

**Prerequisites:** AyaNEO에 NixOS 25 설치 완료, `hardware-configuration.nix` 복사 완료

- [ ] **Step 1: hardware-configuration.nix 교체**

AyaNEO에서 실행:

```bash
cp /etc/nixos/hardware-configuration.nix /path/to/dotfiles/nix/nixos/hosts/mo/hardware-configuration.nix
```

- [ ] **Step 2: flake 빌드 테스트**

```bash
cd nix/nixos
nix flake check
```

Expected: no errors

- [ ] **Step 3: 시스템 적용**

```bash
sudo nixos-rebuild switch --flake .#mo
```

Expected: 시스템 빌드 성공, 재부팅 후 KDE Plasma 로그인

- [ ] **Step 4: 검증 항목 체크**

```bash
# KDE Plasma Wayland 세션 확인
echo $XDG_SESSION_TYPE  # expected: wayland

# fcitx5 동작 확인
fcitx5-diagnose

# Home Manager 패키지 확인
home-manager packages

# Docker 동작 확인
docker run --rm hello-world

# stow 배포
cd /path/to/dotfiles && stow -t ~ base mo
```

- [ ] **Step 5: 검증 완료 후 커밋**

```bash
git add -A
git commit -m "feat(nixos): mo 호스트 hardware-configuration 적용 및 검증 완료"
```
