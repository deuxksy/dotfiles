{ pkgs, ... }: {
  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  # Podman (rootless)
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # KVM/libvirt
  virtualisation.libvirtd.enable = true;
}
