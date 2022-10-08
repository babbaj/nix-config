{ stdenv, lib, fetchFromGitHub, makeDesktopItem, copyDesktopItems, cmake, pkg-config, git
, freefont_ttf, spice-protocol, nettle, libbfd, fontconfig, libffi, expat
, libxkbcommon, libGL, libXext, libXrandr, libXi, libXScrnSaver, libXinerama
, libXcursor, libXpresent, wayland, wayland-protocols
, pipewire, libpulseaudio, libsamplerate
, src # flake input
, terminal ? true
}:

let
  desktopItem = makeDesktopItem {
    name = "looking-glass-client";
    desktopName = "Looking Glass Client";
    type = "Application";
    exec = "looking-glass-client";
    icon = "lg-logo";
    inherit terminal;
  };
in stdenv.mkDerivation rec {
  pname = "looking-glass-client";
  version = "bleeding-edge";

  /*src = fetchFromGitHub {
    owner = "gnif";
    repo = "LookingGlass";
    rev = "febd081202ce0d64c6698d11f17fa14a93d84d17"; # Jan 27
    sha256 = "sha256-zwAF45u0fWej7AUVDr//iDZtLldgFi3t0fXXgAhP0JE=";
    fetchSubmodules = true;
  };*/
  inherit src;

  nativeBuildInputs = [ git cmake pkg-config copyDesktopItems ];

  desktopItems = [ desktopItem ];

  buildInputs = [
    libGL
    freefont_ttf
    spice-protocol
    expat
    libbfd
    nettle
    fontconfig
    libffi
    libxkbcommon
    libXi
    libXScrnSaver
    libXinerama
    libXcursor
    libXpresent
    libXext
    libXrandr
    wayland
    wayland-protocols
    pipewire.dev
    libpulseaudio
    libsamplerate
  ];

  NIX_CFLAGS_COMPILE = "-march=native";

  #cmakeFlags = [ "-DOPTIMIZE_FOR_NATIVE=OFF" ];

  patches = [
    #./0001-Allow-sudo.patch
    ./allow-sudo.patch
    ./fix-pointer-grab.patch
  ];

  postUnpack = ''
    echo ${src.rev} > source/VERSION
  '';

  postPatch = ''
    cd client
  '';

  postInstall = ''
    mkdir -p $out/share/pixmaps
    cp $src/resources/lg-logo.png $out/share/pixmaps
  '';

  meta = with lib; {
    description = "A KVM Frame Relay (KVMFR) implementation";
    longDescription = ''
      Looking Glass is an open source application that allows the use of a KVM
      (Kernel-based Virtual Machine) configured for VGA PCI Pass-through
      without an attached physical monitor, keyboard or mouse. This is the final
      step required to move away from dual booting with other operating systems
      for legacy programs that require high performance graphics.
    '';
    homepage = "https://looking-glass.io/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ alexbakker babbaj ];
    platforms = [ "x86_64-linux" ];
  };
}
