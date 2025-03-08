{ config, pkgs, lib, ... }:

{
  imports = [
    ./looking-glass-module.nix
  ];

  #boot.extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
  #boot.initrd.kernelModules = [ "vfio-pci" "kvmfr" ];
  boot.initrd.kernelModules = [ "vfio-pci" ];
  #boot.kernelModules = [ "kvm-amd" "kvmfr" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModprobeConfig = ''
    options kvmfr static_size_mb=128
  '';

  boot.kernelPatches = [
    {
      name = "fix-vfio-framebuffer-troll";
      patch = ./fix-vfio-troll.patch;
    }
  ];

  boot.kernelParams =
  let
    # 2070
    gpuIds = "10de:1f02,10de:10f9,10de:1ada,10de:1adb";
  in [
    "amd_iommu=on" "iommu=1" "kvm.ignore_msrs=1" "kvm.report_ignored_msrs=0" "kvm_amd.npt=1" "kvm_amd.avic=1"
    "vfio-pci.ids=${gpuIds}"
    "default_hugepagesz=1G"
  ];

  security.pam.loginLimits = [
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      ovmf.enable = true;
      runAsRoot = false;
      package = pkgs.qemu_kvm; # host cpu only
    };
    onBoot = "ignore";
    onShutdown = "shutdown";
  };

  programs.looking-glass = {
    enable = true;

    settings = {
      app.shmFile = "/dev/kvmfr0";
      input = {
        grabKeyboardOnFocus = true;
        rawMouse = true;
      };
      spice.alwaysShowCursor = true;
      win = {
        fullScreen = true;
        # not recommended with x11
        #jitRender = true;
      };
      egl = {
        # egl filters break the nvidia driver
        #preset = "yay";
        #vsync = true; # this seems to consistently add a frame of latency without fully fixing tearing
        #noSwapDamage = true;
        #noBufferAge = true;
      };
      audio = {
        micDefault = "allow";
        micShowIndicator = false;
      };
    };
  };

  services.udev.extraRules = ''
    # Unprivileged nvme access
    # cat /sys/block/nvme0n1/wwid
    ATTR{wwid}=="nvme.1cc1-324b32323239324837345941-414441544120535838323030504e50-00000001", SUBSYSTEM=="block", OWNER="babbaj"
    KERNEL=="sd*",  SUBSYSTEM=="block", OWNER="babbaj"
    SUBSYSTEM=="vfio", OWNER="babbaj"

    # take ownership of /dev/kvmfr0
    SUBSYSTEM=="kvmfr", OWNER="babbaj", GROUP="kvm", MODE="0660"
  '';
}
