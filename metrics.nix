{ config, pkgs, lib, ... }:

{
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    exporters.node.enable = true;

    scrapeConfigs = [{
      job_name = "nixos";
      static_configs = [{
        targets = [
          "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
        ];
      }];
    }];
  };

  services.grafana.enable = true;
}
