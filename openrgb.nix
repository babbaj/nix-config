{ config, pkgs, ... }:

{
  systemd.services.rgb-server = {
    script = "${pkgs.openrgb}/bin/openrgb --server";
    wantedBy = [ "multi-user.target" ]; 
  };

  environment.systemPackages = with pkgs; [
    openrgb
    (writeScriptBin "rgb-white" "openrgb --color FF7878")
    (writeScriptBin "rgb-off" "openrgb --color 0")
  ];
}
