{
  description = "A very basic flake";

  inputs = {
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos.url = "github:nixos/nixpkgs/nixos-unstable-small";
    memflow.url = "github:memflow/memflow-nixos";
  };

  outputs = { self, nixpkgs, nixos, home-manager, memflow }: {
    
    nixosConfigurations.nixos = nixos.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModule
        memflow.nixosModule
        ./configuration.nix
      ];
      #pkgs = nixpkgsFor.x86_64-linux nixos;
      #specialArgs = { inherit inputs; };
    };
  };
}
