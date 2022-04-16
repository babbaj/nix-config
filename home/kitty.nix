{ ... }:

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
  };
}
