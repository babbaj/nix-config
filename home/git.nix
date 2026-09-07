{ pkgs, ... }:

let inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Babbaj";
      user.email = "babbaj45@gmail.com";

      alias = {
        # Pretty graph
        graph = "! git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'";
        # Shows the latest commit with more detail
        latest = "show HEAD --summary";
        # Prints all aliases
        aliases = "! git config --get-regexp '^alias\\.' | sed -e 's/^alias\\.//' -e 's/\\ /\\ =\\ /' | grep -v '^aliases' | sort";
        # Quick view of all recents commits
        oneline = "log --pretty=oneline";
        activity = "! git for-each-ref --sort=-committerdate refs/heads/ "
                  + "--format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'";
      };

      #submodule.recurse = true;
      #fetch.recurseSubmodules = true;
    };

    signing = {
      key = if !isDarwin then "F044309848A07CAC" else "0D0F363408CD842A";
      signByDefault = true;
    };

    #difftastic.enable = true;
  };
}
