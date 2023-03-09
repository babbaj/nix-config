{ pkgs, ... }:

let
  mpv-osc-modern-src = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/maoiscat/mpv-osc-modern/e232eb99bbc3bd57e5ee9100535011d6051bd2d2/modern.lua";
    sha256 = "sha256-Pnn/KZpIT2I79u4coveBlAY0c+NNcq/x1RpQ1xSNq/c=";
  };
  mpv-osc-modern = pkgs.runCommand "mpv-osc-modern" {
    passthru.scriptName = "modern.lua";
  } ''
    install -Dm644 ${mpv-osc-modern-src} $out/share/mpv/scripts/modern.lua
  '';
in
{
  programs.mpv = {
    enable = true;
    scripts = [
      mpv-osc-modern
    ];
    config = {
      osc = "no";
    };
    profiles.Idle = {
      profile-cond= ''p["idle-active"]'';
      profile-restore = "copy-equal";
      title= "' '";
      keepaspect = "no";
      background = 1;
    };
  };
  xdg.configFile."mpv/fonts/material-design-iconic-font.ttf".source = "${pkgs.fetchurl {
    url = "https://github.com/maoiscat/mpv-osc-modern/raw/e232eb99bbc3bd57e5ee9100535011d6051bd2d2/Material-Design-Iconic-Font.ttf";
    sha256 = "sha256-GKRb4uy2bOIXw7vM8hn4vcBdx21hpuY2cxhu/Rx82ho=";
  }}";
}
