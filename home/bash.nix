{ pkgs, lib, ... }:

{
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      # https://stackoverflow.com/questions/9457233/unlimited-bash-history
      export HISTTIMEFORMAT="[%F %T] "
      export HISTFILE=~/.bash_eternal_history
      PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

      export PATH=$PATH:~/bin:~/.cargo/bin
      #export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${lib.makeLibraryPath [ pkgs.xorg.libXxf86vm ]}
    '';
    historyFileSize = -1;
    historySize = -1;

    shellAliases = {
      pbcopy = "xclip -selection clipboard";
      pbpaste = "xclip -selection clipboard -o";
      cp = "cp --reflink=auto";
    };

    historyControl = [ "ignoredups" ];
  };
}
