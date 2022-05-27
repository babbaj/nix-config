{ pkgs, ...}:

let
  mkLaunchdConfig = name: ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <dict>
        <key>SuccessfulExit</key>
        <false/>
      </dict>
      <key>Label</key>
      <string>activate-${name}-tunnel</string>
      <key>ProgramArguments</key>
      <array>
        <string>${pkgs.wireguard-tools}/bin/wg-quick</string>
        <string>up</string>
        <string>${name}</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>StandardErrorPath</key>
      <string>/var/log/${name}.err</string>
      <key>EnvironmentVariables</key>
      <dict>
        <key>PATH</key>
        <string>${pkgs.wireguard-go}/bin</string>
      </dict>
    </dict>
    </plist>
  '';
in
{
  environment.launchDaemons = {
    nocom = {
      text = mkLaunchdConfig "nocom";
      target = "activate-nocom-tunnel.plist";
    };
    hetzner = {
      text = mkLaunchdConfig "hetzner";
      target = "activate-hetzner-tunnel.plist";
    };
  };
}