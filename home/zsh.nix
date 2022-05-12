{ config, pkgs, lib, ... }:

let inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;

    dotDir = ".config/zsh";

    shellAliases = {
      oscfg = "pushd ~/nix-config; darwin-rebuild switch --flake '.#soybook'; popd";
    };

    history = {
      size = 1000000;
      save = 1000000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      share = true;
    };

    sessionVariables = {
      COLORTERM = "truecolor";
      TERM = "xterm-256color";
      EDITOR = "nano";
    };

    profileExtra = ''
      # History
      # If this is set, zsh sessions will append their history list to the
      # history file, rather than replace it.
      setopt appendhistory

      # When searching for history entries in the line editor, do not display
      # duplicates of a line previously found, even if the duplicates are not
      # contiguous.
      setopt histfindnodups

      # Remove superfluous blanks from each command line being added to the
      # history list.
      setopt histreduceblanks

      # Whenever the user enters a line with history expansion, don’t execute
      # the line directly; instead, perform history expansion and reload the
      # line into the editing buffer.
      setopt histverify

      # New history lines are added to the $HISTFILE incrementally (as soon as
      # they are entered), rather than waiting until the shell exits.
      setopt incappendhistory

      # Input / Output
      # Allow comments even in interactive shells.
      setopt interactivecomments

      # .zprofile doesnt seem to get executed anymore
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
  };
}
