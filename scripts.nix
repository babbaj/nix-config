{ config, lib, pkgs, ... }:

{
  systemd.user.services.update-sky =
  let config = pkgs.writeText "mapcrafter-config" ''
    output_dir = /tmp/mapcrafter-output

    [world:world]
    input_dir = /tmp/skyexport/world

    [map:world]
    name = SkyMasons
    world = world
    rotations = top-left top-right bottom-right bottom-left
    texture_size = 16

    [map:world_top_down]
    name = SkyMasons top down
    world = world
    render_view = topdown
    texture_size = 16
  '';

  script = pkgs.writeScript "skycache-update.sh" ''
    #!${pkgs.stdenv.shell}
    set -e

    function cleanup {
        echo "Removing /tmp dirs"
        rmdir --ignore-fail-on-non-empty $skycache
        rm -r /tmp/skyexport /tmp/mapcrafter-output
    }
    trap cleanup EXIT
    rsyncargs="-rpt" # recursive, perms, time

    echo 'yay'
    dirname="skycache-$(date +%s)"
    skycache="/home/babbaj/skycache/$dirname"
    mkdir $skycache

    rsync $rsyncargs n:/opt/slave/skymason/ $skycache
    rsync $rsyncargs $skycache ovh:/root/skycache/ #backup

    mkdir /tmp/skyexport
    echo "Running exporter with $skycache"
    java -jar /home/babbaj/SkyCacheExporter/build/libs/SkyCacheExporter-1.0-SNAPSHOT-standalone.jar $skycache /tmp/skyexport # TODO: package the exporter

    mkdir /tmp/mapcrafter-output

    echo 'Running mapcrafter'
    mapcrafter -c ${config} -j 24

    rsync $rsyncargs -v --progress --delete /tmp/mapcrafter-output/ ovh:/root/skyrender/
  '';
  in {
    enable = false;
    description = "Download chunk cache and update mapcrafter render";
    startAt = "hourly";
    path = with pkgs; [ rsync openssh mapcrafter jdk11 ];
    serviceConfig = {
      ExecStart = "${script}";
    };
  };

  systemd.user.services.backup-headless = {
    description = "Backup headless database";
    path = with pkgs; [ rsync openssh ];
    startAt = "daily";
    script = ''
      mkdir /home/babbaj/headless-backup || true
      rsync -v --progress n:/opt/slave/headless.db /home/babbaj/headless-backup/headless-$(date +"%m-%d-%Y").db
    '';
  };

  systemd.user.services.skycache-rsync = {
    #enable = false;
    description = "Hourly skycache backup";
    path = with pkgs; [ rsync openssh ];
    startAt = "hourly";
    script = ''
      set -e
      set -x

      dirname="skycache-$(date +%s)"
      tmpdir=/tmp/$dirname

      rsync -rpt n:/opt/slave/skymason/ $tmpdir
      mkdir /home/babbaj/skycache || true
      mv $tmpdir /home/babbaj/skycache/$dirname
    '';
  };
}
