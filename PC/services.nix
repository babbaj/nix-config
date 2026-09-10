{ lib, pkgs, ... }:

{
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  services.vaultwarden = {
    enable = false;
    config = {
      ROCKET_ADDRESS = "::";
    };
    backupDir = "/var/backup/vaultwarden";
  };
  systemd.services.vaultwarden.serviceConfig.StateDirectoryMode = lib.mkForce "0755";

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings.PasswordAuthentication = false;
  };

  services.gnome.gnome-keyring.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql;
    enableTCPIP = false;
    ensureUsers = [
      { name = "babbaj"; }
    ];
    ensureDatabases = [ "ocr" ];

    initialScript = pkgs.writeText "backend-initScript" ''
      GRANT ALL PRIVILEGES ON DATABASE "ocr" TO "babbaj";
      GRANT ALL PRIVILEGES ON SCHEMA public TO babbaj;
      GRANT USAGE ON SCHEMA public TO babbaj;
      GRANT CREATE ON SCHEMA public TO babbaj;
    '';
  };

  # Spin up the passthrough VM so the second GPU parks its fans (see
  # ./vm/gpu-idle-vm.nix, installed as `run-gpu-idle-vm`).
  #
  # When the 2070 is already claimed by another guest (the libvirt Windows VM)
  # qemu dies with "Could not open '/dev/vfio/N': Device or resource busy",
  # which is expected, not a failure. ExecCondition exiting 1 skips the unit
  # quietly instead of leaving it in the failed state.
  systemd.services.stop-2070-fan = {
    description = "Set the fan speed to 0";
    wantedBy = [ "multi-user.target" ];
    after = [ "display-manager.service" ];
    serviceConfig.ExecCondition = pkgs.writeShellScript "gpu-idle-vm-condition" ''
      set -u

      # All four functions of the 2070 share one iommu group, so checking the
      # group of function 0 covers the whole set passed to the VM.
      dev=0000:27:00.0

      group=$(readlink -f "/sys/bus/pci/devices/$dev/iommu_group" 2>/dev/null)
      if [ -z "$group" ]; then
        echo "$dev has no iommu group; not starting the idle VM"
        exit 1
      fi

      node="/dev/vfio/''${group##*/}"
      if [ ! -e "$node" ]; then
        echo "$node does not exist ($dev not bound to vfio-pci?); not starting the idle VM"
        exit 1
      fi

      # Anything holding the group open (another qemu) makes the VM fail to start.
      for fd in /proc/[0-9]*/fd/*; do
        if [ "$(readlink "$fd" 2>/dev/null)" = "$node" ]; then
          pid=''${fd#/proc/}
          pid=''${pid%%/*}
          echo "$node is in use by pid $pid ($(cat "/proc/$pid/comm" 2>/dev/null)); not starting the idle VM"
          exit 1
        fi
      done

      exit 0
    '';
    script = ''
      /run/current-system/sw/bin/run-gpu-idle-vm
    '';
  };

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.gui.enable = true;

  services.tailscale.enable = true;

  services.plex.enable = false;
  services.plex.openFirewall = true;


  services.udev.extraRules = ''
    KERNEL=="hidraw*", TAG+="uaccess"
  '';

  hardware.bluetooth.enable = true;

  services.ratbagd.enable = true;
}
