{ stdenv, lib, fetchgit, pkg-config, makeWrapper, gtk3, libX11, libXrandr, libpulseaudio
, gpu-screen-recorder
}:

stdenv.mkDerivation rec {
  pname = "gpu-screen-recorder-gtk";
  version = "2022-03-22";

  src = fetchgit {
    url = "https://repo.dec05eba.com/gpu-screen-recorder-gtk";
    rev = "6162b5a9b32ef52b232e61deb8ec58d2a998cfd4";
    sha256 = "sha256-VGkN44LdVYJOUvUfnIeGXdzNaz31fr39WE8yo5yXrBE=";
  };

  nativeBuildInputs = [ 
    pkg-config 
    makeWrapper
  ];

  buildInputs = [
    gtk3
    libX11
    libXrandr
    libpulseaudio
  ];

  configurePhase = ''
    substituteInPlace src/main.cpp \
      --replace '/usr/lib/libnvidia-fbc.so.1' '/run/opengl-driver/lib/libnvidia-fbc.so.1'
  '';

  buildPhase = ''
    ./build.sh
  '';

  installPhase = ''
    install -Dt $out/bin/ gpu-screen-recorder-gtk
    install -Dt $out/share/applications/ gpu-screen-recorder-gtk.desktop

    wrapProgram $out/bin/gpu-screen-recorder-gtk --prefix PATH : ${lib.makeBinPath [ gpu-screen-recorder ]}
  '';

  meta = with lib; {
    description = "gtk frontend for gpu-screen-recorder.";
    homepage = "https://git.dec05eba.com/gpu-screen-recorder-gtk/about/";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ babbaj ];
    platforms = [ "x86_64-linux" ];
  };
}
