{ config, pkgs, lib, ... }:

{
  imports = [
    ./looking-glass-module.nix
  ];

  boot.extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
  boot.initrd.kernelModules = [ "vfio-pci" "kvmfr" ];
  boot.kernelModules = [ "kvm-amd" "kvmfr" ];
  boot.extraModprobeConfig = ''
    options kvmfr static_size_mb=128
  '';

  boot.kernelParams =
  let
    # 2060
    #gpuIds = "10de:1e89,10de:10f8,10de:1ad8,10de:1ad9";
    # 2070
    gpuIds = "10de:1f02,10de:10f9,10de:1ada,10de:1adb";
    ssdId = "144d:a808";
  in [
    "amd_iommu=on" "iommu=1" "kvm.ignore_msrs=1" "kvm.report_ignored_msrs=0" "kvm_amd.npt=1" "kvm_amd.avic=1"
    #"vfio-pci.ids=${gpuIds}"
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

  boot.initrd.preDeviceCommands = ''
    DEVS="0000:27:00.0 0000:27:00.1 0000:27:00.2 0000:27:00.3"
    for DEV in $DEVS; do
      echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
    done
    modprobe -i vfio-pci
  '';

  # Bind the driver late in the boot process
  systemd.services.bind-vfio = {
    description = "Bind the vfio-pci driver to the 2070";
    wantedBy = [ "multi-user.target" ];
    after = [ "display-manager.service" ];

    script = ''
      DEVS="0000:27:00.0 0000:27:00.1 0000:27:00.2 0000:27:00.3"
      for DEV in $DEVS; do
        if [[ ! -d "/sys/bus/pci/devices/$DEV/driver" ]]; then
          vendor=$(cat /sys/bus/pci/devices/$DEV/vendor)
          device=$(cat /sys/bus/pci/devices/$DEV/device)
          echo $vendor $device > /sys/bus/pci/drivers/vfio-pci/new_id
        fi
      done
    '';
  };

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
    ATTR{wwid}=="eui.0025385b01421a07", SUBSYSTEM=="block", OWNER="babbaj"
    KERNEL=="sd*",  SUBSYSTEM=="block", OWNER="babbaj"
    SUBSYSTEM=="vfio", OWNER="babbaj"

    # take ownership of /dev/kvmfr0
    SUBSYSTEM=="kvmfr", OWNER="babbaj", GROUP="kvm", MODE="0660"
  '';
}
