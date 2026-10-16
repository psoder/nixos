{
  description = "Arrakis NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixvim = {
      url = "github:nix-community/nixvim";
      # If you are not running an unstable channel of nixpkgs, select the corresponding branch of Nixvim.
      # url = "github:nix-community/nixvim/nixos-26.05";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      mkHost =
        modules:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };

          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.nixvim.nixosModules.nixvim
          ]
          ++ modules;
        };
    in
    {
      nixosConfigurations = {
        arrakis = mkHost [
          ./hosts/arrakis/configuration.nix
        ];

        solaria = mkHost [
          ./hosts/solaria/configuration.nix
        ];
      };
    };
}
