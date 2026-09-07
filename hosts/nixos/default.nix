# The desktop. System-wide concerns live in ../../modules; this file is the
# host identity plus the glue that doesn't belong to any one of them.
{ config, pkgs, ... }:

{
  imports = [
    # These five were carved out of the old monolithic configuration.nix and
    # MUST stay ahead of the modules below. NixOS collects option definitions
    # in reverse breadth-first import order, so listing them first keeps their
    # definitions in the same position the single-file config had — which
    # matters for order-sensitive options like environment.systemPackages,
    # boot.extraModprobeConfig and services.udev.extraRules.
    ./packages.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/services.nix

    ./hardware.nix
    ../../modules/nixos/wireguard.nix
    ../../modules/nixos/vm
    ../../modules/nixos/user-services.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/metrics.nix
    ../../modules/nix.nix
    ../../modules/nixos/mic
    ../../modules/nixos/samba.nix
  ];

  networking.hostName = "nixos";
  networking.hostId = "d5794eb2"; # ZFS requires this

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  programs.steam.enable = true;
  programs.java.enable = true;
  programs.gnupg.agent.enable = true;
  programs.nix-ld.enable = true;
  programs.zsh.enable = true;

  users.users.babbaj = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "input" "vaultwarden" ];
    shell = pkgs.zsh;
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';

  home-manager = {
    users.babbaj = {
      imports = [ ../../home/home.nix ];
      home.stateVersion = config.system.stateVersion;
    };

    useUserPackages = true;
    useGlobalPkgs = true;
    verbose = true;
  };

  # Garbage collection. `gc.automatic` is set in ../../modules/nix.nix, which
  # the macOS host shares; the schedule below is desktop-only.
  nix = {
    gc = {
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings.auto-optimise-store = true;
  };

  # This value determines the NixOS release from which the default settings for
  # stateful data, like file locations and database versions, were taken. It's
  # recommended to leave it at the release version of the first install.
  system.stateVersion = "20.09";
}
