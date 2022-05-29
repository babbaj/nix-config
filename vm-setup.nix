{ config, pkgs, lib, ... }:

{
  imports = [
    ./looking-glass-module.nix
  ];

  boot.kernelModules = [ "kvm-amd"];
  boot.initrd.kernelModules = [ "vfio-pci" ];
  boot.kernelParams =
  let
    gpuIds = "10de:1e89,10de:10f8,10de:1ad8,10de:1ad9";
    ssdId = "144d:a808";
  in [
    "amd_iommu=on" "iommu=1" "kvm.ignore_msrs=1" "kvm.report_ignored_msrs=0" "kvm_amd.npt=1" "kvm_amd.avic=1"
    "vfio-pci.ids=${gpuIds}"
    #"pcie_acs_override=downstream,multifunction"
    "default_hugepagesz=1G"
  ];

  /*boot.kernelPatches = [
    {
      name = "acs-override-patch";
      patch = pkgs.fetchurl {
        name = "acs-override-patch.patch";
        url = https://aur.archlinux.org/cgit/aur.git/plain/add-acs-overrides.patch?h=linux-vfio&id=85ceebfa8ff5bf51483df3e27ebf9222cb860d12;
        sha256 = "sha256-uQvnt5ZSvmH31QaRAA9qjHWiQNwu7iZnto2YT2dYP3c=";
      };
    }
  ];*/

  security.pam.loginLimits = [
    #{ domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
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
      input = {
        grabKeyboardOnFocus = true;
        rawMouse = true;
      };
      spice.alwaysShowCursor = true;
      win = {
        fullScreen = true;
        jitRender = true;
      };
      egl = {
        preset = "yay";
        vsync = true; # this seems to consistently add a frame of latency without fully fixing tearing
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
    ATTR{wwid}=="eui.0025385b01421a07", SUBSYSTEM=="block", OWNER="babbaj"
    KERNEL=="sd*",  SUBSYSTEM=="block", OWNER="babbaj"
    SUBSYSTEM=="vfio", OWNER="babbaj"
  '';
}
