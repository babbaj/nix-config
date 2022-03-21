{ config, pkgs, lib, ...}:

{
    services.prometheus.exporters.node = {
        enable = true;
    };

    services.grafana = {
        enable = true;
    };
}
