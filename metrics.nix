{ config, pkgs, lib, ... }:

{
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    exporters.node.enable = true;

    scrapeConfigs = [
      {
        job_name = "nixos";
        static_configs = [{
          targets = [
            "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
          ];
        }];
      }
      {
        job_name = "nginxlog";
        static_configs = [{
          targets = [
            "127.0.0.1:${toString config.services.prometheus.exporters.nginxlog.port}"
          ];
        }];
      }
      {
        job_name = "cave";
        static_configs = [{
          targets = [
            "192.168.69.1:9400"
          ];

        }];
        scrape_interval = "5s";
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {};
  };
}
