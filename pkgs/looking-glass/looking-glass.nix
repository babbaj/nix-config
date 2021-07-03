{ stdenv, lib, fetchFromGitHub, fetchpatch
, cmake, pkgconfig, SDL2, SDL, SDL2_ttf, openssl, spice-protocol, fontconfig
, libX11, freefont_ttf, nettle, libconfig, wayland, libpthreadstubs, libXdmcp
, libXfixes, libbfd
, libXi, libXScrnSaver, libXinerama
}:

stdenv.mkDerivation rec {
  pname = "looking-glass-client";
  version = "master";
  src = fetchFromGitHub {
    owner = "gnif";
    repo = "LookingGlass";
    rev = "d82f2e510d4910be7455e1497a7917a6d2d64f97"; # July 2
    sha256 = "17gg5f5vsvg5mmwpx6gcwwyz0hazp7a2gf4vj9dbkalqvnk0qxxg";
    fetchSubmodules =  true;
  };

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [
    SDL SDL2 SDL2_ttf openssl spice-protocol fontconfig
    libX11 freefont_ttf nettle libconfig wayland libpthreadstubs
    libXdmcp libXfixes libbfd cmake

    libXi libXScrnSaver libXinerama
  ];

  cmakeFlags = [ "-DENABLE_WAYLAND=no" ];
  NIX_CFLAGS_COMPILE = "-mavx";
          
  patches = [
    ./0001-Allow-sudo.patch
  ];

  enableParallelBuilding = true;

  sourceRoot = "source/client";

  meta = with lib; {
    description = "A KVM Frame Relay (KVMFR) implementation";
    longDescription = ''
      Looking Glass is an open source application that allows the use of a KVM
      (Kernel-based Virtual Machine) configured for VGA PCI Pass-through
      without an attached physical monitor, keyboard or mouse. This is the final
      step required to move away from dual booting with other operating systems
      for legacy programs that require high performance graphics.
    '';
    homepage = "https://looking-glass.hostfission.com/";
    license = licenses.gpl2Plus;
    maintainers = [ maintainers.alexbakker ];
    platforms = [ "x86_64-linux" ];
  };
}
