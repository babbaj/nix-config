{
  inputs = {
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Updates faster but requires more compiling
    nixpkgs-unstable-small.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    #inputs.agenix.url = "github:ryantm/agenix";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    memflow.url = "github:memflow/memflow-nixos";
    polymc.url = "github:PolyMC/PolyMC";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    # For using Touch ID for sudo authentication.
    malob-nixpkgs.url = "github:malob/nixpkgs";

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
    self, nixpkgs, nixpkgs-unstable-small, nixpkgs-master, home-manager, agenix, memflow, polymc, looking-glass-src, gb-src,
    darwin, malob-nixpkgs
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
        ./fix-xserver.patch
        #(fetchpatch { # discord
        #  url = "https://github.com/NixOS/nixpkgs/commit/a859d764e9f9905b170152accb46fddc06b52028.patch";
        #  sha256 = "sha256-ILeqOXhTI2uARmwbMOvzJCnphco/ICx3VioVZ3Xrg3w=";
        #})
      ];
    };
    pkgsUnpatched = (import nixpkgs { inherit system; });

    pkgs = import nixpkgs-patched {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (final: prev: {
          looking-glass-client = pkgs.callPackage ./pkgs/looking-glass/looking-glass.nix { src = looking-glass-src; };
          gb-backup = pkgs.callPackage ./pkgs/gb-backup/gb.nix { src = gb-src; };
          polymc = polymc.packages.${system}.default.override { extraJDKs = [ pkgs.zulu8 ]; };
          #bzip2 = final.bzip2_1_1;
          steam = prev.steam.override { extraArgs = "-noreactlogin"; };
          #firefox = pkgsUnpatched.firefox;
          webkitgtk = pkgsUnpatched.webkitgtk;
          webkitgtk_5_0 = pkgsUnpatched.webkitgtk_5_0;
          webkitgtk_4_1 = pkgsUnpatched.webkitgtk_4_1;

          #xorg.xorgserver = prev.xorg.xorgserver;
        })
        #polymc.overlay
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
        agenix.nixosModules.age
        ./configuration.nix
      ];
      inherit pkgs;
      specialArgs = { inherit inputs; };
    };

    darwinConfigurations.soybook = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          home-manager.darwinModules.home-manager
          malob-nixpkgs.darwinModules.security-pam
          ./macbook/macbook-config.nix
        ];
        specialArgs = { inherit inputs; };
      };
  };
}
