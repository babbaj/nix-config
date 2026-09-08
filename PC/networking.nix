{ ... }:

{
  networking.networkmanager.enable = true;

  networking.firewall.trustedInterfaces = [ "kittens" "vultr" "tailscale0" ];
  networking.firewall.logRefusedConnections = false; # this was filling the logs with junk
  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];

  networking.extraHosts = ''
    127.0.0.1 babbaj.proxy.localhost
    127.0.0.1 normieslayer.proxy.localhost
    192.168.69.69 100010.proxy.local
  '';

  # /etc/hosts is a symlink into the store, so append the mutable extras by
  # replacing it with a real file at activation time.
  system.activationScripts.appendHosts = {
    deps = [ "etc" ];
    text = ''
      hostsSrc=$(realpath /etc/hosts)
      rm /etc/hosts
      cat $hostsSrc > /etc/hosts
      cat /home/babbaj/hosts >> /etc/hosts
    '';
  };

  # loopback-only resolver, purely for the wildcard entries /etc/hosts can't express
  services.dnsmasq = {
    enable = true;
    # Don't pull in the resolvconf-generated /etc/dnsmasq-conf.conf; NetworkManager
    # writes a link-local upstream with a bogus scope id in there which makes dnsmasq
    # refuse to start ("bad interface name"). Upstreams are set explicitly below.
    resolveLocalQueries = false;
    settings = {
      # Keep a bind option: without one dnsmasq binds the wildcard address and would
      # answer on the trusted wireguard/tailscale interfaces.
      bind-interfaces = true;
      listen-address = "127.0.0.1";

      address = [
        "/proxy.blahajwg/192.168.69.1"
      ];

      no-resolv = true;
      server = [ "1.1.1.1" "8.8.8.8" ];
    };
  };

  # Send *.proxy.blahajwg to the local dnsmasq; everything else keeps using the
  # per-link DNS servers NetworkManager/tailscale configure.
  networking.nameservers = [ "127.0.0.1" ];
  services.resolved.settings.Resolve.Domains = [ "~proxy.blahajwg" ];
}
