# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, lib, pkgs, ... }:


let
  baseconfig = { allowUnfree = true; };
  master = import <master> { config = baseconfig; };
  stable = import <nixos-stable> { config = baseconfig; }; # 20.09

  patchDriver = import ./nvfbc-unlock.nix;
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

  boot.kernelPackages = pkgs.linuxPackages_5_10;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "v4l2loopback" "snd_aloop" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 video_nr=9 card_label="OBS Virtual Output"
  '';
  boot.initrd.kernelModules = [ "vfio-pci" ];
  boot.kernelParams = [ "noibrs" "noibpb" "nopti" "nospectre_v2" "nospectre_v1" "l1tf=off" "nospec_store_bypass_disable" "no_stf_barrier" "mds=off" "tsx=on" "tsx_async_abort=off" "mitigations=off" ]; # make-linux-fast-again.com
  boot.supportedFilesystems = [ "zfs" ];

  # https://github.com/keylase/nvidia-patch/blob/master/patch-fbc.sh
  hardware.nvidia.package = patchDriver config.boot.kernelPackages.nvidiaPackages.stable;


  #systemd.user.services.obs-replay = {
  #  description = "OBS Replay";
  #  serviceConfig = {
  #    Type = "simple";
  #    ExecStart = "${pkgs.obs-studio}/bin/obs --startreplaybuffer";
  #  };
  # 
  #  wantedBy = [ "gnome-session-initialized.target" ];
  #};

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
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.screenSection = ''
    Option         "metamodes" "HDMI-0: nvidia-auto-select +2560+0, DP-0: nvidia-auto-select +0+0 {ForceCompositionPipeline=On}"
  '';
  services.xserver.libinput.mouse.middleEmulation = false; # worst troll ever

  services.xserver.displayManager.gdm.enable = true;

  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.windowManager.i3 = {
    enable = true;
    package = pkgs.i3-gaps;
    extraPackages = with pkgs; [
      rofi
      dmenu
      i3status
      i3lock
      i3blocks
      dunst
    ];
    extraSessionCommands = ''
      ${pkgs.picom}/bin/picom &
      ${pkgs.hsetroot}/bin/hsetroot -solid '#000000'
    '';
  };

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
    description = "rsync wal logs ${startAt}";
    startAt = "hourly";

    serviceConfig = {
      ExecStart = "${pkgs.rsync}/bin/rsync -av --progress -e '${pkgs.openssh}/bin/ssh' --delete f:/opt/postgres/wal/ /mnt/h/postgreswal/";
    };
  };

  services.postgresql = {
    enable = true;
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
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    
    overlays = [
      (self: super:
        {
          # get updates asap
          discord = master.discord;
          steam = master.steam.override { 
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

          gb-backup = super.gb-backup.overrideAttrs ({...}: {
            version = "master";
            src = pkgs.fetchFromGitHub {
              owner = "leijurv";
              repo = "gb";
              rev = "fa996208d06766bf523686fbe5831628130d80f7"; # August 16
              sha256 = "1vggl8d69sf4z2lmixfndwwd6l9gi0fkkrxga7v4w7a7yr96b1vp";
            };
          });

          qemu = super.qemu.overrideAttrs ({patches ? [], ...}: {
            patches = patches ++ [
             #./0001-Disable-input-grab-on-startup.patch
             ./0001-cringe-input-patch.patch
            ];
          });

          nix = super.nix.overrideAttrs ({...}: {
              prePatch = ''
                substituteInPlace src/nix-build/nix-build.cc \
                  --replace 'pkgs.runCommandCC or pkgs.runCommand' 'pkgs.runCommand'
              '';
          });
        })
    ];
  };

  environment.systemPackages = 
  with pkgs; [
    coreutils
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    jetbrains.rider
    vlc
    wireguard
    qbittorrent
    (wrapOBS {
      plugins = with obs-studio-plugins; [
        looking-glass-obs
        obs-nvfbc
      ];
    })
    minecraft
    multimc
    steam
    google-chrome
    firefox
    element-desktop
    discord
    binutils
    go
    goimports
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
    steam-run-native
    wine
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
    keepassxc
    bitwarden
    cargo
    rustc
    rustup
    droidcam
    libsForQt5.dolphin
    nixfmt
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
          #background_opacity = 0.9;
          background_opacity = 0.5;
        };
      };

      programs.fzf.enable = true;
    };

    useUserPackages = true;
    useGlobalPkgs = true;
    verbose = true;
  };

}
