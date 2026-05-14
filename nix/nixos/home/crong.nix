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
      rebuild = "sudo nixos-rebuild switch --flake /home/crong/git/dotfiles/nix/nixos#mo";
    };
    initContent = ''
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
    Host *
      LogLevel error
      StrictHostKeyChecking no
      ServerAliveInterval 120
      ForwardAgent yes
      AddKeysToAgent yes
      Port 22

    Host axiom eve mo
      HostName %h.bun-bull.ts.net
      User crong

    Host girl
      HostName %h.bun-bull.ts.net
      User deck

    Host arv steward
      HostName %h.bun-bull.ts.net
      User root
  '';

  # Mise 글로벌 설정
  home.file.".config/mise/config.toml".text = ''
    [tools]
    curlie = "latest"
    go = "1.25"
    lua = "5.4"
    node = "24"
    ollama = "latest"
    python = "3.12"
    rust = "stable"
  '';
}
