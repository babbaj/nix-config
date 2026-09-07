# VFIO GPU passthrough: bind the 2070 to vfio-pci, run the guest under libvirtd
# and render it on the host through Looking Glass over /dev/kvmfr0.
{ config, pkgs, ... }:

{
  imports = [
    ./looking-glass.nix
  ];

  boot.extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
  boot.initrd.kernelModules = [ "vfio-pci" "kvmfr" ];
  boot.kernelModules = [ "kvm-amd" "kvmfr" ];
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
    in
    [
      "amd_iommu=on"
      "iommu=1"
      "kvm.ignore_msrs=1"
      "kvm.report_ignored_msrs=0"
      "kvm_amd.npt=1"
      "kvm_amd.avic=1"
      "vfio-pci.ids=${gpuIds}"
      "default_hugepagesz=1G"
    ];

  security.pam.loginLimits = [
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      runAsRoot = false;
      package = pkgs.qemu_kvm; # host cpu only
    };
    onBoot = "ignore";
    onShutdown = "shutdown";
  };
  users.users.qemu-libvirtd.extraGroups = [ "kvm" ];

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
      # NOTE: keep this section, even empty — the ini generator emits an [egl]
      # header for it, so deleting it changes looking-glass-client.ini.
      # egl filters break the nvidia driver, so nothing is set here.
      egl = { };
      audio = {
        micDefault = "allow";
        micShowIndicator = false;
      };
    };
  };

  # NOTE: the commented lines below are part of the generated udev rules file,
  # not Nix comments — removing them changes the derivation.
  services.udev.extraRules = ''
    # Unprivileged nvme access
    # cat /sys/block/nvme0n1/wwid
    #ATTR{wwid}=="nvme.1cc1-324b32323239324837345941-414441544120535838323030504e50-00000001", SUBSYSTEM=="block", OWNER="babbaj"
    ATTR{wwid}=="nvme.1cc1-324b32323239324837345941-414441544120535838323030504e50-00000001", SUBSYSTEM=="block", MODE="0666"
    #KERNEL=="sd*",  SUBSYSTEM=="block", OWNER="babbaj"
    SUBSYSTEM=="vfio", MODE="0666"

    # take ownership of /dev/kvmfr0
    SUBSYSTEM=="kvmfr", MODE="0666"
  '';
}
