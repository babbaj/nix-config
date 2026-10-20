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
    ./boot.nix
    ./networking.nix
    ./desktop.nix
    ./services.nix

    ./hardware.nix
    ./wireguard.nix
    ./vm
    ./user-services.nix
    ./audio.nix
    ./metrics.nix
    ./nix.nix
    ./mic
    ./samba.nix
    ./qbittorrent.nix
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
  # gamescope + its WSI Vulkan layer (64- and 32-bit), needed for HDR passthrough with `gamescope --hdr-enabled`
  programs.gamescope = {
    enable = true;
    enableWsi = true;
  };
  # "Steam" session at the GDM login screen: gamescope drives the display directly, so HDR works
  # (GNOME lacks the color-management features nested gamescope needs for HDR)
  programs.steam.gamescopeSession = {
    enable = true;
    # EDID's preferred mode is 60Hz, so the refresh rate has to be given explicitly
    args = [ "--hdr-enabled" "-W" "2560" "-H" "1440" "-r" "240" ];
    # lets DXVK/vkd3d-proton (DX11/DX12 games) expose HDR to the game, as SteamOS does
    env.DXVK_HDR = "1";
  };
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
      imports = [ ../home/home.nix ];
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
