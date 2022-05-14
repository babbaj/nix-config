{
  inputs = {
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Updates faster but requires more compiling
    nixpkgs-unstable-small.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    memflow.url = "github:memflow/memflow-nixos";
    polymc.url = "github:PolyMC/PolyMC";
    #polymc.url = "github:Babbaj/PolyMC/nix-refactor";

    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-21.11-darwin";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    # For using Touch ID for sudo authentication.
    malob-nixpkgs.url = "github:malob/nixpkgs";
    home-manager-darwin.url = "github:nix-community/home-manager";
    home-manager-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    looking-glass-src = {
      url = "ssh://git@github.com/gnif/LookingGlass.git";
      type = "git";
      ref = "master";
      submodules = true;
      flake = false;
    };
    gb-src = {
      url = "github:leijurv/gb";
      flake = false;
    };
  };

  outputs = inputs@{
    self, nixpkgs, nixpkgs-unstable-small, nixpkgs-master, home-manager, memflow, polymc, looking-glass-src, gb-src,
    darwin, nixpkgs-darwin, home-manager-darwin, malob-nixpkgs
   }:
  let
    system = "x86_64-linux";

    pkgsUnstableSmall = import nixpkgs-unstable-small { inherit system; };
    pkgsMaster = import nixpkgs-master { inherit system; config.allowUnfree = true; };

    nixpkgs-patched = let
      pkgs = (import nixpkgs { inherit system; });
    in pkgs.applyPatches {
      name = "nixpkgs-patched";
      src = nixpkgs;
      patches = with pkgs; [
        #(fetchpatch { # https://github.com/NixOS/nixpkgs/pull/166347
        #  url = "https://github.com/NixOS/nixpkgs/commit/553b2f048a98c8432d04dfa38bb3e295d1b1c504.patch";
        #  sha256 = "sha256-/je+fBDK7qSYRkO835nleVdZuc9WJIHyZP5fgDh8V9Q=";
        #})
      ];
    };

    pkgs = import nixpkgs-patched {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (final: prev: {
          looking-glass-client = pkgs.callPackage ./pkgs/looking-glass/looking-glass.nix { src = looking-glass-src; };
          gb-backup = pkgs.callPackage ./pkgs/gb-backup/gb.nix { src = gb-src; };
        })
        polymc.overlay
      ];
    };

    home-manager-patched = pkgs.applyPatches {
      name = "home-manager-patched";
      src = home-manager;
      patches = with pkgs; [

      ];
    };

    nixosSystem = args:
      import "${nixpkgs-patched}/nixos/lib/eval-config.nix" (args // {
        modules = args.modules ++ [ {
            system.nixos.versionSuffix = ".${pkgs.lib.substring 0 8 (self.lastModifiedDate or self.lastModified or "19700101")}.${self.shortRev or "dirty"}";
            system.nixos.revision = pkgs.lib.mkIf (self ? rev) self.rev;
        } ];
      });
  in {
    nixosConfigurations.nixos = nixosSystem {
      inherit system;
      modules = [
        (import "${home-manager-patched}/nixos")
        memflow.nixosModule
        ./configuration.nix
      ];
      inherit pkgs;
      #specialArgs = { inherit inputs; };
    };

    darwinConfigurations.soybook = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          home-manager-darwin.darwinModules.home-manager
          malob-nixpkgs.darwinModules.security-pam
          ./hosts/macbook-config.nix
        ];
        specialArgs = {
          inherit inputs;
        };
      };
  };
}
