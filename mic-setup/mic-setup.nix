{ pkgs, lib, config, ...}:

let
  pw-push-to-talk = pkgs.callPackage ./pw-push-to-talk.nix {};
in
{
  environment.etc = {
      "wireplumber/main.lua.d/90-load-custom-scrips.lua".source = ./90-load-custom-scrips.lua;
      "wireplumber/scripts/link-easyeffects-to-proxy.lua".source = ./link-easyeffects-to-proxy.lua;
      "wireplumber/scripts/reroute-mic-for-cringe-programs.lua".source = ./reroute-mic-for-cringe-programs.lua;

      # TODO: inline this file
      "pipewire/pipewire.conf.d/pw-loopback-nodes.conf".source = ./pw-loopback-nodes.conf;
  };

  systemd.user.services.push-to-talk = {
    description = "Push to talk for specific pipewire nodes";
    after = [ "pipewire.service" ];
    requires = [ "pipewire.service" ];
    partOf = [ "pipewire.service" ];

    path = [ pw-push-to-talk ];
    script = ''
      pw_push_to_talk --release-delay 300 --node EasyEffectsProxySource Pause --node-toggle LiveSynthSource Menu
    '';
  };
}