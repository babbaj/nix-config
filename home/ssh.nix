{ ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks.n = {
      hostname = "192.168.69.2";
      user = "root";
    };
    extraConfig = ''
      SetEnv TERM=xterm-256color
    '';
  };
}
