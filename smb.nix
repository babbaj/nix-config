{ config, lib, pkgs, modulesPath, ... }:

{
  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      hosts allow = 192.168.70. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
    '';

    shares = {
      test = {
        path = "/home/babbaj/samba";
        "read only" = "no";
        browseable = "yes";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

    };
  };
}
