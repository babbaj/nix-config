{ pkgs, lib, config, modulesPath, ... }:

with lib;
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  config = {
    nixpkgs.config.allowUnfree = true;

    services.qemuGuest.enable = true;

    boot = {
      growPartition = true;
      kernelParams = [ "console=ttyS0" "boot.shell_on_fail" ];
      loader.timeout = 5;
    };

    system.name = "ethminer";

    virtualisation = {
      cores = 2;
      diskSize = 1000; # MB
      memorySize = 2048; # MB

      # TODO: completely stateless
      diskImage = "/tmp/nixos-ethminer.qcow2";

      forwardPorts = [
        # allow ssh to root@localhost -p 2222
        {
          host.port = 2222;
          guest.port = 22;
        }
      ];

      qemu.options = [#lib.mkForce [
        "-nographic"
        "-cpu host"
        "-device vfio-pci,host=0000:28:00.0"
        "-device vfio-pci,host=0000:28:00.1"
        "-device vfio-pci,host=0000:28:00.2"
        "-device vfio-pci,host=0000:28:00.3"
      ];
    };

    
    systemd.services.ethminer = {
      path = [ pkgs.cudatoolkit ];
      description = "ethminer ethereum mining service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        DynamicUser = true;
        ExecStartPre = "${pkgs.ethminer}/bin/ethminer --list-devices";
        Restart = "always";
        RestartSec = 5;
      };

      script = ''
        ${pkgs.ethminer}/bin/ethminer \
          --farm-recheck 200 \
          --report-hashrate \
          --cuda \
          --pool stratum://47hHuiextmkRwsz4KQhvDL1m6BoW8qXax5sGkjDeArq1QGs27VzkGyHNHB3odsdbFmeJxs2z6Ab3HHkGwDtgBqjhNdETj7s.2060-miner:~ethash@gulf.moneroocean.stream:10128;
      '';
    };

    systemd.services.nvidiaoc = 
    let
      settings = config.hardware.nvidia.package.settings;
    in {
      description = "overclock gpu and set fan speed";
      wantedBy = [ "multi-user.target" ];
      after = [ "display-manager.service" ];
      environment = {
        DISPLAY = ":0";
        XAUTHORITY = "/var/run/lightdm/root/:0"; # ~/.Xauthority doesnt work outside of the DE but X is ran with this for -auth and it works
      };
      serviceConfig = {
        ExecStart = "${settings}/bin/nvidia-settings -c :0 -a [gpu:0]/GPUGraphicsClockOffsetAllPerformanceLevels=-500 -a [gpu:0]/GPUMemoryTransferRateOffsetAllPerformanceLevels=1400 -a [gpu:0]/GPUFanControlState=1 -a [fan:0]/GPUTargetFanSpeed=50";
      };
    };

    services.xserver = 
    let
      x11cfg = ''
Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    BoardName      "NVIDIA GeForce RTX 2060"
    BusID          "PCI:0:9:0"
    Screen          0
EndSection

Section "Screen"
    Identifier     "Screen0"
    Device         "Device0"
    DefaultDepth    24
    Option         "AllowEmptyInitialConfiguration" "True"
    Option         "Coolbits" "29"
    SubSection     "Display"
        Depth       24
    EndSubSection
EndSection
      '';
    in
    {
      enable = true;
      videoDrivers = lib.mkOverride 9 [ "nvidia" ];
      desktopManager.plasma5.enable = true;

      serverLayoutSection = ''
        Screen "Screen0"
      '';

      config = lib.mkAfter x11cfg;

      xrandrHeads = [
        {
         output = "HDMI-0";
          primary = true;
        }
      ];
    };
    systemd.suppressedSystemUnits = [
      "sleep.target"
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
    ];

    hardware.nvidia.nvidiaPersistenced = true;

    services.openssh.enable = true;
    services.openssh.permitRootLogin = "yes";

    environment.systemPackages = with pkgs;
      [
        ethminer
        nvtop
        pciutils
        htop
        gwe
      ];

    # we could alternatively hook root or a custom user
    # to some ssh key pair
    users.extraUsers.root.password = ""; # oops
    users.mutableUsers = false;
  };
}
