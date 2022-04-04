{ config, ... }:

{
  programs.htop = {
    enable = true;
    settings = with config.lib.htop; ({
      delay = 10;
      sort_key = fields.PERCENT_MEM;
      show_cpu_frequency = 1;
    } // leftMeters [
      (bar "LeftCPUs")
      (bar "Memory")
      (bar "Swap")
    ] // rightMeters [
      (bar "RightCPUs")
      (text "Tasks")
      (text "LoadAverage")
      (text "Uptime")
      (text "Systemd")
    ]);
  };
}
