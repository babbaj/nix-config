{ config, pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelModules = [ "v4l2loopback" "snd_aloop" "msr" "zenpower" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
    zenpower
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 video_nr=9 card_label="OBS Virtual Output"
  '';

  # make-linux-fast-again.com
  boot.kernelParams = [
    "noibrs"
    "noibpb"
    "nopti"
    "nospectre_v2"
    "nospectre_v1"
    "l1tf=off"
    "nospec_store_bypass_disable"
    "no_stf_barrier"
    "mds=off"
    "tsx=on"
    "tsx_async_abort=off"
    "mitigations=off"
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
  };

  boot.tmp = {
    useTmpfs = true;
    cleanOnBoot = true;
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  security.pam.loginLimits = [
    {
      item = "nofile";
      domain = "*";
      type = "soft";
      value = "4096";
    }
  ];
}
