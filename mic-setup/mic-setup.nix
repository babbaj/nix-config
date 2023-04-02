{ pkgs, lib, config, ...}:

let
  pw-push-to-talk = pkgs.callPackage ./pw-push-to-talk.nix {};
in
{
  # to remap side buttons to keys used for push to talk
  services.input-remapper.enable = true;

  programs.looking-glass.settings.pipewire.recDevice = "MicProxySource";

  systemd.user.services.autoload-input-remapper = {
    description = "Load the input-remapper config";
    wantedBy = [ "default.target" ];
    path = [ pkgs.input-remapper ];
    script = ''
      input-remapper-control --command autoload
    '';
  };

  environment.etc = {
    "wireplumber/main.lua.d/90-load-custom-scrips.lua".text = ''
      load_script("link-easyeffects-to-proxy.lua")
      load_script("reroute-mic-for-cringe-programs.lua")
      load_script("volume.lua")
    '';
    "wireplumber/scripts/link-easyeffects-to-proxy.lua".source = ./link-easyeffects-to-proxy.lua;
    "wireplumber/scripts/reroute-mic-for-cringe-programs.lua".source = ./reroute-mic-for-cringe-programs.lua;
    "wireplumber/scripts/volume.lua".source = ./volume.lua;

    # TODO: inline this file
    "pipewire/pipewire.conf.d/pw-loopback-nodes.conf".source = ./pw-loopback-nodes.conf;
  };

  systemd.user.services.push-to-talk = {
    description = "Push to talk for specific pipewire nodes";
    after = [ "pipewire.service" ];
    bindsTo = [ "pipewire.service" ];
    wantedBy = [ "graphical-session.target" ];

    path = [ pw-push-to-talk ];
    script = ''
      pw_push_to_talk --release-delay 300 \
        --node EasyEffectsProxySource Pause \
        --node-toggle LiveSynthSource Menu
    '';
  };
}
