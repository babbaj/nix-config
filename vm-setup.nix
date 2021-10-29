{ config, pkgs, lib, ... }:

{
  boot.kernelModules = [ "kvm-amd"];
  boot.initrd.kernelModules = [ "vfio-pci" ];
  boot.kernelParams = [ 
    "amd_iommu=on" "iommu=1" "kvm.ignore_msrs=1" "kvm.report_ignored_msrs=0" "kvm_amd.npt=1" "kvm_amd.avic=1" "vfio-pci.ids=10de:1e89,10de:10f8,10de:1ad8,10de:1ad9" 
    "default_hugepagesz=1G"
  ];

  security.pam.loginLimits = [
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemuOvmf = true;
    qemuRunAsRoot = false;
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
      egl.vsync = true;
    };
  };

  services.udev.extraRules = ''
    # Unprivileged nvme access
    ATTR{wwid}=="eui.0025385b01421a07", SUBSYSTEM=="block", OWNER="babbaj"
    KERNEL=="sd*",  SUBSYSTEM=="block", OWNER="babbaj"
    SUBSYSTEM=="vfio", OWNER="babbaj"
  '';
}
