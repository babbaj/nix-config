{ config, lib, pkgs, modulesPath, ... }:

let
  patchDriver = import ./nvfbc-unlock.nix;
in
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # https://github.com/keylase/nvidia-patch/blob/master/patch-fbc.sh
  hardware.nvidia.package = patchDriver config.boot.kernelPackages.nvidiaPackages.stable;

  fileSystems."/" =
    { device = "/dev/disk/by-id/nvme-ADATA_SX8200PNP_2K22292H74YA-part1";
      fsType = "btrfs";
      options = [ "compress-force=zstd:1" "noatime" "space_cache=v2" "autodefrag" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-id/nvme-ADATA_SX8200PNP_2K22292H74YA-part2";
      fsType = "vfat";
    };
  
  fileSystems."/mnt/h" =
    { device = "/dev/disk/by-id/ata-WDC_WD10EZEX-00BN5A0_WD-WCC3F4021203-part1";
      fsType = "ext4";
    };

  fileSystems."/mnt/c" =
    { device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_500GB_S5H7NS0NB47461B-part4";
      fsType = "ntfs-3g";
    };

  fileSystems."/mnt/g" =
    { device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_1TB_S3Z8NB0M554645B-part2";
      fsType = "ntfs-3g";
    };

  fileSystems."/mnt/d" =
    { device = "/dev/disk/by-id/ata-ST2000DM006-2DM164_Z4Z8WDL5-part2";
      fsType = "btrfs";
      options = [ "compress-force=zstd:3" ];
    };


  swapDevices = [ { device = "/dev/disk/by-id/nvme-ADATA_SX8200PNP_2K22292H74YA-part3"; } ];
}
