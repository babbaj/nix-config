{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.profiles.pipewire;
in
{
  options.profiles.pipewire.enable = mkEnableOption "Enable the PipeWire audio/video daemon instead of PulseAudio";
  options.profiles.pipewire.lowlatency.enable = mkEnableOption "Enable low-latency audio configuration for PipeWire";

  config = mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        # needed for pactl utility some apps might rely on
        pulseaudio
        # patchbay
        helvum
        # sound effects
        easyeffects
      ];
      # https://nixos.wiki/wiki/PipeWire
      hardware.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;

        #config.pipewire = {
        #  "context.properties" = {
        #    #"link.max-buffers" = 64;
        #    "link.max-buffers" = 16; # version < 3 clients can't handle more than this
        #    "log.level" = 2; # https://docs.pipewire.org/page_daemon.html
        #    #"default.clock.rate" = 48000;
        #    #"default.clock.quantum" = 1024;
        #    #"default.clock.min-quantum" = 32;
        #    #"default.clock.max-quantum" = 8192;
        #    #
        #  };
        #  "context.objects" = [
        #    {
        #      # A default dummy driver. This handles nodes marked with the "node.always-driver"
        #      # property when no other driver is currently active. JACK clients need this.
        #      factory = "spa-node-factory";
        #      args = {
        #        "factory.name"     = "support.node.driver";
        #        "node.name"        = "Dummy-Driver";
        #        "priority.driver"  = 8000;
        #      };
        #    }
        #  ];
        #};
      };
    })
    (mkIf (!cfg.enable) {
      sound.enable = true;
      hardware.pulseaudio = {
        enable = true;
        package = pkgs.pulseaudioFull;
        support32Bit = true;
      };
    })
  ];
}
