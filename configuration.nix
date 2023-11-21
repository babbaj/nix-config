# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware.nix
      ./wireguard.nix
      ./vm-setup.nix
      ./scripts.nix
      ./pipewire.nix
      #./metrics.nix
      ./openrgb.nix
      #./wifi.nix
      ./nix.nix
      ./mic-setup/mic-setup.nix
      ./ups.nix
    ];


  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "v4l2loopback" "snd_aloop" "msr" "zenpower" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
    zenpower
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 video_nr=9 card_label="OBS Virtual Output"
  '';
  boot.initrd.kernelModules = [ "vfio-pci" ];
  boot.kernelParams = [ "noibrs" "noibpb" "nopti" "nospectre_v2" "nospectre_v1" "l1tf=off" "nospec_store_bypass_disable" "no_stf_barrier" "mds=off" "tsx=on" "tsx_async_abort=off" "mitigations=off" ]; # make-linux-fast-again.com
  #boot.supportedFilesystems = [ "zfs" ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
  };

  boot.tmpOnTmpfs = true;
  boot.cleanTmpDir = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  #memflow.kvm.enable = true;

  networking.hostName = "nixos"; # Define your hostname.
  networking.hostId = "d5794eb2"; # ZFS requires this

  networking.extraHosts = ''
    127.0.0.1 babbaj.proxy.localhost
    127.0.0.1 normieslayer.proxy.localhost
    192.168.69.69 100010.proxy.local
  '';

  system.activationScripts.appendHosts = {
    deps = [ "etc" ];
    text = ''
      hostsSrc=$(realpath /etc/hosts)
      rm /etc/hosts
      cat $hostsSrc > /etc/hosts
      cat /home/babbaj/hosts >> /etc/hosts
    '';
  };

  time.timeZone = "America/New_York";

  networking.useDHCP = false;
  networking.interfaces.enp34s0.useDHCP = true;
  #networking.interfaces.wlp35s0.useDHCP = true;

  networking.networkmanager.enable = true;
  networking.firewall.trustedInterfaces = [ "kittens" "vultr" ];
  networking.firewall.logRefusedConnections = false; # this has been filling my logs with junk
  networking.firewall.allowedTCPPorts = [
    51680
  ];
  networking.firewall.allowedUDPPorts = [
    51680
  ];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  programs.steam.enable = true;

  programs.java = {
    enable = true;
    #package = pkgs.jdk8;
  };
  programs.gnupg.agent.enable = true;

  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];

    excludePackages = [ pkgs.xterm ];

    /*screenSection = ''
      Option         "metamodes" "HDMI-0: nvidia-auto-select +2560+0, DP-0: nvidia-auto-select +0+0 {ForceCompositionPipeline=On}"
    '';

    displayManager.setupCommands = '' # the code above usually doesn't work for some reason
      ${config.hardware.nvidia.package.settings}/bin/nvidia-settings --assign CurrentMetaMode="HDMI-0: nvidia-auto-select +2560+0, DP-0: nvidia-auto-select +0+0 {ForceCompositionPipeline=On}"
    '';*/
    xrandrHeads = [
      {
        output = "DP-0";
        primary = true;
      }
    ];

    libinput.mouse.middleEmulation = false; # worst troll ever

    displayManager.gdm = {
      #enable = true;
      wayland = false; # gdm keeps using wayland when xorg is selected
    };
    displayManager.lightdm.enable = true;
    desktopManager.gnome.enable = true;
    #desktopManager.plasma5.enable = true;

    logFile = "/var/log/X.0.log"; # lightdm sets the log file to here but gdm does not

    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      extraPackages = with pkgs; [
        rofi
        dmenu
        i3status
        i3lock
      ];
      extraSessionCommands = ''
        ${pkgs.picom}/bin/picom &
        ${pkgs.hsetroot}/bin/hsetroot -solid '#000000'
      '';
    };
  };

  fonts.fonts = with pkgs; [
    cantarell-fonts
  ];

  # Configure keymap in X11
  services.xserver.layout = "us";

  # Enable sound.
  profiles.pipewire.enable = true;

  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_ADDRESS = "0.0.0.0";
    };
    backupDir = "/var/lib/bitwarden_rs/backup";
  };
  systemd.services.vaultwarden.serviceConfig.StateDirectoryMode = lib.mkForce "0755";

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings.PasswordAuthentication = false;
  };

  services.gnome.gnome-keyring.enable = true;

  systemd.user.services.wal-rsync = rec {
    enable = false;
    description = "rsync wal logs ${startAt}";
    startAt = "hourly";

    serviceConfig = {
      ExecStart = "${pkgs.rsync}/bin/rsync -av --progress -e '${pkgs.openssh}/bin/ssh' --delete f:/opt/postgres/wal/ /mnt/h/postgreswal/";
    };
  };

  services.postgresql = {
    enable = false;
    package = pkgs.postgresql_12;
    enableTCPIP = false;
    dataDir = "/opt/postgres/base/data";
    settings = {
      restore_command = "${pkgs.gzip}/bin/gzip -d < /mnt/h/postgreswal/%f.gz > %p";
      hot_standby = "on";
      max_standby_archive_delay = "-1";
      max_standby_streaming_delay = "-1";
    };
  };

  # warp-svc
  #systemd.packages = with pkgs; [
  #  cloudflare-warp
  #];

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;

  # cuckpak
  services.flatpak.enable = true;
  xdg.portal.enable = true;

  hardware.openrazer = {
    enable = true;
    users = [ "babbaj" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

  # Garbage Collection
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings.auto-optimise-store = true;

    #package = pkgs.nix_2_4;
  };

  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs;
  let
  #glib is cringe https://github.com/GNOME/glib/blob/bc0d62424579f507f8d7af13bd29b6d86723f65f/gio/gdesktopappinfo.c#L2498-L2523
  fake-xterm = pkgs.runCommand "xterm-imposter" {} ''
    mkdir -p $out/bin
    ln -s ${pkgs.kitty}/bin/kitty $out/bin/xterm
  '';

  ides = [
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    jetbrains.rider
    jetbrains.pycharm-professional
    vscode
    qtcreator
  ];
  dev-tools = [
    zig_0_9
    clang_16
    llvm_16
    gcc13
    git
    binutils
    cmake
    gnumake
    ninja
    pkg-config
    #go
    go_1_19
    linuxPackages.perf
    perf-tools
    #dotnet-sdk_3
    dotnet-sdk
    mono
    gdb
    lldb
    valgrind
    rustc
    cargo
    rustup
    rust-cbindgen
    astyle
  ];
  shell-tools = [
    coreutils
    ripgrep
    bat
    wget
    pv
    neofetch
    jq
    iotop
    htop
    rlwrap
    mbuffer
    file
    xclip xsel
    asciinema
    tmux
    xxd
  ];
  cli-tools = [
    fdupes
    duperemove
    squashfsTools
    squashfuse
    #cloudflare-warp # warp-cli
    bind # nslookup and dig
    mediainfo
    lepton # used by gb
    compsize
    pciutils
    sqlite-interactive
    smartmontools
    ffmpeg_5-full
    iperf
    yt-dlp
    usbutils
    lm_sensors
    inetutils
    dmidecode
    i2c-tools
    gnupg
    backblaze-b2
    nvtop
    nmap
    unzip
    p7zip
    unrar
    psmisc # future installer requires killall
    gb-backup
    #geekbench
    openssl
    xmrig-mo
    wireguard-tools
    docker-compose
    alsa-utils
    libnotify
  ];
  nix-tools = [
    nix-diff
    nix-top
    nixfmt
    nix-direnv
    direnv
  ];
  obs-stuff = import ./obs.nix pkgs;
  in
  ides ++
  dev-tools ++
  shell-tools ++
  cli-tools ++
  nix-tools ++
  [
    obs-stuff.patched-obs
    obs-stuff.obs-autostart
  ] ++
  [
    texlive.combined.scheme-full
    vlc
    qbittorrent
    minecraft
    prismlauncher
    google-chrome
    ungoogled-chromium
    element-desktop
    discord
    virt-manager
    tdesktop
    flameshot
    pavucontrol
    zoom-us
    qdirstat
    piper # for the mouse
    openvpn
    spotify
    networkmanagerapplet
    gnome.gnome-tweaks
    gparted
    wireshark
    wineWowPackages.staging
    #libreoffice-qt
    handbrake
    ghidra-bin
    #depotdownloader
    bitwarden
    droidcam
    libsForQt5.kdenlive
    libsForQt5.okular
    monero-gui
    nheko
    lutris
    xsecurelock
    #gpu-screen-recorder
    #gpu-screen-recorder-gtk
    gimp
    nixos-artwork.wallpapers.simple-dark-gray # dark gray background
    fake-xterm
    gnomeExtensions.gsconnect
    mumble
    audacity
    mangohud
  ];

  #security.wrappers.looking-glass-ptrace = {
  #  owner = "babbaj";
  #  group = "babbaj";
  #  capabilities = "CAP_SYS_PTRACE=ep";
  #  source = "${pkgs.looking-glass-client}/bin/looking-glass-client";
  #};

  # for intellij
  environment.etc = with pkgs; {
    "jdk".source = jdk;
    "jdk8".source = jdk8;
    "jdk11".source = jdk11;
    "jdk17".source = jdk17;
    "zulu8".source = zulu8;
  };
  # for mc dev
  environment.sessionVariables.LD_LIBRARY_PATH = [ "${pkgs.xorg.libXxf86vm}" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.babbaj = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "input" "vaultwarden" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };
  #security.sudo.wheelNeedsPassword = false; # troll face
  programs.zsh.enable = true;

  home-manager = {
    users.babbaj = {
      imports = [
        ./home/home.nix
      ];
      home.stateVersion = config.system.stateVersion;
    };

    useUserPackages = true;
    useGlobalPkgs = true;
    verbose = true;
  };
}
