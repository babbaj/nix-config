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
      bep = {
        hostname = "ec2-3-137-153-233.us-east-2.compute.amazonaws.com";
        user = "root";
        identityFile = "/home/babbaj/.ssh/nixos_key.pem";
      };
      b = {
        hostname = "sneed";
        user = "ubuntu";
      };
    };

    extraConfig = ''
      SetEnv TERM=xterm-256color
    '';
  };
}
