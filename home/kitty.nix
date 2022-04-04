{ ... }:

{
  programs.kitty = {
    enable = true;

    settings = {
      background_opacity = "0.8";
      scrollback_lines = "-1";
    };
    keybindings = {
      # Pause key (push to talk)
      "0xff13" = "discard_event";
    };
  };
}
