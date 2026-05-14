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
    fcitx5 = {
      waylandFrontend = false;
      addons = with pkgs; [
        fcitx5-hangul
        fcitx5-gtk
        qt6Packages.fcitx5-configtool
      ];
      settings = {
        globalOptions = {
          Hotkey = {
            TriggerKeys = "Shift+Space";
          };
        };
        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "hangul";
          };
          "Groups/0/Items/0" = {
            Name = "keyboard-us";
            Layout = "us";
          };
          "Groups/0/Items/1" = {
            Name = "hangul";
            Layout = "us";
          };
          "GroupOrder" = {
            "0" = "Default";
          };
        };
        addons = {
          "org.fcitx.Fcitx5.Plugin.Hangul" = {
            globalSection = {};
            sections = {
              Hangul = { HangulKeyboard = "2"; };
              Hotkey = { Trigger = "Shift+Space"; };
            };
          };
        };
      };
    };
  };

  # 사운드 (PipeWire)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.tailscale.enable = true;

  networking.firewall.enable = false;
}
