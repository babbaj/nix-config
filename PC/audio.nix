{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # needed for the pactl utility some apps rely on
    pulseaudio
    # patchbay
    helvum
    # sound effects
    easyeffects
  ];

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
}
