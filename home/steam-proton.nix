{ config, lib, pkgs, ... }:

let
    version = "7.0rc3-GE-1";
    proton-ge = fetchTarball {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/Proton-${version}.tar.gz";
      sha256 = "sha256:1nvrbifsbgm2fz9114q3wyzdrm52jnjir3ncjc7inalmdymsmq4g";
    };
    path = "~/.steam/root/compatibilitytools.d/Proton-${version}";

    inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  # For some reason a normal symlink doesn't work and recursive symlinking on every activation is too slow
  home.activation.proton-activation = lib.mkIf isLinux (lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ ! -d ${path} ]]; then
      cp -r --reflink=auto ${proton-ge} ${path}
    fi
  '');
}
