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
    initContent = ''
      . ~/.path
      . ~/.alias
      eval "$(sops -d ~/.key)"
      eval "$(atuin init zsh)"
      eval "$(zoxide init zsh)"
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
    lfs.enable = true;
    settings = {
      user = {
        name = "Crong";
        email = "deuxksy@gmail.com";
      };
      init.defaultBranch = "main";
      core.editor = "nvim";
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        dark = true;
        side-by-side = true;
        line-numbers = true;
        features = "side-by-side line-numbers decorations";
        true-color = "always";
        syntax-theme = "Dracula";
        plus-style = "syntax \"#003800\"";
        minus-style = "syntax \"#3f0001\"";
        hyperlinks = true;
        hyperlinks-file-link-format = "vscode://file/{path}:{line}";
      };
      "delta \"decorations\"" = {
        commit-decoration-style = "blue ol";
        commit-style = "raw";
        file-style = "omit";
        hunk-header-decoration-style = "blue box";
        hunk-header-file-style = "red";
        hunk-header-line-number-style = "\"#067a00\"";
        hunk-header-style = "file line-number syntax";
      };
      "delta \"line-numbers\"" = {
        line-numbers-left-style = "cyan";
        line-numbers-right-style = "cyan";
        line-numbers-minus-style = "124";
        line-numbers-plus-style = "28";
      };
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      credential.helper = "store";
    };
  };

  # Direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # SSH config
  home.file.".ssh/config".text = ''
    # --- EcoAI Jump Host ---
    Host ecoai-jumphost
      HostName ecoai-cluster-01
      User kls
      Port 20010

    # --- Proxmox Nodes (Direct) ---
    Host ecoai-cluster-01 ecoai-cluster-02 ecoai-cluster-03 ecoai-cluster-04 ecoai-cluster-05
      User kls

    Host ecoai-train-01 ecoai-train-02
      User kls

    # --- Infrastructure VMs (via Jump Host) ---
    Host keco-mgmt-01 keco-haproxy-01 keco-haproxy-02
      User kls
      ProxyJump ecoai-jumphost

    # --- K8s Masters (via Jump Host) ---
    Host keco-master-01 keco-master-02 keco-master-03
      User kls
      ProxyJump ecoai-jumphost

    # --- K8s Workers (via Jump Host) ---
    Host keco-worker-01 keco-worker-02 keco-worker-03 keco-worker-04 keco-worker-gpu-01
      User kls
      ProxyJump ecoai-jumphost

    # --- K8s Train (via Jump Host) ---
    Host keco-train-01 keco-train-02
      User kls
      ProxyJump ecoai-jumphost

    # --- Personal Hosts (Tailscale) ---
    Host axiom eve mo
      HostName %h.bun-bull.ts.net
      User crong

    Host girl
      HostName %h.bun-bull.ts.net
      User deck

    Host arv steward
      HostName %h.bun-bull.ts.net
      User root

    # --- Global Defaults ---
    Host *
      LogLevel error
      StrictHostKeyChecking accept-new
      ServerAliveInterval 120
      ForwardAgent yes
      AddKeysToAgent yes
      IdentitiesOnly yes
      IdentityFile ~/.ssh/id_ed25519
      IdentityFile ~/.ssh/AI/id_ed25519
  '';
}
