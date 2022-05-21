{ config, pkgs, lib, ... }:

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

    inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  programs.bash = {
    enable = true;
    bashrcExtra = lib.optionalString isDarwin ''
      export PATH=$PATH:~/.local/bin:~/.fig/bin
      . "$HOME/.fig/shell/bashrc.pre.bash"
    '' + ''
      # https://stackoverflow.com/questions/9457233/unlimited-bash-history
      export HISTTIMEFORMAT="[%F %T] "
      export HISTFILE=~/.bash_eternal_history
      PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

      export PATH=$PATH:~/bin:~/.cargo/bin
      #export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${lib.makeLibraryPath [ pkgs.xorg.libXxf86vm ]}
    '';

    initExtra = lib.optionalString isDarwin ''
      . "$HOME/.fig/shell/bashrc.post.bash"
    '';

    profileExtra = lib.optionalString isDarwin ''
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # Fig pre block. Keep at the top of this file.
      . "$HOME/.fig/shell/profile.pre.bash"

      # Fig post block. Keep at the bottom of this file.
      . "$HOME/.fig/shell/profile.post.bash"
    '';

    historyFileSize = -1;
    historySize = -1;

    inherit (config.programs.zsh) shellAliases;

    historyControl = [ "ignoredups" ];
  };
}
