{
  inputs = {
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    #nixpkgs.url = "github:nixos/nixpkgs/pull/160343/merge"; # Gnome 42
    # Updates faster but requires more compiling
    nixpkgs-unstable-small.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    memflow.url = "github:memflow/memflow-nixos";
    polymc.url = "github:PolyMC/PolyMC";
    #polymc.url = "github:Babbaj/PolyMC/nix-refactor";

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

  outputs = { self, nixpkgs, nixpkgs-unstable-small, nixpkgs-master, home-manager, memflow, polymc, looking-glass-src, gb-src }: 
  let
    system = "x86_64-linux";

    pkgsUnstableSmall = import nixpkgs-unstable-small { inherit system; };
    pkgsMaster = import nixpkgs-master { inherit system; config.allowUnfree = true; };

    nixpkgsPatched = let
      pkgs = (import nixpkgs { inherit system; });
    in pkgs.stdenv.mkDerivation {
      name = "nixpkgs-patched";
      src = nixpkgs;
      patches = with pkgs; [
        (fetchpatch { # https://github.com/NixOS/nixpkgs/pull/166320
          url = "https://github.com/NixOS/nixpkgs/commit/8d636482f1eb7113e629ae604074e4c706068c1f.patch";
          sha256 = "sha256-06iiQBNBPHimiRIccF1AdAEA2CTFbQYlRqzzp9/UxSg=";
        })
        (fetchpatch { # https://github.com/NixOS/nixpkgs/pull/166347
          url = "https://github.com/NixOS/nixpkgs/commit/553b2f048a98c8432d04dfa38bb3e295d1b1c504.patch";
          sha256 = "sha256-/je+fBDK7qSYRkO835nleVdZuc9WJIHyZP5fgDh8V9Q=";
        })
      ];

      dontFixup = true;
      installPhase = ''
        cp -R . $out
      '';
    };

    pkgs = import nixpkgsPatched {
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
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        home-manager.nixosModule
        memflow.nixosModule
        ./configuration.nix
      ];
      inherit pkgs;
      #specialArgs = { inherit inputs; };
    };
  };
}
