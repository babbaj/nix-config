{ config, lib, pkgs, ... }:

let inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  programs.i3status-rust = lib.mkIf isLinux {
    enable = true;
    bars = {
      default = {
        blocks = [
          {
            block = "music";
            player = "spotify";
            buttons = [ "play" "prev" "next" ];
          }
          {
            block = "disk_space";
            path = "/";
            alias = "/";
            info_type = "available";
            unit = "GB";
            interval = 60;
            warning = 20.0;
            alert = 10.0;
          }
          {
            block = "memory";
            display_type = "memory";
            format_mem = "{mem_used} /{mem_total}";
            format_swap = "{swap_used} /{swap_total}";
          }
          {
            block = "cpu";
            interval = 1;
          }
          {
            block = "load";
            interval = 1;
            format = "{1m}";
          }
          { block = "sound"; }
          {
            block = "time";
            interval = 1;
            format = "%a %m/%d %r";
          }
        ];
        icons = "none";
        theme = "space-villain";
      };
    };
  };
}
