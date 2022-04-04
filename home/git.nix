{ ... }:

{
  programs.git = {
    enable = true;
    userName = "Babbaj";
    userEmail = "babbaj45@gmail.com";

    signing = {
      key = "F044309848A07CAC";
      signByDefault = true;
    };

    extraConfig = {
      #submodule.recurse = true;
    };

    difftastic.enable = true;
  };
}
