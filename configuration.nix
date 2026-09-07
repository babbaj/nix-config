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
      ./metrics.nix
      #./ups.nix
      #./openrgb.nix
      #./wifi.nix
      ./nix.nix
      ./mic-setup/mic-setup.nix
      ./smb.nix
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

  security.pam.loginLimits = [
    {
      item = "nofile";
      domain = "*";
      type = "soft";
      value = "4096";
    }
  ];

  boot.tmp = {
    useTmpfs = true;
    cleanOnBoot = true;
  };

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

  networking.networkmanager.enable = true;
  networking.firewall.trustedInterfaces = [ "kittens" "vultr" "tailscale0" ];
  networking.firewall.logRefusedConnections = false; # this has been filling my logs with junk
  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];

  # loopback-only resolver, purely for wildcard entries /etc/hosts can't express
  services.dnsmasq = {
    enable = true;
    # don't pull in the resolvconf-generated /etc/dnsmasq-conf.conf; NetworkManager
    # writes a link-local upstream with a bogus scope id in there which makes dnsmasq
    # refuse to start ("bad interface name"). Upstreams are set explicitly below.
    resolveLocalQueries = false;
    settings = {
      # keep a bind option: without one dnsmasq binds the wildcard address and would
      # answer on the trusted wireguard/tailscale interfaces
      bind-interfaces = true;
      listen-address = "127.0.0.1";

      address = [
        "/proxy.blahajwg/192.168.69.1"
      ];

      no-resolv = true;
      server = [ "1.1.1.1" "8.8.8.8" ];
    };
  };

  # send *.proxy.blahajwg to the local dnsmasq, everything else keeps using the
  # per-link DNS servers NetworkManager/tailscale configure
  networking.nameservers = [ "127.0.0.1" ];
  services.resolved.settings.Resolve.Domains = [ "~proxy.blahajwg" ];

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

  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];

    excludePackages = [ pkgs.xterm ];

    #displayManager.lightdm.enable = true;

    logFile = "/var/log/X.0.log"; # lightdm sets the log file to here but gdm does not
  };
  services.libinput.mouse.middleEmulation = false; # worst troll ever


  services.desktopManager.cosmic.enable = true;
  #services.displayManager.cosmic-greeter.enable = true;
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1; # enable clipboard manager

  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  fonts.packages = with pkgs; [
    cantarell-fonts
  ];

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";

  # Enable sound.
  profiles.pipewire.enable = true;

  services.vaultwarden = {
    enable = true;
    config = {
      #ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_ADDRESS = "::";
    };
    backupDir = "/var/backup/vaultwarden";
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
    enable = true;
    package = pkgs.postgresql;
    enableTCPIP = false;
    ensureUsers = [
      {
        name = "babbaj";  # Replace with your actual username
      }
    ];
    ensureDatabases = [ "ocr" ];

    initialScript = pkgs.writeText "backend-initScript" ''
      GRANT ALL PRIVILEGES ON DATABASE "ocr" TO "babbaj";
      GRANT ALL PRIVILEGES ON SCHEMA public TO babbaj;
      GRANT USAGE ON SCHEMA public TO babbaj;
      GRANT CREATE ON SCHEMA public TO babbaj;
    '';
  };

  systemd.services.stop-2070-fan = {
    description = "Set the fan speed to 0";
    wantedBy = [ "multi-user.target" ];
    after = [ "display-manager.service" ];
    script = ''
      /run/current-system/sw/bin/run-gpu-idle-vm
    '';
  };

  # warp-svc
  #systemd.packages = with pkgs; [
  #  cloudflare-warp
  #];

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.gui.enable = true;

  services.tailscale.enable = true;

  # cuckpak
  services.flatpak.enable = true;
  xdg.portal.enable = true;

  hardware.openrazer = {
    enable = true;
    users = [ "babbaj" ];
    batteryNotifier = {
      percentage = 15;
    };
  };

  services.plex.enable = true;
  services.plex.openFirewall = true;

  # broken until https://github.com/NixOS/nixpkgs/pull/461918 is merged into unstable
  #programs.ns-usbloader.enable = true;

  services.udev.extraRules = ''
    KERNEL=="hidraw*", TAG+="uaccess"
  '';

  hardware.bluetooth.enable = true;

  services.ratbagd.enable = true;

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
    jetbrains.idea
    jetbrains.clion
    jetbrains.goland
    jetbrains.rider
    jetbrains.pycharm
    jetbrains.rust-rover
    vscode
    qtcreator
  ];
  dev-tools = [
    zig
    clang_18
    llvm_18
    gcc13
    git
    binutils
    cmake
    gnumake
    ninja
    pkg-config
    go
    perf
    perf-tools
    dotnet-sdk_8
    mono
    gdb
    lldb
    valgrind
    rustc
    cargo
    rustup
    rust-cbindgen
    astyle
    opencode
    opencode-desktop
  ];
  shell-tools = [
    coreutils
    ripgrep
    bat
    wget
    pv
    fastfetch
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
    appimage-run
    eza
    hyperfine
  ];
  cli-tools = [
    fdupes
    duperemove
    squashfsTools
    squashfuse
    #cloudflare-warp # warp-cli
    bind # nslookup and dig
    mediainfo
    compsize
    pciutils
    sqlite-interactive
    smartmontools
    ffmpeg-full
    iperf
    yt-dlp
    usbutils
    lm_sensors
    inetutils
    dmidecode
    i2c-tools
    gnupg
    backblaze-b2
    nvtopPackages.full
    nmap
    unzip
    p7zip
    unrar
    psmisc # future installer requires killall
    gb-backup
    #geekbench
    openssl
    wireguard-tools
    docker-compose
    alsa-utils
    libnotify
    exfatprogs
    graphviz
    gamescope
    wl-clipboard
    television
  ];
  nix-tools = [
    nix-diff
    #nix-top
    nixfmt
    nix-direnv
    direnv
    fh
    nix-alien
  ];
  cosmic-stuff = [
    /*cosmic-ext-applet-caffeine
    #cosmic-ext-applet-clipboard-manager
    cosmic-ext-applet-emoji-selector
    cosmic-ext-applet-external-monitor-brightness
    cosmic-ext-ctl*/
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
  cosmic-stuff ++
  (let
    gpu-vm = (import "${modulesPath}/../" { configuration = ./gpu-idle-vm.nix; system = pkgs.stdenv.hostPlatform.system; }).vm;
  in [
    gpu-vm
    texliveFull
    vlc
    qbittorrent
    prismlauncher
    google-chrome
    ungoogled-chromium
    element-desktop
    discord
    virt-manager
    telegram-desktop
    (flameshot.override {enableWlrSupport = true;})
    pavucontrol
    qdirstat
    piper # for the mouse
    openvpn
    spotify
    networkmanagerapplet
    gnome-tweaks
    gparted
    wireshark
    wineWow64Packages.staging
    #libreoffice-qt
    handbrake
    ghidra-bin
    #depotdownloader
    bitwarden-desktop
    droidcam
    kdePackages.kdenlive
    kdePackages.okular
    monero-gui
    nheko
    #lutris # https://github.com/NixOS/nixpkgs/issues/513245
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
    #soundux
    r2modman
    gnome-calculator
    clonehero
    gnome-system-monitor
    python3
    polychromatic
    parted
    neo4j
    blender
    brave
    firefox
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.ffmpegthumbs
    claude-code
    #bottles # see lutris
    freecad
    slack
  ]);

  # for intellij
  environment.etc = with pkgs; {
    "jdk".source = jdk;
    "jdk8".source = jdk8;
    "jdk11".source = jdk11;
    "jdk17".source = jdk17;
    "jdk25".source = jdk25;
    "zulu8".source = zulu8;
    "jetbrains_jdk".source = jetbrains.jdk;
    #"jetbrains_jdk17".source = jetbrains.jdk-no-jcef-17;
  };
  # for mc dev
  environment.sessionVariables.LD_LIBRARY_PATH = [ "${pkgs.libXxf86vm}" ];
  environment.sessionVariables.__GL_THREADED_OPTIMIZATIONS = "0";
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.babbaj = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "input" "vaultwarden" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };
  #security.sudo.wheelNeedsPassword = false; # troll face
  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';
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
