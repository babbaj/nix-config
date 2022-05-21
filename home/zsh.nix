{ config, pkgs, lib, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  genCdAliases = len:
    let
      strRepeat0 = str: acc: n: if n == 0 then str else strRepeat0 (acc + str) acc (n - 1);
      strRepeat = str: n: strRepeat0 str str n;
      alias = strRepeat "." len;
      pathStr = strRepeat "../" len;

      genCdAliases0 = depth: attrs:
        if depth <= 1 then attrs
        else (genCdAliases0 (depth - 1) attrs) //
          { ${builtins.substring 0 depth alias} = ("cd " + builtins.substring 0 ((depth - 1) * 3) pathStr); };
    in
    genCdAliases0 len {};
in
{
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;

    dotDir = ".config/zsh";

    shellAliases = lib.mkMerge [
      rec {
        oscfg = "pushd ~/nix-config; darwin-rebuild switch --flake '.#soybook'; popd";
        ls      = "${pkgs.exa}/bin/exa --color=auto --group-directories-first --classify";
        lst     = "${ls} --tree";
        la      = "${ls} --all";
        ll      = "${ls} --all --long --header --group";
        llt     = "${ll} --tree";
        tree    = "${ls} --tree";

        cdtemp  = "cd `mktemp -d`";
        rm      = "rm -Iv";
        df      = "df -h";
        #zreload = "export ZSH_RELOADING_SHELL=1; source $ZDOTDIR/.zshenv; source $ZDOTDIR/.zshrc; unset ZSH_RELOADING_SHELL";
        zreload = "omz reload";

        b2 = "${pkgs.backblaze-b2}/bin/backblaze-b2";
      }
      (lib.mkIf (!isDarwin) {
        pbcopy = "xclip -selection clipboard";
        pbpaste = "xclip -selection clipboard -o";
        cp = "cp --reflink=auto";
      })
      (genCdAliases 100)
     ];

    history = {
      size = 100000000;
      save = 100000000;
      ignoreDups = true;
      share = true;
      extended = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "per-directory-history" # ctrl+g to switch between global and local
        "ripgrep" # adds completion for ripgrep
        "safe-paste"
        "sudo" # press escape twice
        "copybuffer" # ctrl+o
      ];
      extraConfig = ''
        export HISTORY_START_WITH_GLOBAL=true
      '';
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
    '' + lib.optionalString isDarwin ''
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # Fig pre block. Keep at the top of this file.
      . "$HOME/.fig/shell/zprofile.pre.zsh"

      # Fig post block. Keep at the bottom of this file.
      . "$HOME/.fig/shell/zprofile.post.zsh"
    '';

    initExtra = ''
      ## Keybindings section
      # Navigate words with ctrl+arrow keys
      bindkey '^[Oc' forward-word               #
      bindkey '^[Od' backward-word              #
      bindkey '^[[1;3D' backward-word           # alt+left
      bindkey '^[[1;3C' forward-word            # alt+right
      bindkey '^H' backward-kill-word           # delete previous word with ctrl
      bindkey '^[[Z' undo                       # Shift+tab undo last action
    '' + lib.optionalString isDarwin ''
      . "$HOME/.fig/shell/zshrc.post.zsh"
    '';

    initExtraFirst = lib.mkIf isDarwin ''
      export PATH=$PATH:~/.local/bin:~/.fig/bin
      . "$HOME/.fig/shell/zshrc.pre.zsh"
    '';
  };
}
