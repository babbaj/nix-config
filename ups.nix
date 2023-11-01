{ ... }:

{
  services.apcupsd = {
    enable = true;
  };
  services.prometheus = {
    enable = true;
    exporters.apcupsd = {
      enable = true;
    };
    scrapeConfigs = [
      {
        job_name = "apcups";
        static_configs = [{
            targets = [ "localhost:9162" ];
        }];
      }
    ];
  };
  services.grafana = {
    enable = true;
    settings = {};
  };
}
