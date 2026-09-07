{ config, pkgs, lib, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
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
      #export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${lib.makeLibraryPath [ pkgs.libXxf86vm ]}
    '';

    profileExtra = lib.optionalString isDarwin ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    historyFileSize = -1;
    historySize = -1;

    inherit (config.programs.zsh) shellAliases;

    historyControl = [ "ignoredups" ];
  };
}
