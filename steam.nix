{ config, lib, pkgs, ... }:

{
  programs.steam.enable = true;


  home-manager.sharedModules = let
    version = "6.15-GE-2";
    proton-ge = fetchTarball {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/Proton-${version}.tar.gz";
      sha256 = "1f2plw3d0da9ybj72jqc3aqwl5zc6smr4ng0gx61qbfphypl372w";
    };
  in [
    {
      home.file.proton-ge-custom = {
        recursive = false;
        source = proton-ge;
        target = ".steam/root/compatibilitytools.d/Proton-${version}";
      };
    }
  ];
}
