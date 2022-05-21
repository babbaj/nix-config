{ pkgs, ... }:

let inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  # Autostart easyeffects daemon
  services.easyeffects.enable = isLinux;
}
