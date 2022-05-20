{ ... }:

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
    };

    extraConfig = ''
      SetEnv TERM=xterm-256color
    '';
  };
}
