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
    rev = "facbb54776dde77d56a0494b270f57d32f8d9e5b"; # June 16
    sha256 = "0575djfz04z2288cqh7zcvm2f2j5mpcp47pxi4qwcqfr4g98p2sd";
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

  installPhase = ''
    mkdir -p $out/bin
    mv looking-glass-client $out/bin/
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
    homepage = "https://looking-glass.hostfission.com/";
    license = licenses.gpl2Plus;
    maintainers = [ maintainers.alexbakker ];
    platforms = [ "x86_64-linux" ];
  };
}
