{ pkgs, ...}:

{
  #imports = [ ./wg-quick.nix ];
  #disabledModules = [ "modules/services/wg-quick.nix" ];
  networking.wg-quick.interfaces = {
    nocom = {
      address = [ "192.168.69.89/32" ];
      privateKeyFile = "/Users/babbaj/nocom.key";
      peers = [{
        publicKey = "tQFBf1YlSZO/jzkvkqpYsbp5we9j87TSox0DY/oozzI=";
        allowedIPs = [ "192.168.69.0/24" ];
        endpoint = "sneed:14030";
      }];
    };
    vultr = {
      address = [ "192.168.70.90/32" ];
      privateKeyFile = "/Users/babbaj/vultr.key";
      peers = [{
        publicKey = "J3EtsgrqBybYSm8ui4bT14Z8XVehW6xiStsG7q1R+B4=";
        allowedIPs = [ "192.168.70.0/24" ];
        endpoint = "45.77.103.113:51820";
      }];
    };
  };
}
