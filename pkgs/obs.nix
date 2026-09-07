pkgs:
with pkgs;
let
  obs = wrapOBS {
    plugins = with obs-studio-plugins; [
      looking-glass-obs
    ];
  };

  # Start the replay buffer automatically on login.
  obs-autostart = (makeAutostartItem {
    name = "com.obsproject.Studio";
    package = obs;
  }).overrideAttrs ({ buildCommand, ... }: {
    buildCommand = buildCommand + "\n" + ''
      substituteInPlace $out/etc/xdg/autostart/com.obsproject.Studio.desktop \
        --replace 'Exec=obs' 'Exec=obs --startreplaybuffer'
    '';
  });
in
{
  inherit obs obs-autostart;
}
