{ pkgs, lib, config, ...}:

{
  environment.etc = {
      "wireplumber/main.lua.d/90-load-custom-scrips.lua".source = ./90-load-custom-scrips.lua;
      "wireplumber/scripts/link-easyeffects-to-proxy.lua".source = ./link-easyeffects-to-proxy.lua;
      "wireplumber/scripts/reroute-mic-for-cringe-programs.lua".source = ./reroute-mic-for-cringe-programs.lua;

      # TODO: inline this file
      "pipewire/pipewire.conf.d/pw-loopback-nodes.conf".source = ./pw-loopback-nodes.conf;
  };
}
