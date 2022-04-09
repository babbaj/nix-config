{ config, pkgs, ... }:

{
  systemd.services.rgb-server = {
    script = "${pkgs.openrgb} --server";
    wantedBy = [ "multi-user.target" ]; 
  };
}
