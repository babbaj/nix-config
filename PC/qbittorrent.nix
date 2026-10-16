# qBittorrent (headless, web UI) confined to a network namespace whose only
# route out is a WireGuard tunnel to Mullvad. If the tunnel is down the netns
# has no connectivity at all, so nothing can leak over the normal uplink.
# This is independent of the Mullvad app: it doesn't need to be connected, and
# connecting it doesn't affect this (the tunnel just rides inside it).
#
# The WireGuard key is registered on the Mullvad account as device "amused elk";
# ips below are the addresses Mullvad assigned to that key.
#
# Web UI: http://127.0.0.1:8080 on the host, proxied into the namespace.
{ config, lib, pkgs, ... }:

let
  ns = "mullvad";
  dataDir = "/mnt/sneed/qbittorrent";
  webuiPort = 8080;

  # Mullvad's in-tunnel resolver, so DNS for trackers also goes through the VPN.
  resolvConf = pkgs.writeText "resolv.conf" ''
    nameserver 10.64.0.1
  '';
in
{
  age.secrets.mullvadQbittorrentKey.file = ../secrets/mullvad-qbittorrent-key.age;

  systemd.services."netns-${ns}" = {
    description = "Network namespace for ${ns}";
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "${pkgs.iproute2}/bin/ip netns add ${ns}"
        "${pkgs.iproute2}/bin/ip -n ${ns} link set lo up"
      ];
      ExecStop = "${pkgs.iproute2}/bin/ip netns del ${ns}";
    };
  };

  # The UDP socket stays in the init namespace (so it uses the normal uplink);
  # only the interface, and therefore the default route, moves into the netns.
  networking.wireguard.interfaces.${ns} = {
    interfaceNamespace = ns;
    privateKeyFile = config.age.secrets.mullvadQbittorrentKey.path;
    ips = [
      "10.133.159.150/32"
      "fc00:bbbb:bbbb:bb01:d:0:5:9f96/128"
    ];
    peers = [
      {
        # us-bos-wg-101
        publicKey = "oxJ2PIqrQOmS0uiyXvnxT64E1uZnjZDWPbP/+APToAE=";
        endpoint = "149.40.50.98:51820";
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        persistentKeepalive = 25;
      }
    ];
  };

  systemd.services."wireguard-${ns}" = {
    bindsTo = [ "netns-${ns}.service" ];
    after = [ "netns-${ns}.service" ];
  };

  services.qbittorrent = {
    enable = true;
    profileDir = dataDir;
    inherit webuiPort;
    # Note: the module rewrites qBittorrent.conf from this on every start, so
    # settings changed in the web UI that aren't pinned here survive only until
    # the next restart.
    serverConfig = {
      LegalNotice.Accepted = true;
      BitTorrent.Session = {
        DefaultSavePath = "${dataDir}/downloads";
        # Redundant with the netns, but makes libtorrent refuse to fall back
        # to anything else if the interface ever goes missing.
        Interface = ns;
        InterfaceName = ns;
      };
      # The web UI is only reachable through the proxy below, which connects
      # from inside the netns, so every request already arrives as localhost.
      Preferences.WebUI.LocalHostAuth = false;
    };
  };

  systemd.services.qbittorrent = {
    bindsTo = [ "wireguard-${ns}.service" ];
    after = [ "wireguard-${ns}.service" ];
    unitConfig.RequiresMountsFor = dataDir;
    serviceConfig = {
      NetworkNamespacePath = "/run/netns/${ns}";
      BindReadOnlyPaths = [ "${resolvConf}:/etc/resolv.conf" ];
      # Both of these are unix sockets into resolvers in the init namespace,
      # which would resolve names outside the tunnel.
      InaccessiblePaths = [
        "-/run/nscd"
        "-/run/systemd/resolve/io.systemd.Resolve"
        "-/run/systemd/resolve/io.systemd.Resolve.Monitor"
      ];
      # Group-writable so babbaj (in the qbittorrent group) can manage downloads.
      UMask = "0002";
      # /mnt/sneed is nofail, so tmpfiles can run before it's mounted; create
      # the directories here instead, after RequiresMountsFor.
      ExecStartPre = lib.mkBefore [
        "+${pkgs.coreutils}/bin/install -d -o qbittorrent -g qbittorrent -m 2775 ${dataDir} ${dataDir}/downloads"
      ];
    };
  };

  # Host-side listener for the web UI; the proxy process itself runs inside
  # the netns, where qBittorrent is listening on its own loopback.
  systemd.sockets.qbittorrent-webui = {
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "127.0.0.1:${toString webuiPort}" ];
  };

  systemd.services.qbittorrent-webui = {
    requires = [ "qbittorrent.service" ];
    after = [ "qbittorrent.service" ];
    serviceConfig = {
      ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${toString webuiPort}";
      NetworkNamespacePath = "/run/netns/${ns}";
      DynamicUser = true;
      PrivateTmp = true;
    };
  };

  users.users.babbaj.extraGroups = [ "qbittorrent" ];
}
