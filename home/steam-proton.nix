{ config, lib, pkgs, ... }:

let
    mkProtonGE = { version, sha256 }:
    let
     unpacked = fetchTarball {
        url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
        inherit sha256;
      };
      path = ".steam/root/compatibilitytools.d/${version}";
    in
    { ${path}.source = unpacked; };

    inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  home.file = lib.mkIf isLinux (lib.mkMerge [
    (mkProtonGE { version = "Proton-7.0rc3-GE-1"; sha256 = "sha256:1nvrbifsbgm2fz9114q3wyzdrm52jnjir3ncjc7inalmdymsmq4g"; })
    (mkProtonGE { version = "GE-Proton7-37"; sha256 = "sha256:0wgdp8vxpbi66fh4r7g4kvxbyfyqglzjmfgh8bm4wfns8ikwii9z"; })
    (mkProtonGE { version = "GE-Proton7-55"; sha256 = "sha256:0szrza88ic0rx6y90y1s655faxfz7lq24315zw0xl107gvszw8p8"; })
    (mkProtonGE { version = "GE-Proton8-2"; sha256 = "sha256:1n6zs00fngrbjp761drmrvr1gk8fn8x85npayyh70rfs72dmv6hc"; })
    (mkProtonGE { version = "GE-Proton8-13"; sha256 = "sha256:0nj7m55hag0cvjs40lfsj3627gqlrknps5xdg8f2m1rmdhfgky65"; })
    (mkProtonGE { version = "GE-Proton8-16"; sha256 = "sha256:0r11sf7pljw5rqlgbnkl6lkw2cpqyvd16vjp8f64hqjx4ma3947g"; })
    (mkProtonGE { version = "GE-Proton9-1"; sha256 = "sha256:1zc1c1scqnpxsfxj6micpgvn317k7gd48aya8m3c5v6nbi377nm1"; })
  ]);
}
