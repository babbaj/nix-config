{ pkgs, lib, ... }:

let inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  programs.kitty = {
    enable = true;

    settings = {
      background_opacity = "0.8";
      #scrollback_lines = "-1";
      scrollback_lines = "1000000"; # infinite scrollback was a mistake
    };
    keybindings = {
      # Pause key (push to talk)
      "0xff13" = "discard_event";
    };

    # Dummy package so that we can install kitty with Homebrew.
    package = lib.mkIf isDarwin (pkgs.runCommandLocal "" { } "mkdir $out");
  };
}
