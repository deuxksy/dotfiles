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
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "audio" "libvirt" ];
    shell = pkgs.zsh;
  };

  # Sudo
  security.sudo.extraRules = [
    {
      users = [ "crong" ];
      commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
    }
  ];

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
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
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
