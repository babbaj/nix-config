{ pkgs, lib, ... }:

let
  genCdAliases = len:
    let
      strRepeat0 = str: acc: n: if n == 0 then str else strRepeat0 (acc + str) acc (n - 1);
      strRepeat = str: n: strRepeat0 str str n;
      cdStr = "c" + strRepeat "d" len;
      pathStr = strRepeat "../" len;

      genCdAliases0 = depth: attrs:
        if depth <= 1 then attrs
        else (genCdAliases0 (depth - 1) attrs) //
          { ${builtins.substring 0 (depth + 1) cdStr} = ("cd " + builtins.substring 0 ((depth - 1) * 3) pathStr); };
    in
    genCdAliases0 len {};
in
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
    } // genCdAliases 100;

    historyControl = [ "ignoredups" ];
  };
}
