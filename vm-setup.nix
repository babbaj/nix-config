{ config, pkgs, lib, ... }:

let
  #halfCores = "0,12,1,13,2,14,3,15,4,16,5,17";
  nonVmCpus = "6,18,7,19,8,20,9,21,10,22,11,23";
  allCores = "0-23";

  qemuHook = pkgs.writeShellScript "qemu" ''
    if [[ $1 == "win10-gpu" ]] && [[ $2 == "prepare" || $2 == "release" || $2 == "started" ]]
    then
      if [[ $2 == "prepare" ]]
      then
        # isolate cores
        systemctl set-property --runtime -- user.slice AllowedCPUs=${nonVmCpus}
        systemctl set-property --runtime -- system.slice AllowedCPUs=${nonVmCpus}
        systemctl set-property --runtime -- init.scope AllowedCPUs=${nonVmCpus}
      elif [[ $2 == "release" ]]
      then
        # remove core isolation
        systemctl set-property --runtime -- user.slice AllowedCPUs=${allCores}
        systemctl set-property --runtime -- system.slice AllowedCPUs=${allCores}
        systemctl set-property --runtime -- init.scope AllowedCPUs=${allCores}
      fi
    fi
  '';
in
{
  boot.kernelModules = [ "kvm-amd"];
  boot.initrd.kernelModules = [ "vfio-pci" ];
  boot.kernelParams = [ 
    "amd_iommu=on" "iommu=1" "kvm.ignore_msrs=1" "kvm.report_ignored_msrs=0" "kvm_amd.npt=1" "kvm_amd.avic=1" "vfio-pci.ids=10de:1e89,10de:10f8,10de:1ad8,10de:1ad9" 
    "default_hugepagesz=1G"
  ];

  security.pam.loginLimits = [
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; } # unlimited memory limit for vm
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemuOvmf = true;
    qemuRunAsRoot = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
  };

  systemd.services.libvirtd.preStart = ''
    mkdir -p /var/lib/libvirt/hooks
    ln -sf ${qemuHook} /var/lib/libvirt/hooks/qemu
  '';

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
