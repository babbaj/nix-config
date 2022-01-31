{
  description = "A very basic flake";

  inputs = {
    home-manager.url = "github:nix-community/home-manager";
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Updates faster but requires more compiling
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    memflow.url = "github:memflow/memflow-nixos";
    polymc.url = "github:PolyMC/PolyMC";

    looking-glass-src = {
      url = "github:gnif/LookingGlass";
      flake = false;
    };
    gb-src = {
      url = "github:leijurv/gb";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, memflow, polymc, looking-glass-src, gb-src }: 
  let
    looking-glass-src-fixed = builtins.fetchGit {
      url = "https://github.com/gnif/LookingGlass";
      inherit (looking-glass-src) rev;
      submodules = true;
    };

    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (final: prev: {
          looking-glass-client = pkgs.callPackage ./pkgs/looking-glass/looking-glass.nix { src = looking-glass-src-fixed; };
          gb-backup = pkgs.callPackage ./pkgs/gb-backup/gb.nix { src = gb-src; };
        })
        polymc.overlay
      ];
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        home-manager.nixosModule
        memflow.nixosModule
        ./configuration.nix
      ];
      pkgs = pkgs;
      #specialArgs = { inherit inputs; };
    };
  };
}
