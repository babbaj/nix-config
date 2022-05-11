{ pkgs, ... }:

let inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  programs.git = {
    enable = true;
    userName = "Babbaj";
    userEmail = "babbaj45@gmail.com";

    signing = {
      key = if !isDarwin then "F044309848A07CAC" else "0D0F363408CD842A";
      signByDefault = true;
    };

    extraConfig = {
      #submodule.recurse = true;
    };

    #difftastic.enable = true;
  };
}
