# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:


let
  baseconfig = { allowUnfree = true; };
  unstable = import <nixos-unstable> { config = baseconfig; };
  master = import <master> { config = baseconfig; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware.nix

      # Everything that isn't public
      ./secret.nix

      # Home-manager
      <home-manager/nixos>

      #"${builtins.fetchTarball "https://github.com/danielfullmer/nixos-config/archive/2aad9c4254b4372488606b0d0ebf4b89fbd26042.tar.gz"}/modules/nvidia-vgpu"
    ];

  #hardware.nvidia.vgpu.enable = true;
  #hardware.nvidia.vgpu.unlock.enable = true;

  boot.kernelPackages = unstable.linuxPackages_5_10;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "kvm-amd" ];
  boot.initrd.availableKernelModules = [ "vfio-pci" ];
  # pci ids are probably not necessary anymore
  boot.kernelParams = [ "default_hugepagesz=1G" "hugepagesz=1G" "amd_iommu=on" "iommu=1" "kvm.ignore_msrs=1" "kvm_amd.npt=1" "kvm_amd.avic=1" "vfio-pci.ids=10de:1e89,10de:10f8,10de:1ad8,10de:1ad9" ];
  
  boot.initrd.preDeviceCommands = ''
    DEVS="0000:28:00.0 0000:28:00.1 0000:28:00.2 0000:28:00.3"
    for DEV in $DEVS; do
      echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
    done
    modprobe -i vfio-pci
  '';  
  
  security.pam.loginLimits = [
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; } # unlimited memory limit for vm
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemuOvmf = true;
    qemuRunAsRoot = false;
    onBoot = "ignore";
    onShutdown = "shutdown";
  };

  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0666 babbaj qemu-libvirtd -"
  ];

    systemd.user.services.scream-ivshmem = {
    enable = true;
    description = "Scream";
    serviceConfig = {
      ExecStart = "${pkgs.scream-receivers}/bin/scream-alsa -i virbr0";
      Restart = "always";
      RestartSec = "5";
    };

    wantedBy = [ "default.target" ];
    requires = [ "pulseaudio.service" ];
  };

  networking.firewall.interfaces.virbr0.allowedUDPPorts = [ 4010 ]; # scream

  services.udev.extraRules = ''
    # Unprivileged nvme access
    ATTR{wwid}=="eui.0025385b01421a07", SUBSYSTEM=="block", OWNER="babbaj"
    KERNEL=="sd*",  SUBSYSTEM=="block", OWNER="babbaj"
    SUBSYSTEM=="vfio", OWNER="babbaj"
  '';
  
  boot.supportedFilesystems = [ "zfs" ];

  systemd.user.services.obs-replay = {
    enable = true;
    description = "OBS Replay";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.obs-studio}/bin/obs --startreplaybuffer";
    };
  
    wantedBy = [ "gnome-session-initialized.target" ];
  };

  networking.hostName = "gamer"; # Define your hostname.
  networking.hostId = "d5794eb2"; # ZFS requires this
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "America/New_York";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp34s0.useDHCP = true;
  networking.interfaces.wlp35s0.useDHCP = true;


  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  programs.steam.enable = true;
  programs.java.enable = true;
  programs.gnupg.agent.enable = true;
  virtualisation.docker.enable = true;
  #programs.networkmanager.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.screenSection = ''
    Option         "metamodes" "HDMI-0: nvidia-auto-select +2560+0, DP-0: nvidia-auto-select +0+0 {ForceCompositionPipeline=On}"
  '';


  # Enable the GNOME 3 Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome3.enable = true;
  

  # Configure keymap in X11
  services.xserver.layout = "us";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.ratbagd.enable = true;


  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;


  # Garbage Collection
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    autoOptimiseStore = true;
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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
    };
    
    overlays = [
      (self: super:
        {
          # override with newer version from nixpkgs-unstable
          jetbrains.idea-ultimate = unstable.jetbrains.idea-ultimate;
          jetbrains.clion = unstable.jetbrains.clion;
          jetbrains.goland = unstable.jetbrains.goland;
          obs-studio = unstable.obs-studio;
   
          libratbag = unstable.libratbag; # 0.15 required for logitech g203

          oraclejdk = unstable.oraclejdk;

          looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
            version = "master";
            src = pkgs.fetchFromGitHub {
              owner = "gnif";
              repo = "LookingGlass";
              rev = "168d9890ae36ae09defe265c1120dbc1e543345d"; # April 18
              sha256 = "1zk75izbcga5d1x7ywv232l80rgnx4ws6nyjwss0gq6bybv4ky9i";
              fetchSubmodules =  true;
            };
          
            buildInputs = oldAttrs.buildInputs ++ [ pkgs.xorg.libXi pkgs.xorg.libXScrnSaver pkgs.xorg.libXinerama ];
           
            cmakeFlags = [ "-DENABLE_WAYLAND=no" ];
            NIX_CFLAGS_COMPILE = "-mavx";
          
            patches = (oldAttrs.patches or []) ++ [
             ./0001-Allow-sudo.patch
            ];
          });

          #discord = master.discord;
          wine = unstable.wine;
          spotify-tui = unstable.spotify-tui;

          qemu = super.qemu.overrideAttrs (old: rec {
            patches = (old.patches or []) ++ [
             ./0001-Disable-input-grab-on-startup.patch
            ];
          });
        })
    ];
  };
  

  environment.systemPackages = 
  let
    looking_glass_desktop = pkgs.makeDesktopItem {
      name = "looking-glass-client";
      desktopName = "Looking Glass Client";
      type = "Application";
      icon = "${pkgs.looking-glass-client.src}/resources/lg-logo.png";
      exec = "${pkgs.looking-glass-client}/bin/looking-glass-client input:grabKeyboardOnFocus spice:alwaysShowCursor";
      terminal = "true";
    };
  in with pkgs; [
    looking_glass_desktop

    #home-manager
    coreutils
    looking-glass-client
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    vlc
    wireguard
    qbittorrent
    obs-studio
    minecraft
    steam
    google-chrome
    firefox
    element-desktop
    discord
    go
    goimports
    virt-manager
    libvirt
    git
    binutils
    gcc10
    clang_11
    llvm_11
    compsize
    tdesktop
    sqlite-interactive
    vscode
    pciutils
    cmake
    gnumake
    pkg-config
    docker
    docker-compose
    #jre
    #jdk 
    oraclejdk
    wget
    openssl
    pv
    smartmontools
    neofetch
    gnupg
    flameshot
    scream-receivers
    pavucontrol
    zoom-us
    qdirstat
    piper # for the mouse
    libratbag
    direnv
    nix-direnv
    jq
    openvpn
    spotify-tui
    ffmpeg
    linuxPackages.perf
    iotop
    iperf
    gnome3.networkmanagerapplet
    psmisc # future installer requires killall
    linuxPackages.v4l2loopback
    lepton
    unzip
    p7zip
    gparted
    htop
    rlwrap
    wireshark
    zfs
    mbuffer
    steam-run-native
    wine
    dotnet-netcore
    youtube-dl
    usbutils
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.babbaj = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "input" ]; # Enable ‘sudo’ for the user.
  };
  

  home-manager = {
    users.babbaj = {
      programs.direnv = {
        enable = true;
        enableNixDirenvIntegration = true;
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

      programs.obs-studio = {
        enable = true;
        plugins = with pkgs; [
          obs-v4l2sink
          #obs-v4l2loopback
          #obs-move-transition
        ];
      };
    };

    useUserPackages = true;
    useGlobalPkgs = true;
    verbose = true;
  };

}
