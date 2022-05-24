{ pkgs, lib, ... }:

let inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
in
{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      n = {
        hostname = "192.168.69.2";
        user = "root";
      };
      h = {
        hostname = "babbaj.dev";
        user = "root";
      };
      f = {
        hostname = "fiki.dev";
        user = "nocom";
        port = 14022;
      };
      pc = lib.mkIf isDarwin {
        hostname = "192.168.69.88";
        user = "babbaj";
      };
      m = lib.mkIf isLinux {
        hostname = "192.168.69.89";
        user = "babbaj";
      };
    };

    extraConfig = ''
      SetEnv TERM=xterm-256color
    '';
  };
}
