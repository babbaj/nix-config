{ ... }:

{
  services.samba-wsdd.enable = false;
  networking.firewall.allowedTCPPorts = [
   #5357 # wsdd
  ];
  networking.firewall.allowedUDPPorts = [
    #3702 # wsdd
  ];
  services.samba = {
    enable = false;
    securityType = "user";
    shares = {
      public = {
        path = "/mnt/n/share";
        available = "yes";
        browseable = "yes";
        public = "yes";
        writable = "yes";

        "read only" = "no";
        "guest ok" = "yes";
        comment = "Public samba share.";

        createMask = "0777";
        directoryMask = "0777";
      };
    };
    extraConfig = ''
      [global]
      log level = 3
    '';
    openFirewall = true;
  };
}
