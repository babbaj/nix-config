{ config, pkgs, lib, ... }:

with lib;
let
    isAttrsEmpty = set: (!builtins.any (x: true) (builtins.attrNames set));
    cleanup = set: attrsets.filterAttrs (n: v: !(isAttrsEmpty v)) (attrsets.filterAttrsRecursive (name: v: v != null) set);

    cfg = config.looking-glass;

    looking-glass-desktop = { args, terminal, package }: pkgs.makeDesktopItem {
      name = "looking-glass-client";
      desktopName = "Looking Glass Client";
      type = "Application";
      icon = "${package.src}/resources/lg-logo.png";
      exec = "${package}/bin/looking-glass-client ${toString args}";
      terminal = terminal;
    };
in
{
    options.looking-glass = {
        enable = mkEnableOption "looking-glass module";
        package = mkOption {
            type = types.nullOr types.package;
            default = pkgs.looking-glass-client;
        };
        desktopItem = {
            arguments = mkOption {
                type = types.nullOr (types.listOf types.str);
                description = "List of arguments to the executable";
                default = [];
            };
            terminal = mkOption {
                type = types.nullOr lib.types.bool;
                description = "Open a terminal for console output";
                default = true;
            };
        };

        config = {
            app = {
                configFile = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = "A file to read additional configuration from";
                };
                renderer = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Specify the renderer to use";
                };
                license = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Show the license for this application and then terminate";
                };
                cursorPollInterval = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "How often to check for a cursor update in microseconds";
                };
                framePollInterval = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "How often to check for a frame update in microseconds";
                };
                allowDMA = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Allow direct DMA transfers if supported";
                };
                shmFile = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = "The path to the shared memory file, or the name of the kvmfr device to use, ie: kvmfr0";
                };
            };
            win = {
                title = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "The window title";
                };
                position = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Initial window position at startup";
                };
                size = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Initial window size at startup";
                };
                autoResize = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Auto resize the window to the guest";
                };
                allowResize = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Allow the window to be manually resized";
                };
                keepAspect = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Maintain the correct aspect ratio";
                };
                forceAspect = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Force the window to maintain the aspect ratio";
                };
                dontUpscale = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Never try to upscale the window";
                };
                shrinkOnUpscale = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Limit the window dimensions when dontUpscale is enabled";
                };
                borderless = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Borderless mode";
                };
                fullScreen = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Launch in fullscreen borderless mode";
                };
                maximize = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Launch window maximized";
                };
                minimizeOnFocusLoss = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Minimize window on focus loss";
                };
                fpsMin = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Frame rate minimum (0 = disable - not recommended, -1 = auto detect)";
                };
                showFPS = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Enable the FPS & UPS display";
                };
                ignoreQuit = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Ignore requests to quit (ie: Alt+F4)";
                };
                noScreensaver = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Prevent the screensaver from starting";
                };
                autoScreensaver = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Prevent the screensaver from starting when guest requests it";
                };
                alerts = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Show on screen alert messages";
                };
                quickSplash = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Skip fading out the splash screen when a connection is established";
                };
                rotate = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Rotate the displayed image (0, 90, 180, 270)";
                };
            };
            input = {
                grabKeyboard = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Grab the keyboard in capture mode";
                };
                grabKeyboardOnFocus = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Grab the keyboard when focused";
                };
                releaseKeysOnFocusLoss = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "On focus loss, send key up events to guest for all held keys";
                };
                escapeKey = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Specify the escape key, see <linux/input-event-codes.h> for valid values";
                };
                ignoreWindowsKeys = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Do not pass events for the windows keys to the guest";
                };
                hideCursor = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Hide the local mouse cursor";
                };
                mouseSens = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Initial mouse sensitivity when in capture mode (-9 to 9)";
                };
                mouseSmoothing = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Apply simple mouse smoothing when rawMouse is not in use (helps reduce aliasing)";
                };
                rawMouse = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Use RAW mouse input when in capture mode (good for gaming)";
                };
                mouseRedraw = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Mouse movements trigger redraws (ignores FPS minimum)";
                };
                autoCapture = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Try to keep the mouse captured when needed";
                };
                captureOnly = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Only enable input via SPICE if in capture mode";
                };
                helpMenuDelay = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Show help menu after holding down the escape key for this many milliseconds";
                };
            };
            spice = {
                enable = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Enable the built in SPICE client for input and/or clipboard support";
                };
                host = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "The SPICE server host or UNIX socket";
                };
                port = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "The SPICE server port (0 = unix socket)";
                };
                input = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Use SPICE to send keyboard and mouse input events to the guest";
                };
                clipboard = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Use SPICE to syncronize the clipboard contents with the guest";
                };
                clipboardToVM = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Allow the clipboard to be syncronized TO the VM";
                };
                clipboardToLocal = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Allow the clipboard to be syncronized FROM the VM";
                };
                scaleCursor = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Scale cursor input position to screen size when up/down scaled";
                };
                captureOnStart = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Capture mouse and keyboard on start";
                };
                alwaysShowCursor = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Always show host cursor";
                };
                showCursorDot = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Use a “dot” cursor when the window does not have focus";
                };
            };
            egl = {
                vsync = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Enable vsync";
                };
                doubleBuffer = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Enable double buffering";
                };
                multisample = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Enable Multisampling";
                };
                nvGainMax = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "The maximum night vision gain";
                };
                nvGain = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "The initial night vision gain at startup";
                };
                cbMode = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Color Blind Mode (0 = Off, 1 = Protanope, 2 = Deuteranope, 3 = Tritanope)";
                };
                scale = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Set the scale algorithm (0 = auto, 1 = nearest, 2 = linear)";
                };
            };
            opengl = {
                mipmap = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Enable mipmapping";
                };
                vsync = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Enable vsync";
                };
                preventBuffer = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Prevent the driver from buffering frames";
                };
                amdPinnedMem = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Use GL_AMD_pinned_memory if it is available";
                };
            };
            wayland = {
                warpSupport = mkOption {
                    type = types.nullOr types.bool;
                    default = null;
                    description = "Enable cursor warping";
                };
            };
        };

        extraConfig = mkOption {
            type = types.str;
            description = "Extra config file text";
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

        environment.etc =
        let
        config = cleanup cfg.config;
        in mkIf (!isAttrsEmpty config) {
            "looking-glass-client.ini" = {
                text = generators.toINI {} config;
                mode = "0444";
            };
        };
    };
}
