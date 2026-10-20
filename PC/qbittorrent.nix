# qBittorrent (headless, web UI at http://127 .0.0.1:8080).
#
# Downloads go to a mergerfs pool over both SSDs. New files fill sneed first and
# only spill onto feed once sneed is down to minfreespace; the disks stay
# independent bcachefs filesystems, so losing one only loses the files on it.
{ lib, pkgs, ... }:

let
  # Profile (config, resume data, .torrent files) stays on one disk.
  dataDir = "/mnt/sneed/qbittorrent";
  poolDir = "/mnt/torrents";
  # Order matters: with category.create=ff new files go to the first branch
  # with room. The sneed branch is also the original single-disk save path, so
  # torrents added before the pool existed keep working from there.
  poolBranches = [
    "/mnt/sneed/qbittorrent/downloads"
    "/mnt/feed/qbittorrent/downloads"
  ];
  torrentingPort = 51413;
in
{
  # Both disks are nofail, so make sure each branch is mounted and exists
  # before mergerfs assembles them; otherwise it would silently pool the
  # empty mountpoint directory on the root filesystem.
  systemd.services.qbittorrent-pool-branches = {
    description = "Create mergerfs branch directories for ${poolDir}";
    unitConfig.RequiresMountsFor = poolBranches;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/install -d -o qbittorrent -g qbittorrent -m 2775 ${lib.concatStringsSep " " poolBranches}";
    };
  };

  system.fsPackages = [ pkgs.mergerfs ];

  fileSystems.${poolDir} = {
    device = lib.concatStringsSep ":" poolBranches;
    fsType = "fuse.mergerfs";
    noCheck = true;
    options = [
      "nofail"
      "x-systemd.requires=qbittorrent-pool-branches.service"
      "fsname=torrents"
      "allow_other"
      # New files go to the first branch (in order) with more than minfreespace.
      "category.create=ff"
      "minfreespace=20G"
      # If a disk fills mid-write anyway, move the file to the other branch.
      "moveonenospc=true"
      # libtorrent 2 does disk I/O through mmap, which needs page caching on.
      "cache.files=partial"
      "dropcacheonclose=true"
    ];
  };

  services.qbittorrent = {
    enable = true;
    profileDir = dataDir;
    webuiPort = 8080;
    inherit torrentingPort;
    # Note: the module rewrites qBittorrent.conf from this on every start, so
    # settings changed in the web UI that aren't pinned here survive only until
    # the next restart.
    serverConfig = {
      LegalNotice.Accepted = true;
      BitTorrent.Session = {
        DefaultSavePath = poolDir;
        # Reserve each file's full size up front, so a file that won't fit in
        # sneed's remaining space fails over to feed immediately (moveonenospc)
        # rather than halfway through the download.
        Preallocation = true;
        # Seed everything at once instead of a handful of active torrents.
        QueueingSystemEnabled = false;
      };
      Preferences.WebUI = {
        # Loopback only: kittens/vultr/tailscale0 are trusted interfaces, so
        # the firewall alone wouldn't keep the web UI private.
        Address = "127.0.0.1";
        LocalHostAuth = false;
      };
    };
  };

  # Incoming peer connections. The web UI port deliberately stays closed, which
  # is why this isn't services.qbittorrent.openFirewall (that opens both).
  networking.firewall.allowedTCPPorts = [ torrentingPort ];
  networking.firewall.allowedUDPPorts = [ torrentingPort ];

  systemd.services.qbittorrent = {
    unitConfig.RequiresMountsFor = [ dataDir poolDir ];
    serviceConfig = {
      # Group-writable so babbaj (in the qbittorrent group) can manage downloads.
      UMask = "0002";
      # /mnt/sneed is nofail, so tmpfiles can run before it's mounted; create
      # the profile directory here instead, after RequiresMountsFor.
      ExecStartPre = lib.mkBefore [
        "+${pkgs.coreutils}/bin/install -d -o qbittorrent -g qbittorrent -m 2775 ${dataDir}"
      ];
    };
  };

  users.users.babbaj.extraGroups = [ "qbittorrent" ];
}
