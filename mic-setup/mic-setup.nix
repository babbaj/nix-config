{ pkgs, lib, config, ...}:

let
  pw-push-to-talk = pkgs.callPackage ./pw-push-to-talk.nix {};
  pipewire-autolink = pkgs.callPackage ./pipewire-autolink.nix {};
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

  systemd.user.services.push-to-talk = {
    description = "Push to talk for specific pipewire nodes";
    after = [ "pipewire.service" ];
    bindsTo = [ "pipewire.service" ];
    wantedBy = [ "graphical-session.target" ];

    path = [ pw-push-to-talk ];
    script = ''
      pw_push_to_talk --release-delay 300 \
        --node EasyEffectsProxySource KEY_PAUSE \
        --node-toggle LiveSynthSource KEY_MENU
    '';
  };

  systemd.user.services.pw-autolink = {
    description = "Automatically manage specific pipewire links";
    after = [ "pipewire.service" ];
    bindsTo = [ "pipewire.service" ];
    wantedBy = [ "graphical-session.target" ];

    path = [ pipewire-autolink ];
    script = ''
      pipewire-autolink \
        --delete-in steam \
        --connect LiveSynthSource steam \
        --connect SteamProxySource steam \
        --connect easyeffects_source SteamProxySink \
        --connect easyeffects_source EasyEffectsProxySink
    '';
  };
}
