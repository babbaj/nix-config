{ lib, pkgs, ... }:

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
  #services.desktopManager.gnome.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.gdm.enable = true;

  # Keep gnome-keyring (what COSMIC used) as the Secret Service under Plasma too.
  # plasma6 enables pam_kwallet, which starts ksecretd at login; ksecretd then
  # claims org.freedesktop.secrets and hides everything stored in login.keyring.
  security.pam.services.login.kwallet.enable = lib.mkForce false;
  security.pam.services.kde.kwallet.enable = lib.mkForce false;
  # In case ksecretd still gets D-Bus activated, don't let it take the Secret Service name.
  environment.etc."xdg/kwalletrc".text = ''
    [org.freedesktop.secrets]
    apiEnabled=false
  '';

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
