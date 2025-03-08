pkgs: with pkgs;
let
  notify-script = writeScript "obs-file-notification.sh" ''
    #!/usr/bin/env bash

    action=$(${libnotify}/bin/notify-send --action="Show in Files" -i com.obsproject.Studio -a "OBS Studio" "Replay Buffer Saved" "$1")
    if [[ "$action" = "0" ]]; then
      nautilus --select "$1"
    fi
  '';

  patch = runCommand "obs-notify-patch.patch" {} ''
    cp ${./obs-notify-patch.patch} $out
    substituteInPlace $out \
      --subst-var-by notify_command "${notify-script}"
  '';

  obs-studio-patched = obs-studio.overrideAttrs({patches, ...}: {
    #patches = patches ++ [ patch ];
  });
  obs = wrapOBS.override({obs-studio = obs-studio-patched;}) {
    plugins = with obs-studio-plugins; [
      looking-glass-obs
      #obs-nvfbc
    ];
  };

  obs-autostart = (makeAutostartItem {
    name = "com.obsproject.Studio";
    package = obs;
  }).overrideAttrs ({buildCommand, ...}: {
    buildCommand = buildCommand + "\n" + ''
      substituteInPlace $out/etc/xdg/autostart/com.obsproject.Studio.desktop \
        --replace 'Exec=obs' 'Exec=obs --startreplaybuffer'
    '';
  });
in {
  patched-obs = obs;
  inherit obs-autostart;
}
