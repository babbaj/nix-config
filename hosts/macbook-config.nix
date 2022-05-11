{ config, pkgs, ... }:

{
  imports = [
    ../nix.nix
  ];

  home-manager = {
      users.babbaj = {
        home.enableNixpkgsReleaseCheck = true;
        imports = [
          ../home/ssh.nix
          ../home/direnv.nix
          ../home/git.nix
          ../home/kitty.nix
          ../home/fzf.nix
          ../home/firefox.nix
        ];
      };
      useUserPackages = true;
      useGlobalPkgs = true;
      verbose = true;
  };

  networking.computerName = "soybook";
  networking.hostName = "soybook";
  networking.localHostName = "soybook";

  # The gnupg agent configuration that comes with home-manager doesn't work on
  # macOS.
  programs.gnupg.agent = { 
    enable = true; 
    enableSSHSupport = true; 
  };

  users.nix.configureBuildUsers = true;

  services.nix-daemon.enable = true;

  # Dock
  system.defaults.dock.wvous-tl-corner = 2; # Top Left → Mission Control
  system.defaults.dock.wvous-tr-corner = 13; # Top Right → Lock Screen

  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";

  # Date and Time
  time.timeZone = "America/New_York";

  # List Homebrew packages that we want to manage. Some Nix packages of MacOS
  # applications aren't mature. Homebrew must be installed out-of-band.
  homebrew = {
    enable = true;

    taps = [
      # defaults
      "homebrew/cask"
      "homebrew/cask-versions"
      "homebrew/core"
    ];

    brews = [
      # TODO: package newest version with nix
      # currently have to manually install from the releases page on github
      #"dockutil"
      "pinentry-mac"
    ];

    casks = [
      "bitwarden"
      "discord"
      "element"
      "firefox"
      "launchcontrol"
      "steam"
      "visual-studio-code"
      "kitty"
    ];

    #cleanup = "zap";
  };

  # https://github.com/LnL7/nix-darwin/blob/master/modules/system/activation-scripts.nix
  system.activationScripts.postUserActivation.text = ''
    /usr/local/bin/dockutil --remove all --no-restart
    /usr/local/bin/dockutil --add /Applications/Firefox.app --no-restart
    /usr/local/bin/dockutil --add /Applications/Element.app --no-restart
    /usr/local/bin/dockutil --add /Applications/Discord.app --no-restart
    /usr/local/bin/dockutil --add /Applications/Visual\ Studio\ Code.app --no-restart
    /usr/local/bin/dockutil --add /System/Applications/Notes.app --no-restart
    /usr/local/bin/dockutil --add /System/Applications/Utilities/Terminal.app --no-restart
    /usr/local/bin/dockutil --add /System/Applications/System\ Preferences.app --no-restart
    /usr/local/bin/dockutil --add ~/Downloads --section others --view fan --display folder --sort dateadded


    # By default, this directory has unsafe permissions.
    # TODO: Capture this with a Nix expression.
    chmod 700 ~/.gnupg
  '';
  }
