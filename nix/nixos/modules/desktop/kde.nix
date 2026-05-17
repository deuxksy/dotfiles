{ pkgs, ... }: {
  # KDE Plasma 6 (Wayland)
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # 사운드 (PipeWire)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    extraUpFlags = [ "--advertise-exit-node" ];
  };

  networking.firewall.enable = false;
}
