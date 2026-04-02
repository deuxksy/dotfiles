{
  description = "Crong's Nix-Darwin System Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }: {
    darwinConfigurations."eve" = nix-darwin.lib.darwinSystem {
      modules = [ ./hosts/eve/default.nix ];
    };
  };
}
