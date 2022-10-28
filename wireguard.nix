{ config, ... }:

{
  age.secrets.nocomKey.file = ./secrets/nocom-wireguard-key.age;
  age.secrets.hetznerKey.file = ./secrets/hetzner-wireguard-key.age;

  age.identityPaths = [
    "/home/babbaj/.ssh/id_rsa"
  ];

  networking.wireguard.interfaces = {
    nocom = {
      privateKeyFile = config.age.secrets.nocomKey.path;
      ips = [
        "192.168.69.88/24"
      ];
      peers = [
        {
          allowedIPs = [
            "192.168.69.0/24"
          ];
          publicKey = "r+4gwEuOKEXMJEQvM1YX5jc5WHIpjjZGAKW8SkRVyVQ=";
          endpoint = "fiki.dev:14030";
          persistentKeepalive = 25;
        }
      ];
    };

    vultr = {
      privateKeyFile = config.age.secrets.hetznerKey.path;
      ips = [
        "192.168.70.88/24"
      ];
      peers = [
        {
          allowedIPs = [
            "192.168.70.0/24"
          ];
          publicKey = "J3EtsgrqBybYSm8ui4bT14Z8XVehW6xiStsG7q1R+B4=";
          #endpoint = "babbaj.dev:14031";
          endpoint = "45.77.103.113:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
