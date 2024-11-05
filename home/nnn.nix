{ pkgs, ... }:

{
  home.packages = let
    patched = (pkgs.nnn.override({ withNerdIcons = true; }))
      .overrideAttrs({...}: { patches = [ ../nnn-patch.diff ]; });
    wrapped = pkgs.writeShellScriptBin "nnn" ''
      export NNN_PLUG="f:finder;o:fzopen;p:preview-tui;d:dragdrop;z:fzplug"
      ${patched}/bin/nnn -a -e -P p "$@"
    '';
    unwrapped = pkgs.writeShellScriptBin "nnn-unwrapped" ''
      ${patched}/bin/nnn "$@"
    '';
  in
  [ wrapped unwrapped ];

  programs.zsh.shellAliases = {
    n = "nnn";
  };

  programs.zsh.initExtra = ''
    nnn () {
      # Block nesting of nnn in subshells
      [ "''${NNNLVL:-0}" -eq 0 ] || {
          echo "nnn is already running"
          return
      }

      export NNN_TMPFILE="''${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

      command nnn "$@"

      [ ! -f "$NNN_TMPFILE" ] || {
          . "$NNN_TMPFILE"
          rm -f -- "$NNN_TMPFILE" > /dev/null
      }
    }
  '';
}
