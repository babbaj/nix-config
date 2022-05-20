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

    hetzner = {
      privateKeyFile = config.age.secrets.hetznerKey.path;
      ips = [
        "192.168.70.88/24"
      ];
      peers = [
        {
          allowedIPs = [
            "192.168.70.0/24"
          ];
          publicKey = "vy2XBTSC9leNunwHK69NZeA3GTlyDU0CQMKAFxwmEkk=";
          endpoint = "babbaj.dev:14031";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
