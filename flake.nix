{
  inputs = {
    nix-alien.url = "https://flakehub.com/f/thiagokokada/nix-alien/0.1.381.tar.gz";
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs-stable.url = "github:nixos/nixpkgs/22.11";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    memflow.url = "github:memflow/memflow-nixos";
    prism.url = "github:PrismLauncher/PrismLauncher";

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
      url = "github:leijurv/gb";
      flake = false;
    };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , nixpkgs-stable
    , home-manager
    , agenix
    , memflow
    , prism
    , looking-glass-src
    , gb-src
    , darwin
    , nix-alien
    }:
    let
      system = "x86_64-linux";

      pkgsStable = import nixpkgs-stable { inherit system; config.allowUnfree = true; };

      # NOTE: `patches` is empty, but this is *not* a no-op: applyPatches gives
      # nixpkgs a distinct store path, which `pkgs.path` (and therefore
      # /etc/nixpkgs-link, see modules/nix.nix) points at. Dropping it changes
      # the system closure. It exists so a patch can be dropped in with no
      # other edits.
      nixpkgs-patched =
        let
          pkgs = import nixpkgs { inherit system; config = { }; };
        in
        pkgs.applyPatches {
          name = "nixpkgs-patched";
          src = nixpkgs;
          patches = [ ];
        };

      pkgs = import nixpkgs-patched {
        inherit system;
        config.allowUnfree = true;

        overlays = [
          (final: prev: {
            looking-glass-client = pkgs.callPackage ./pkgs/looking-glass/looking-glass.nix {
              source = looking-glass-src // { name = "source"; };
            };
            gb-backup = pkgs.callPackage ./pkgs/gb-backup/gb.nix { src = gb-src; };
            prismlauncher = prism.packages.${system}.default.override {
              jdks = [ pkgs.jdk17 pkgs.jdk8 pkgs.zulu8 ];
            };
            steam = prev.steam.override { extraArgs = "-noreactlogin"; };
            helvum = pkgsStable.helvum;
            nix-alien = nix-alien.packages.${system}.default;
            obs-studio-plugins = prev.obs-studio-plugins // {
              looking-glass-obs = prev.obs-studio-plugins.looking-glass-obs.overrideAttrs (old: {
                nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.pkg-config ];
                buildInputs = old.buildInputs ++ [ pkgs.libunwind pkgs.elfutils ];
              });
            };
          })
        ];
      };

      # Same caveat as nixpkgs-patched above: the empty patch list still
      # changes home-manager's store path.
      home-manager-patched = pkgs.applyPatches {
        name = "home-manager-patched";
        src = home-manager;
        patches = [ ];
      };

      nixosSystem = args:
        import "${nixpkgs-patched}/nixos/lib/eval-config.nix" (args // {
          modules = args.modules ++ [{
            system.nixos.versionSuffix =
              ".${pkgs.lib.substring 0 8 (self.lastModifiedDate or self.lastModified or "19700101")}.${self.shortRev or "dirty"}";
            system.nixos.revision = pkgs.lib.mkIf (self ? rev) self.rev;
          }];
        });
    in
    {
      nixosConfigurations.nixos = nixosSystem {
        inherit system pkgs;
        specialArgs = { inherit inputs; };
        modules = [
          (import "${home-manager-patched}/nixos")
          memflow.nixosModule
          agenix.nixosModules.age
          {
            nix.settings = {
              substituters = [ "https://cosmic.cachix.org/" ];
              trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
            };
          }
          ./PC
        ];
      };

      darwinConfigurations.soybook = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          home-manager.darwinModules.home-manager
          ./macbook/macbook-config.nix
        ];
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
          overlays = [
            (final: prev: {
              prismlauncher = prism.packages."aarch64-darwin".default;
            })
          ];
        };
      };
    };
}
