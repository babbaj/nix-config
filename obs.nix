pkgs: with pkgs;
let
  patch = runCommand "obs-notify-patch.patch" {} ''
    cp ${./obs-patch.patch} $out
    substituteInPlace $out \
      --subst-var-by libnotify ${libnotify} \
      --subst-var-by iconpath ${obs-studio}/share/icons/hicolor/128x128/apps/com.obsproject.Studio.png
  '';

  obs-studio-patched = obs-studio.overrideAttrs({patches, ...}: {
    patches = patches ++ [ patch ];
  });
  obs = wrapOBS.override({obs-studio = obs-studio-patched;}) {
    plugins = with obs-studio-plugins; [
      looking-glass-obs
      obs-nvfbc
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
