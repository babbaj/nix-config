{ lib, stdenv, fetchFromGitHub, fetchurl, cmake, python2, boost, libpng, libjpeg }:

let 
  mcJar = fetchurl {
    url = "https://s3.amazonaws.com/Minecraft.Download/versions/1.12.2/1.12.2.jar";
    sha256 = "sha256-itoH2l7nfa01J71yePvQXuH8ill4E7IWqHGi19ZMxk8=";
  };
in
stdenv.mkDerivation rec {
  pname = "mapcrafter";
  version = "2.4";

  src = fetchFromGitHub {
    owner = "mapcrafter";
    repo = "mapcrafter";
    rev = "5aa16da59c5022a06fa01c24ab99b100b3c6bedb";
    sha256 = "sha256-28p60NCDHYnGSBgMn/G6m7Xnq7n+jfSreNWwJ9BwO6Q=";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ boost libpng libjpeg ];

  NIX_CFLAGS_COMPILE = [
    "-Wno-error=format-security"
  ];

  enableParallelBuilding = true;

  postInstall = ''
    mkdir -p $out/share/mapcrafter/textures
    ${python2}/bin/python $src/src/tools/mapcrafter_textures.py -f ${mcJar} $out/share/mapcrafter/textures
  '';
}
