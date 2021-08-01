{ config, pkgs, lib, ... }:

{
  boot.kernelModules = [ "kvm-amd"];
  boot.initrd.kernelModules = [ "vfio-pci" ];

  boot.kernelParams = [ "default_hugepagesz=1G" "hugepagesz=1G" "amd_iommu=on" "iommu=1" "kvm.ignore_msrs=1" "kvm_amd.npt=1" "kvm_amd.avic=1" "vfio-pci.ids=10de:1e89,10de:10f8,10de:1ad8,10de:1ad9" ];

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

  programs.looking-glass = {
    enable = true;

    settings = {
      input = {
        grabKeyboardOnFocus = true;
          rawMouse = true;
        };
        spice.alwaysShowCursor = true;
        win.fullScreen = true;
    };
  };

  services.udev.extraRules = ''
    # Unprivileged nvme access
    ATTR{wwid}=="eui.0025385b01421a07", SUBSYSTEM=="block", OWNER="babbaj"
    KERNEL=="sd*",  SUBSYSTEM=="block", OWNER="babbaj"
    SUBSYSTEM=="vfio", OWNER="babbaj"
  '';
}
