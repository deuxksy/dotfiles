# Neovim External Dependencies
# Linters, Formatters, Tools for nvim-lint and conform.nvim

{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Linters
    eslint_d
    python3Packages.flake8
    hadolint
    python3Packages.yamllint
    shellcheck

    # Formatters
    stylua
    prettierd
    python3Packages.black
    rustfmt
    go
    opentofu
    shfmt
  ];
}
