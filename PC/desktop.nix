{ pkgs, ... }:

{
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];

    excludePackages = [ pkgs.xterm ];

    logFile = "/var/log/X.0.log"; # lightdm sets this, gdm does not

    xkb.layout = "us";
  };
  services.libinput.mouse.middleEmulation = false; # worst troll ever

  services.desktopManager.cosmic.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  fonts.packages = with pkgs; [
    cantarell-fonts
  ];

  # cuckpak
  services.flatpak.enable = true;
  xdg.portal.enable = true;

  environment.sessionVariables = {
    COSMIC_DATA_CONTROL_ENABLED = 1; # enable clipboard manager
    NIXOS_OZONE_WL = "1";
  };
}
