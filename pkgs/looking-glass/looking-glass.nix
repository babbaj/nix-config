{ stdenv, lib, fetchFromGitHub, fetchpatch, makeDesktopItem, cmake, pkg-config
, SDL, SDL2_ttf, freefont_ttf, spice-protocol, nettle, libbfd, fontconfig, libffi, expat
, libXi, libXScrnSaver, libXinerama, libXcursor, libXpresent, libxkbcommon
, wayland, wayland-protocols
}:

let
  desktopItem = makeDesktopItem {
    name = "looking-glass-client";
    desktopName = "Looking Glass Client";
    type = "Application";
    exec = "looking-glass-client";
    icon = "lg-logo";
    terminal = true;
  };
in
stdenv.mkDerivation rec {
  pname = "looking-glass-client";
  version = "bleeding-edge";

  src = fetchFromGitHub {
    owner = "gnif";
    repo = "LookingGlass";
    rev = "72f3a9f3cfe46aa54e8465a13b243b33aab91296"; # Sep 10
    sha256 = "0rsyrvdakas1qjl3n7klggvm6hvgjra9179d26va929iyvr4dln7";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake pkg-config ];

  buildInputs = [
    SDL SDL2_ttf freefont_ttf spice-protocol
    libbfd nettle fontconfig libffi expat
    libXi libXScrnSaver libXinerama libXcursor libXpresent
    libxkbcommon
    wayland wayland-protocols
  ];

  NIX_CFLAGS_COMPILE = "-mavx"; # Fix some sort of AVX compiler problem.

  patches = [
    ./0001-Allow-sudo.patch
  ];

  postUnpack = ''
    echo ${src.rev} > source/VERSION
    export sourceRoot="source/client"
  '';

  postInstall = ''
    mkdir -p $out/share/pixmaps
    ln -s ${desktopItem}/share/applications $out/share/
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
