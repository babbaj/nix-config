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
          ../home/firefox.nix
          ../home/zsh.nix
        ];
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

  # Date and Time
  time.timeZone = "America/New_York";

  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      (self: super:
        {
          dockutil = super.dockutil.overrideAttrs(old: {
              postInstall = ''
                substituteInPlace $out/bin/dockutil \
                    --replace '/usr/bin/python' '${pkgs.python2}/bin/python'
              '';
          });
        })
    ];
  };

  environment.systemPackages = with pkgs; [
      pv
  ];

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
      "pinentry-mac"
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
    ];

    cleanup = "zap";
  };

  # https://github.com/malob/nixpkgs/blob/master/modules/darwin/security/pam.nix
  security.pam.enableSudoTouchIdAuth = true;

  # https://github.com/LnL7/nix-darwin/blob/master/modules/system/activation-scripts.nix
  system.activationScripts.postUserActivation.text = ''
    ${pkgs.dockutil}/bin/dockutil --remove all --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /Applications/Firefox.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /Applications/Element.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /Applications/Discord.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /Applications/Visual\ Studio\ Code.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /System/Applications/Notes.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /System/Applications/Utilities/Terminal.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /System/Applications/System\ Preferences.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add ~/Downloads --section others --view fan --display folder --sort dateadded


    # By default, this directory has unsafe permissions.
    # TODO: Capture this with a Nix expression.
    chmod 700 ~/.gnupg
  '';
  }
