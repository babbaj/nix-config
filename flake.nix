{
  inputs = {
    nix-alien.url = "https://flakehub.com/f/thiagokokada/nix-alien/0.1.381.tar.gz";
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/22.11";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    #inputs.agenix.url = "github:ryantm/agenix";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    memflow.url = "github:memflow/memflow-nixos";
    prism.url = "github:PrismLauncher/PrismLauncher";
    prism.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    looking-glass-src = {
      url = "ssh://git@github.com/gnif/LookingGlass.git";
      type = "git";
      ref = "master";
      submodules = true;
      flake = false;
    };
    gb-src = {
      url = "github:babbaj/gb/gitignore";
      flake = false;
    };
  };

  outputs = inputs@{
    self, nixpkgs, nixpkgs-stable, nixpkgs-master, home-manager, agenix, memflow, prism, looking-glass-src, gb-src,
    darwin, nix-alien
   }:
  let
    system = "x86_64-linux";

    pkgsMaster = import nixpkgs-master { inherit system; config.allowUnfree = true; };
    pkgsStable = import nixpkgs-stable { inherit system; config.allowUnfree = true; };

    nixpkgs-patched = let
      pkgs = (import nixpkgs { inherit system; config = {}; });
    in pkgs.applyPatches {
      name = "nixpkgs-patched";
      src = nixpkgs;
      patches = with pkgs; [
        ./update-openrazer.patch
      ];
    };
    pkgsUnpatched = (import nixpkgs { inherit system; });

    lowerBuildCores = drv: drv.overrideAttrs(old: {
      postConfigure = ''
        export NIX_BUILD_CORES=8
      '';
    });
    pkgs = import nixpkgs-patched {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = [
        "lepton-unstable-2019-08-20"
        "olm-3.2.16"
      ];

      overlays = [
        (final: prev: {
          #looking-glass-client = pkgs.callPackage ./pkgs/looking-glass/looking-glass.nix { src = looking-glass-src // { name = "source"; }; terminal = false; };
          gb-backup = pkgs.callPackage ./pkgs/gb-backup/gb.nix { src = gb-src; };
          prismlauncher = prism.packages.${system}.default.override { jdks = [ pkgs.jdk17 pkgs.jdk8 pkgs.zulu8 ]; };
          #prismlauncher = prism.packages.${system}.default;
          #bzip2 = final.bzip2_1_1;
          steam = prev.steam.override { extraArgs = "-noreactlogin"; };
          helvum = pkgsStable.helvum;
          nix-alien = nix-alien.packages.${system}.default;
        })
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
          ./macbook/macbook-config.nix
        ];
        specialArgs = { inherit inputs; };
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
          overlays = [
            (final: prev: {
              #prismlauncher = prism.packages.${system}.default.override { extraJDKs = [ final.zulu8 ]; };
              prismlauncher = prism.packages."aarch64-darwin".default;
            })
            #prism.overlay
          ];
        };
      };
  };
}
