{ config, pkgs, ... }:

{
  imports = [
    ../nix.nix
    ./wireguard.nix
  ];

  home-manager = {
      users.babbaj = {
        imports = [
          ../home/home.nix
        ];
        home.stateVersion = "22.11";
      };
      useUserPackages = true;
      useGlobalPkgs = true;
      verbose = true;

  };

  programs.zsh = {
      enable = true;
      enableFzfCompletion = true;
      enableFzfHistory = true;
      enableSyntaxHighlighting = true;
  };

  system.stateVersion = 5;

  networking.computerName = "m1";
  networking.hostName = "m1";
  networking.localHostName = "m1";

  # The gnupg agent configuration that comes with home-manager doesn't work on
  # macOS.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.nix-daemon.enable = true;

  # Dock
  system.defaults.dock.wvous-tl-corner = 2; # Top Left → Mission Control

  # Date and Time
  time.timeZone = "America/New_York";

  users = {
    users.babbaj = {
      home = "/Users/babbaj";
      isHidden = false;
      shell = pkgs.zsh;
    };
  };
  nix.configureBuildUsers = true;

  environment.systemPackages = with pkgs; [
      pv
      wget
      smartmontools # smartctl
      bat
      ripgrep
      jq
      mediainfo
      cmake
      jetbrains.idea-community
      go
      git
      #prismlauncher
  ];

  # List Homebrew packages that we want to manage. Some Nix packages of MacOS
  # applications aren't mature. Homebrew must be installed out-of-band.
  homebrew = {
    enable = true;

    brews = [
      "pinentry-mac"
      "wireguard-tools"
    ];

    casks = [
      "bitwarden"
      "discord"
      "element"
      "firefox"
      "steam"
      "visual-studio-code"
      "kitty"
      "spotify"
      "telegram"
      # java
      "zulu"
      #"zulu8"
      #"zulu15"
      #"zulu17"
      #"zulu21"
      "manymc"
      "rectangle" # window snapping
      "hot" # temp monitoring
      "mpv"
      "vlc"
      "coconutbattery"
      "prismlauncher"
      "qbittorrent"
    ];

    onActivation.cleanup = "zap";
    onActivation.upgrade = true;
  };

  # https://github.com/malob/nixpkgs/blob/master/modules/darwin/security/pam.nix
  security.pam.enableSudoTouchIdAuth = true;

  # https://github.com/LnL7/nix-darwin/blob/master/modules/system/activation-scripts.nix
  system.activationScripts.postUserActivation.text = ''
    ${pkgs.dockutil}/bin/dockutil --remove all --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /Applications/Firefox.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /Applications/Element.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /Applications/Telegram.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /Applications/Discord.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /Applications/Visual\ Studio\ Code.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /Applications/kitty.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /System/Applications/Notes.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add ~/Downloads --section others --view fan --display folder --sort dateadded

    # By default, this directory has unsafe permissions.
    # TODO: Capture this with a Nix expression.
    #chmod 700 ~/.gnupg
  '';
  }
