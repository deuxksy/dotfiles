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

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Networking
  networking.hostName = "mo";
  networking.networkmanager.enable = true;

  # Keyboard
  services.xserver.xkb = {
    layout = "kr";
  };
  console.useXkbConfig = true;

  # Timezone & Locale
  time.timeZone = "Asia/Seoul";
  #i18n.defaultLocale = "en_US.UTF-8";
  i18n = {
    defaultLocale = "ko_KR.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ko_KR.UTF-8/UTF-8"
    ];
  };

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
  environment.variables.EDITOR = "nvim";

  # Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "crong" ];
  nixpkgs.config.allowUnfree = true;

  # nix-ld (바이너리 호환성)
  programs.nix-ld.enable = true;
  environment.sessionVariables.LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
  ];

  # CUPS (프린팅)
  services.printing.enable = true;

  # Firefox
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    age aria2 atuin awscli2
    bat bottom btop
    chafa curl
    delta direnv dust duf
    eza
    fd ffmpeg fzf
    gcc git github-cli gitleaks glow gnupg go google-chrome gping gnumake
    hexyl home-manager htop hyperfine
    iperf3
    jq
    kdePackages.kate k8sgpt kubectl
    lazygit lua5_4 lynis
    fastfetch mitmproxy mosh mpv
    neovim nodejs_24 pnpm
    ollama openssl opentofu
    pipx pkg-config procs python3
    rclone ripgrep rustc cargo
    shell-gpt solaar sops stow
    tealdeer tailscale tmux tmuxp tokei
    uv wget
    xh
    yazi yt-dlp yq
    zlib zoxide
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

  # SSH
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  # Auto-login (개발 워크스테이션)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "crong";

  system.stateVersion = "25.11";
}
