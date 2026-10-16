{ config, lib, pkgs, ... }:

let

    mkProtonGE0 = { version, arch ? "",  sha256 }:
    let
     unpacked = pkgs.fetchzip {
        url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}${arch}.tar.gz";
        inherit sha256;
      };
      path = ".steam/root/compatibilitytools.d/${version}";
    in
    { ${path}.source = unpacked; };
    mkProtonGE = { version, sha256 }: mkProtonGE0 { inherit version; inherit sha256; arch = "-x86_64"; };

    inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  home.file = lib.mkIf isLinux (lib.mkMerge [
    (mkProtonGE0 { version = "GE-Proton10-32"; sha256 = "sha256-NxZ4OJUYQdRNQTb62jRET6Ef14LEhynOASIMPvwWeNA="; })
    (mkProtonGE0 { version = "GE-Proton10-34"; sha256 = "sha256-lzPsYYcrp5NoT3B0WFj3o10Z7tXx7xva1wEP3edeuqM="; })
    (mkProtonGE { version = "GE-Proton11-7"; sha256 = "sha256-ftW0vE45v2JsbaYqo/So0ZFfvdtakHX0XEXEE4TdxLk="; })
  ]);
}
