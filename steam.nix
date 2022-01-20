{ config, lib, pkgs, ... }:

{
  programs.steam.enable = true;

  home-manager.sharedModules = let
    version = "7.0rc3-GE-1";
    proton-ge = fetchTarball {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/Proton-${version}.tar.gz";
      sha256 = "sha256:1nvrbifsbgm2fz9114q3wyzdrm52jnjir3ncjc7inalmdymsmq4g";
    };
  in [
    {
      home.file.proton-ge-custom = {
        recursive = true;
        source = proton-ge;
        target = ".steam/root/compatibilitytools.d/Proton-${version}";
      };
    }
  ];
}
