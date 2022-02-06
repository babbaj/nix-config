{ config, lib, pkgs, modulesPath, ... }:

let
  patchDriver = import ./nvfbc-unlock.nix;
  kernel = config.boot.kernelPackages.kernel;

  pkgsPath = modulesPath + "/../../pkgs";
  nvidia_generic = args: let
    imported = import (pkgsPath + "/os-specific/linux/nvidia-x11/generic.nix") args;
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

  #hardware.nvidia.package = patchDriver config.boot.kernelPackages.nvidiaPackages.stable;
  # 495.46 crashes xorg with looking-glass
  hardware.nvidia.package = patchDriver (nvidia_generic {
    version = "495.44";
    sha256_64bit = "0j4agxfdswadxkd9hz9j5cq4q3jmhwdnvqclxxkhl5jvh5knm1zi";
    settingsSha256 = "0v8gqbhjsjjsc83cqacikj9bvs10bq6i34ca8l07zvsf8hfr2ziz";
    persistencedSha256 = "19rv7vskv61q4gh59nyrfyqyqi565wzjbcfddp8wfvng4dcy18ld";
  });
  hardware.nvidia.modesetting.enable = true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/7be7dc7e-97f2-43d4-ab33-134dd5f64a71";
      fsType = "btrfs";
      options =
        [ "compress-force=zstd:1" "noatime" "space_cache=v2" ]
        ++
        # https://www.reddit.com/r/selfhosted/comments/sgy96t/psa_linux_516_has_major_regression_in_btrfs/
        (if kernel.kernelOlder "5.16" then [ "autodefrag" ]
        else lib.warn "Disabling autodefrag for linux 5.16" []);
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
