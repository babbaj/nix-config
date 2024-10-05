{ config, lib, pkgs, modulesPath, ... }:

let
  patchDriver = import ./nvfbc-unlock.nix;
  kernel = config.boot.kernelPackages.kernel;

  nvidia_generic = args: let
    imported = import ("${pkgs.path}/pkgs/os-specific/linux/nvidia-x11/generic.nix") args;
  in
    pkgs.callPackage imported {
      inherit kernel;
      lib32 = (pkgs.pkgsi686Linux.callPackage imported {
        libsOnly = true;
        kernel = null;
      }).out;
    };
in
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  hardware.i2c.enable = true;

  hardware.openrazer = {
    enable = true;
    users = [ "babbaj" ];
  };

  #hardware.nvidia.package = patchDriver config.boot.kernelPackages.nvidiaPackages.stable;
  # 495.46 and above crashes xorg when looking-glass is launched
  #hardware.nvidia.package = patchDriver (nvidia_generic {
  #  version = "495.44";
  #  sha256_64bit = "0j4agxfdswadxkd9hz9j5cq4q3jmhwdnvqclxxkhl5jvh5knm1zi";
  #  settingsSha256 = "0v8gqbhjsjjsc83cqacikj9bvs10bq6i34ca8l07zvsf8hfr2ziz";
  #  persistencedSha256 = "19rv7vskv61q4gh59nyrfyqyqi565wzjbcfddp8wfvng4dcy18ld";
  #});
  #hardware.nvidia.package = patchDriver config.boot.kernelPackages.nvidiaPackages.stable;
  #hardware.nvidia.modesetting.enable = true;

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta;
  hardware.nvidia.open = true;
  boot.extraModprobeConfig = ''
    options nvidia-drm modeset=1
  '';

  hardware.graphics.enable32Bit = true;
  hardware.pulseaudio.support32Bit = true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/7be7dc7e-97f2-43d4-ab33-134dd5f64a71";
      fsType = "btrfs";
      options = [ "compress-force=zstd:1" "noatime" "space_cache=v2" "autodefrag" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/9188-860B";
      fsType = "vfat";
    };

  fileSystems."/mnt/h" =
    { device = "/dev/disk/by-id/ata-WDC_WD10EZEX-00BN5A0_WD-WCC3F4021203-part1";
      fsType = "ext4";
      options = [ "nofail" ];
    };

  # This can't exist when it's using the vfio driver
  fileSystems."/mnt/c" =
    { device = "/dev/disk/by-id/nvme-ADATA_SX8200PNP_2K22292H74YA_1-part3";
      fsType = "ntfs3";
      options = [ "nofail" "noauto" "force" ];
    };

  fileSystems."/mnt/g" =
    { device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_1TB_S3Z8NB0M554645B-part2";
      fsType = "ntfs3";
      options = [ "nofail" ];
    };

  fileSystems."/mnt/n" =
    { device = "/dev/disk/by-id/ata-SPCC_Solid_State_Disk_AA230214S302KG02348";
      fsType = "btrfs";
      options = [ "nofail" "noatime" "compress-force=zstd:3" ];
    };


  swapDevices = [ { device = "/dev/disk/by-uuid/69384c4f-67cd-42d7-ba0b-a54b806f1bc8"; } ];
}
