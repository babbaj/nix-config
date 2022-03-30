{ stdenv, lib, fetchFromGitHub, cmake, pkg-config, pipewire, libpulseaudio, libX11, libXi, libXtst, libwnck, webkitgtk, libappindicator, alsa-lib, pcre, openssl, makeWrapper }:


let
  expected-src = fetchFromGitHub {
    owner = "TartanLlama";
    repo = "expected";
    rev = "96d547c03d2feab8db64c53c3744a9b4a7c8f2c5";
    sha256 = "sha256-jF9QyCBfi6QLc9SGdNPAaZW/6c/M1LU2Y3dMyBMyMG0=";
  };
in
stdenv.mkDerivation {
  pname = "soundux";
  version = "lastest";

  src = fetchFromGitHub {
    owner = "Soundux";
    repo = "Soundux";
    rev = "a4fc3811779f67554b3c88686bced40b4e74d1bd";
    sha256 = "sha256-baLxrGdUgPYA34sKbPFhQ3EvxoRqZNgcHopHWg78M+k=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake pkg-config makeWrapper ];

  buildInputs = [
    pipewire
    libpulseaudio
    libX11
    libXi
    libXtst
    libwnck
    webkitgtk
    libappindicator
    alsa-lib
    pcre
    openssl
  ];

  cmakeFlags = [
    "-DFETCHCONTENT_SOURCE_DIR_EXPECTED=${expected-src}"
  ];

  installPhase = ''
    install -Dt $out/bin soundux
    mv dist $out/bin/dist

    wrapProgram $out/bin/soundux \
      --prefix LD_LIBRARY_PATH : ${lib.makeBinPath [ pipewire libpulseaudio ]}
    #ls -l
    #exit 1
  '';

  #makeFlags = [ "DESTDIR=$(out)" ];
}
