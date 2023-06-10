{ config, lib, pkgs, ... }:

let
    mkProtonGEScript = { version, sha256 }:
    let
     unpacked = fetchTarball {
        url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
        inherit sha256;
      };
      path = "~/.steam/root/compatibilitytools.d/${version}";
    in
    ''
      if [[ ! -d ${path} ]]; then
        cp -r --reflink=auto ${unpacked} ${path}
      fi
    '';

    inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  # For some reason a normal symlink doesn't work and recursive symlinking on every activation is too slow
  home.activation.proton-activation = lib.mkIf isLinux (lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${mkProtonGEScript { version = "Proton-7.0rc3-GE-1"; sha256 = "sha256:1nvrbifsbgm2fz9114q3wyzdrm52jnjir3ncjc7inalmdymsmq4g"; }}
    ${mkProtonGEScript { version = "GE-Proton7-37"; sha256 = "sha256:0wgdp8vxpbi66fh4r7g4kvxbyfyqglzjmfgh8bm4wfns8ikwii9z"; }}
    ${mkProtonGEScript { version = "GE-Proton7-55"; sha256 = "sha256:0szrza88ic0rx6y90y1s655faxfz7lq24315zw0xl107gvszw8p8"; }}
    ${mkProtonGEScript { version = "GE-Proton8-2"; sha256 = "sha256:1n6zs00fngrbjp761drmrvr1gk8fn8x85npayyh70rfs72dmv6hc"; }}
  '');
}
