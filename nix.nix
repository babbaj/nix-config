{ pkgs, inputs, ... }:

{
  nix = {
    # This specifies the Nix package nix-darwin references. Without this, Nix
    # will downgrade to Nix stable, which lacks flake support.
    # https://github.com/LnL7/nix-darwin/search?q=nix.package
    #
    # TODO: Understand how nix-darwin referencing an older version of Nix will
    # cause my entire installation to downgrade.
    #package = pkgs.nixFlakes;

    extraOptions = ''
      sandbox = true
      experimental-features = nix-command flakes recursive-nix
    '';

    # This is the default Nix expression search path. The default value assumes
    # you're using Nix channels, so we have to modify it so that older tools
    # (e.g., nix-shell) that still rely on literal paths will work.
    #
    # TODO: Confirm my understanding and elaborate on how this relates to the
    # Repl: https://nixos.wiki/wiki/Flakes#Getting_Instant_System_Flakes_Repl
    nixPath = [ "nixpkgs=${pkgs.path}" ];

    registry = {
      # Make sure the flake registry follows nixpkgs-unstable, which we
      # defined in our flake.nix. These are the defaults:
      # https://github.com/NixOS/flake-registry/blob/master/flake-registry.json.
      nixpkgs.flake = inputs.nixpkgs;
    };

    gc = {
      automatic = true;
    };
  };
}
