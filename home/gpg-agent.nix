{ pkgs, lib, ... }:

let inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  services.gpg-agent = lib.mkIf isLinux {
    enable = true;
    pinentryFlavor = "gnome3";
  };
}
