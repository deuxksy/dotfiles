{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Linter
    nodePackages.eslint
    python3Packages.flake8
    hadolint
    python3Packages.yamllint
    shellcheck

    # Formatter
    stylua
    nodePackages.prettier
    python3Packages.black
    rustfmt
    go
    terraform
    shfmt

    # 기타
    git
  ];

  shellHook = ''
    echo "Neovim tools environment loaded"
    echo "Available tools: eslint_d, flake8, hadolint, yamllint, shellcheck"
    echo "                 stylua, prettier, black, rustfmt, gofmt, terraform_fmt, shfmt"
  '';
}
