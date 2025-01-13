{ pkgs, ... }:

{
  home.packages = let
    patched = (pkgs.nnn.override({ withNerdIcons = true; }))
      .overrideAttrs({...}: { patches = [ ../nnn-patch.diff ]; });
    wrapped = pkgs.writeShellScriptBin "nnn" ''
      export NNN_PLUG="f:finder;o:fzopen;p:preview-tui;d:dragdrop;z:fzplug"
      ${patched}/bin/nnn -a -e -P p "$@"
    '';
    unwrapped = pkgs.runCommand "nnn-unwrapped" {} ''
      mkdir -p $out/bin
      ln -s ${patched}/bin/nnn $out/bin/nnn-unwrapped
      ln -s ${patched}/share $out/share
    '';
    in
    [ wrapped unwrapped ];

  programs.zsh.shellAliases = {
    n = "nnn";
  };

  programs.zsh.initExtra = ''
    # https://github.com/jarun/nnn/wiki/Basic-use-cases#configure-cd-on-quit
    nnn () {
      # Block nesting of nnn in subshells
      [ "''${NNNLVL:-0}" -eq 0 ] || {
          echo "nnn is already running"
          return
      }

      command nnn "$@"

      NNN_TMPFILE="''${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
      [ ! -f "$NNN_TMPFILE" ] || {
          . "$NNN_TMPFILE"
          rm -f -- "$NNN_TMPFILE" > /dev/null
      }
    }
  '';
}
