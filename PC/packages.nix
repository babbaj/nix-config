# Everything installed system-wide. Grouped by purpose — add new packages to
# the group that matches what they're for.
#
# NOTE: the concatenation order at the bottom is load-bearing for the resulting
# system-path derivation; reordering it rebuilds the closure for no reason.
{ pkgs, modulesPath, ... }:

let
  inherit (pkgs) jdk jdk8 jdk11 jdk17 jdk25 zulu8 jetbrains;

  # glib is cringe:
  # https://github.com/GNOME/glib/blob/bc0d62424579f507f8d7af13bd29b6d86723f65f/gio/gdesktopappinfo.c#L2498-L2523
  fake-xterm = pkgs.runCommand "xterm-imposter" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.kitty}/bin/kitty $out/bin/xterm
  '';

  obs-stuff = import ../pkgs/obs.nix pkgs;

  # A throwaway VM that holds the second GPU so its fans idle at zero.
  # Installed as `run-gpu-idle-vm`; started by systemd.services.stop-2070-fan.
  gpu-vm = (import "${modulesPath}/../" {
    configuration = ./vm/gpu-idle-vm.nix;
    system = pkgs.stdenv.hostPlatform.system;
  }).vm;

  ides = with pkgs; [
    jetbrains.idea
    jetbrains.clion
    jetbrains.goland
    jetbrains.rider
    jetbrains.pycharm
    jetbrains.rust-rover
    vscode
    qtcreator
  ];

  dev-tools = with pkgs; [
    zig
    clang_18
    llvm_18
    gcc13
    git
    binutils
    cmake
    gnumake
    ninja
    pkg-config
    go
    perf
    perf-tools
    dotnet-sdk_8
    mono
    gdb
    lldb
    valgrind
    rustc
    cargo
    rustup
    rust-cbindgen
    astyle
    opencode
    opencode-desktop
  ];

  shell-tools = with pkgs; [
    coreutils
    ripgrep
    bat
    wget
    pv
    fastfetch
    jq
    iotop
    htop
    rlwrap
    mbuffer
    file
    xclip
    xsel
    asciinema
    tmux
    xxd
    appimage-run
    eza
    hyperfine
  ];

  cli-tools = with pkgs; [
    fdupes
    duperemove
    squashfsTools
    squashfuse
    bind # nslookup and dig
    mediainfo
    compsize
    pciutils
    sqlite-interactive
    smartmontools
    ffmpeg-full
    iperf
    yt-dlp
    usbutils
    lm_sensors
    inetutils
    dmidecode
    i2c-tools
    gnupg
    backblaze-b2
    nvtopPackages.full
    nmap
    unzip
    p7zip
    unrar
    psmisc # future installer requires killall
    gb-backup
    openssl
    wireguard-tools
    docker-compose
    alsa-utils
    libnotify
    exfatprogs
    graphviz
    gamescope
    wl-clipboard
    television
  ];

  nix-tools = with pkgs; [
    nix-diff
    nixfmt
    nix-direnv
    direnv
    fh
    nix-alien
  ];

  apps = with pkgs; [
    gpu-vm
    texliveFull
    vlc
    qbittorrent
    prismlauncher
    google-chrome
    ungoogled-chromium
    element-desktop
    discord
    virt-manager
    telegram-desktop
    (flameshot.override { enableWlrSupport = true; })
    pavucontrol
    qdirstat
    piper # for the mouse
    openvpn
    spotify
    networkmanagerapplet
    gnome-tweaks
    gparted
    wireshark
    wineWow64Packages.staging
    handbrake
    ghidra-bin
    bitwarden-desktop
    droidcam
    kdePackages.kdenlive
    kdePackages.okular
    monero-gui
    #lutris # https://github.com/NixOS/nixpkgs/issues/513245
    xsecurelock
    gimp
    nixos-artwork.wallpapers.simple-dark-gray # dark gray background
    fake-xterm
    gnomeExtensions.gsconnect
    mumble
    audacity
    mangohud
    r2modman
    gnome-calculator
    clonehero
    gnome-system-monitor
    python3
    polychromatic
    parted
    neo4j
    blender
    brave
    firefox
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.ffmpegthumbs
    claude-code
    #bottles # see lutris
    freecad
    slack
  ];
in
{
  environment.systemPackages =
    ides
    ++ dev-tools
    ++ shell-tools
    ++ cli-tools
    ++ nix-tools
    ++ [
      obs-stuff.obs
      obs-stuff.obs-autostart
    ]
    ++ apps;

  # for intellij
  environment.etc = {
    "jdk".source = jdk;
    "jdk8".source = jdk8;
    "jdk11".source = jdk11;
    "jdk17".source = jdk17;
    "jdk25".source = jdk25;
    "zulu8".source = zulu8;
    "jetbrains_jdk".source = jetbrains.jdk;
  };

  environment.sessionVariables = {
    LD_LIBRARY_PATH = [ "${pkgs.libXxf86vm}" ]; # for mc dev
    __GL_THREADED_OPTIMIZATIONS = "0";
  };
}
