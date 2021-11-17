# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, lib, pkgs, ... }:


let
  baseconfig = { allowUnfree = true; };
  master = import <master> { config = baseconfig; };
  stable = import <nixos-stable> { config = baseconfig; }; # 20.09
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware.nix

      # Everything that isn't public
      ./secret.nix

      ./vm-setup.nix

      ./looking-glass-module.nix

      #./steam.nix

      # Home-manager
      <home-manager/nixos>
    ];

  boot.kernelPackages = pkgs.linuxPackages_5_14;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "v4l2loopback" "snd_aloop" "msr" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 video_nr=9 card_label="OBS Virtual Output"
  '';
  boot.initrd.kernelModules = [ "vfio-pci" ];
  boot.kernelParams = [ "noibrs" "noibpb" "nopti" "nospectre_v2" "nospectre_v1" "l1tf=off" "nospec_store_bypass_disable" "no_stf_barrier" "mds=off" "tsx=on" "tsx_async_abort=off" "mitigations=off" ]; # make-linux-fast-again.com
  boot.supportedFilesystems = [ "zfs" ];

  networking.hostName = "nixos"; # Define your hostname.
  networking.hostId = "d5794eb2"; # ZFS requires this

  networking.extraHosts = ''
    127.0.0.1 babbaj.proxy.localhost
    23.156.128.112 2b2t.org
  '';

  time.timeZone = "America/New_York";

  networking.useDHCP = false;
  networking.interfaces.enp34s0.useDHCP = true;
  networking.interfaces.wlp35s0.useDHCP = true;

  networking.networkmanager.enable = true;
  networking.firewall.trustedInterfaces = [ "nocom" ];
  networking.firewall.logRefusedConnections = false; # this has been filling my logs with junk


  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  programs.steam.enable = true;

  programs.java = {
    enable = true;
    package = pkgs.jdk8;
  };
  programs.gnupg.agent.enable = true;
  virtualisation.docker.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    screenSection = ''
      Option         "metamodes" "HDMI-0: nvidia-auto-select +2560+0, DP-0: nvidia-auto-select +0+0 {ForceCompositionPipeline=On}"
    '';
    displayManager.setupCommands = '' # the code above usually doesn't work for some reason
      ${config.hardware.nvidia.package.settings}/bin/nvidia-settings --assign CurrentMetaMode="HDMI-0: nvidia-auto-select +2560+0, DP-0: nvidia-auto-select +0+0 {ForceCompositionPipeline=On}"
    '';
    xrandrHeads = [
      {
        output = "DP-0";
        primary = true;
      }
    ];

    libinput.mouse.middleEmulation = false; # worst troll ever

    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

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

  powerManagement.powerUpCommands = ''${config.hardware.nvidia.package.settings}/bin/nvidia-settings --assign CurrentMetaMode="HDMI-0: nvidia-auto-select +2560+0, DP-0: nvidia-auto-select +0+0 {ForceCompositionPipeline=On}"'';

  # Configure keymap in X11
  services.xserver.layout = "us";

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.vaultwarden.enable = true;

  services.ratbagd.enable = true;

  services.sshd.enable = true;
  
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


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

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
    autoOptimiseStore = true;

    package = pkgs.nix_2_4;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    
    overlays = [
      (self: super:
        {
          # get updates asap
          #discord = master.discord;
          steam = super.steam.override {
            extraProfile = ''
              unset VK_ICD_FILENAMES
              #export VK_ICD_FILENAMES=${config.hardware.nvidia.package.lib32}/share/vulkan/icd.d/nvidia_icd32.json:${config.hardware.nvidia.package}/share/vulkan/icd.d/nvidia_icd.json
              #export VK_ICD_FILENAMES=$(echo /run/opengl-driver{,-32}/share/vulkan/icd.d/* | tr ' ' ':'):/usr/share/vulkan/icd.d/intel_icd.x86_64.json:/usr/share/vulkan/icd.d/intel_icd.i686.json:/usr/share/vulkan/icd.d/lvp_icd.x86_64.json:/usr/share/vulkan/icd.d/lvp_icd.i686.json:/usr/share/vulkan/icd.d/nvidia_icd.json:/usr/share/vulkan/icd.d/nvidia_icd32.json:/usr/share/vulkan/icd.d/radeon_icd.x86_64.json:/usr/share/vulkan/icd.d/radeon_icd.i686.json
              
              export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json:\
              /run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/radeon_icd.i686.json:\
              /run/opengl-driver/share/vulkan/icd.d/amd_icd64.json:/run/opengl-driver-32/share/vulkan/icd.d/amd_icd32.json:\
              /run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json:/run/opengl-driver-32/share/vulkan/icd.d/nvidia_icd.json:\
              /run/opengl-driver/share/vulkan/icd.d/lvp_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/lvp_icd.i686.json
            ''; 
          };

          openvpn = stable.openvpn; # openvpn 2.5 is broken with pia

          looking-glass-client = pkgs.callPackage ./pkgs/looking-glass/looking-glass.nix {};

          gb-backup = pkgs.callPackage ./pkgs/gb-backup/gb.nix {};

          qemu = (super.qemu.override { hostCpuOnly = true; }).overrideAttrs (old: {
            patches = old.patches ++ [
             #./0001-Disable-input-grab-on-startup.patch
             ./0001-cringe-input-patch.patch
            ];

            configureFlags = old.configureFlags ++ [ "--enable-linux-io-uring" ];
            buildInputs = old.buildInputs ++ [ pkgs.liburing ];
          });

          #nix = pkgs.nix_2_4.overrideAttrs ({...}: {
          #    prePatch = ''
          #      substituteInPlace src/nix-build/nix-build.cc \
          #        --replace 'pkgs.runCommandCC or pkgs.runCommand' 'pkgs.runCommand'
          #    '';
          #});

        })
    ];
  };

  environment.systemPackages = with pkgs;
  let
  obs = (wrapOBS {
    plugins = with obs-studio-plugins; [
      looking-glass-obs
      obs-nvfbc
    ];
  });
  obs-autostart = (makeAutostartItem {
    name = "com.obsproject.Studio";
    package = obs;
  }).overrideAttrs ({buildCommand, ...}: {
    buildCommand = buildCommand + "\n" + ''
      substituteInPlace $out/etc/xdg/autostart/com.obsproject.Studio.desktop \
        --replace 'Exec=obs' 'Exec=obs --startreplaybuffer'
    '';
  });

  # basically equivalent to nix-build '<nixpkgs/nixos>' -A vm --arg configuration ./ethminer-vm.nix
  mining-vm = (import <nixpkgs/nixos> { configuration = ./ethminer-vm.nix; }).vm;
  in
  [
    coreutils
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    jetbrains.rider
    vlc
    wireguard
    qbittorrent
    obs
    obs-autostart
    minecraft
    multimc
    steam
    google-chrome
    firefox
    element-desktop
    discord
    go
    binutils
    virt-manager
    git
    clang_12
    llvm_12
    gcc11
    compsize
    tdesktop
    sqlite-interactive
    vscode
    pciutils
    cmake
    gnumake
    pkg-config
    docker-compose
    wget
    openssl
    pv
    smartmontools
    neofetch
    gnupg
    flameshot
    pavucontrol
    zoom-us
    qdirstat
    piper # for the mouse
    direnv
    nix-direnv
    jq
    openvpn
    spotify
    ffmpeg
    linuxPackages.perf
    iotop
    iperf
    gnome3.networkmanagerapplet
    gnome.gnome-tweaks
    psmisc # future installer requires killall
    lepton
    unzip
    p7zip
    unrar
    gparted
    htop
    rlwrap
    wireshark
    mbuffer
    wineWowPackages.staging
    dotnet-sdk_3
    youtube-dl
    usbutils
    lm_sensors
    inetutils
    dmidecode
    i2c-tools
    libreoffice-qt
    gb-backup
    xclip xsel
    handbrake
    ghidra-bin
    depotdownloader
    file
    qtcreator
    gdb
    backblaze-b2
    nvtop
    valgrind
    mpv
    asciinema
    bitwarden
    cargo
    rustc
    rustup
    droidcam
    nixfmt
    libsForQt5.kdenlive
    libsForQt5.okular
    screen
    monero-gui
    xmrig-mo
    ethminer
    mining-vm
  ];

  # for intellij
  environment.etc = with pkgs; {
    "jdk8".source = jdk8;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.babbaj = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "input" "docker" ]; # Enable ‘sudo’ for the user.
  };
  #security.sudo.wheelNeedsPassword = false; # troll face

  home-manager = {
    users.babbaj = {
      imports = [ ./i3.nix ];

      programs.ssh = {
        enable = true;
        matchBlocks.n = {
          hostname = "192.168.69.2";
          user = "root";
        };
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      programs.git = {
        enable = true;
        userName = "Babbaj";
        userEmail = "babbaj45@gmail.com";

        signing = {
          key = "F044309848A07CAC";
          signByDefault = true;
        };
      };

      services.gpg-agent.enable = true;
      services.gpg-agent.pinentryFlavor = "gnome3";

      programs.bash = {
        enable = true;
        bashrcExtra = ''
          PATH=$PATH:~/bin
        '';

        shellAliases = {
          pbcopy = "xclip -selection clipboard";
          pbpaste = "xclip -selection clipboard -o";
          cp = "cp --reflink=auto";
        };

        historyControl = [ "ignoredups" ];
      };

      programs.alacritty = {
        enable = true;

        settings = {
          background_opacity = 0.9;
        };
      };

      programs.fzf.enable = true;
    };

    useUserPackages = true;
    useGlobalPkgs = true;
    verbose = true;
  };
}
