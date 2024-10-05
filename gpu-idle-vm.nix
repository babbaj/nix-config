{ pkgs, lib, config, modulesPath, ... }:

with lib;
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  nixpkgs.config.allowUnfree = true;

  services.qemuGuest.enable = true;

  boot = {
    growPartition = true;
    kernelParams = [ "console=ttyS0" "boot.shell_on_fail" ];
    loader.timeout = 5;
  };

  system.name = "gpu-idle";

  virtualisation = {
    cores = 2;
    diskSize = 1000; # MB
    memorySize = 2048; # MB

    # TODO: completely stateless?
    diskImage = "/tmp/nixos-gpu-idle.qcow2";

    forwardPorts = [
      # allow ssh to root@localhost -p 2222
      {
        host.port = 2222;
        guest.port = 22;
      }
    ];

    qemu.options = [
      "-nographic"
      "-cpu host"
      "-device vfio-pci,host=0000:27:00.0"
      "-device vfio-pci,host=0000:27:00.1"
      "-device vfio-pci,host=0000:27:00.2"
      "-device vfio-pci,host=0000:27:00.3"
    ];

    # Don't know why this breaks xorg
    qemu.virtioKeyboard = false;
  };

  systemd.services.nvidia-fan =
  let
    nvidia = config.hardware.nvidia.package;
  in {
    #enable = false;
    description = "Set the fan speed to 0";
    wantedBy = [ "multi-user.target" ];
    after = [ "display-manager.service" ];
    path = [ nvidia.bin nvidia.settings ];
    environment = {
      DISPLAY = ":0";
      XAUTHORITY = "/var/run/lightdm/root/:0"; # ~/.Xauthority doesnt work outside of the DE but X is ran with this for -auth and it works
    };
    script = ''
      nvidia-settings -c :0 -a [gpu:0]/GPUFanControlState=1 -a [fan:0]/GPUTargetFanSpeed=0
    '';
  };

  hardware.nvidia.open = true;

  services.xserver =
  let
    x11cfg = ''
Section "Device"
  Identifier     "Device0"
  Driver         "nvidia"
  VendorName     "NVIDIA Corporation"
  BoardName      "NVIDIA GeForce RTX 2070"
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

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  environment.systemPackages = with pkgs;
    [
      nvtopPackages.full
      pciutils
      htop
      gwe
    ];

  # we could alternatively hook root or a custom user
  # to some ssh key pair
  users.extraUsers.root.password = ""; # oops
  users.mutableUsers = false;
}
