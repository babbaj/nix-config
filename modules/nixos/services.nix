{ lib, pkgs, ... }:

{
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  services.vaultwarden = {
    enable = true;
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
  systemd.services.stop-2070-fan = {
    description = "Set the fan speed to 0";
    wantedBy = [ "multi-user.target" ];
    after = [ "display-manager.service" ];
    script = ''
      /run/current-system/sw/bin/run-gpu-idle-vm
    '';
  };

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.gui.enable = true;

  services.tailscale.enable = true;

  services.plex.enable = true;
  services.plex.openFirewall = true;


  services.udev.extraRules = ''
    KERNEL=="hidraw*", TAG+="uaccess"
  '';

  hardware.bluetooth.enable = true;

  services.ratbagd.enable = true;
}
