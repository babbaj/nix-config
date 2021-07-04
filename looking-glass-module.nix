{ config, pkgs, lib, ... }:

with lib;
let
    cfg = config.looking-glass;

    looking-glass-desktop = { args, terminal, package }: pkgs.makeDesktopItem {
      name = "looking-glass-client";
      desktopName = "Looking Glass Client";
      type = "Application";
      icon = "${package.src}/resources/lg-logo.png";
      exec = "${package}/bin/looking-glass-client ${toString args}";
      terminal = toString terminal;
    };
in
{
    options.looking-glass = {
        enable = mkEnableOption "looking-glass module";
        package = mkOption {
            type = types.package;
            default = pkgs.looking-glass-client;
        };
        desktopItem = {
            arguments = mkOption {
                type = types.listOf types.str;
                description = "List of arguments to the executable";
                default = [];
            };
            terminal = mkOption {
                type = lib.types.bool;
                description = "Open a terminal for console output";
                default = true;
            };
        };
        iniConfig = mkOption {
            type = types.str;
            description = "Full text for /etc/looking-glass-client.ini";
            default = "";
        };
         
    };

    config = mkIf cfg.enable {
        environment.systemPackages = with cfg.desktopItem; [ 
            (looking-glass-desktop { args = arguments; inherit terminal; package = cfg.package; })
            cfg.package
        ];

        systemd.tmpfiles.rules = [
            "f /dev/shm/looking-glass 0666 1000 qemu-libvirtd -" # TODO: make this more configurable
        ];

        environment.etc = mkIf (cfg.iniConfig != "") {
            "looking-glass-client.ini" = {
                text = cfg.iniConfig;
                mode = "0444";
            };
        };
    };
}
