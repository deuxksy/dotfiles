{
  description = "Crong's NixOS System Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixos";
    };
  };

  outputs = { self, nixpkgs, nixos, home-manager, sops-nix, hermes-agent }: {
    nixosConfigurations."mo" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [
            (final: prev: {
              mitmproxy = prev.mitmproxy.overridePythonAttrs (old: {
                pythonRelaxDeps =
                  if (old.pythonRelaxDeps or false) == true
                  then true
                  else (old.pythonRelaxDeps or [ ]) ++ [ "msgpack" ];
              });
              pipx = prev.pipx.overridePythonAttrs { doCheck = false; };
            })
          ];
        }
        ./hosts/mo/default.nix
        sops-nix.nixosModules.sops
        hermes-agent.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.crong = import ./home/crong.nix;
        }
      ];
    };
  };
}
