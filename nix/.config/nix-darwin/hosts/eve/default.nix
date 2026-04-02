{ pkgs, ... }: {
  imports = [
    ../../modules/services/beszel-agent.nix # 서비스 모듈 로드
    ../../modules/package/nvim.nix          # Neovim external dependencies
  ];

  # 시스템 전역 정책
  nix.enable = false; # Determinate Systems 사용 시 false
  nix.settings.trusted-users = [ "crong" ];
  system.primaryUser = "crong";
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Core Utilities
    git neovim tmux ripgrep fd fzf jq yq htop atuin bat bottom btop yazi macmon grpcurl direnv mas wget curl gnupg rclone curlie mosh television lynis
    wezterm sops age
    # Development
    mise opentofu mkdocs pipx awscli2 kubectl
    # Network & Media
    ffmpeg mpv yt-dlp fastfetch chafa glow mitmproxy iperf3
    # AI & Tools
    himalaya wakatime-cli tealdeer vfkit google-cloud-sdk qwen-code gitleaks
  ];

  homebrew = {
    enable = true;
    onActivation.cleanup = "none";
    brews = [ "mole" "duck" "holmesgpt" "kubectl-ai" "k8sgpt" "k9s" ];
    casks = [ "eul" "hammerspoon" "maccy" "warp" "orbstack" ];
  };

  system.stateVersion = 5;
}
