{ lib, stdenv
, fetchFromGitHub
, rustPlatform
, pkg-config
, clang
, pipewire
, libX11
, libXi
, libXtst
, libclang
}:

rustPlatform.buildRustPackage rec {
  pname = "pw-push-to-talk";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "babbaj";
    repo = pname;
    rev = "ef791cec11ae127262d4ce23602822e1448f8129";
    sha256 = "sha256-qZVG0bSAG354HMKJZCLm4AD+RV/C12GxGSefECiCDJk=";
  };

  cargoSha256 = "sha256-8nhXdCp77sw9S66yAIdHBylVTEBCxVBtEfMzrR2pnvY=";

  LIBCLANG_PATH = "${libclang.lib}/lib/libclang.so";
  nativeBuildInputs = [
    pkg-config
    clang # https://github.com/NixOS/nixpkgs/issues/124163
  ];

  buildInputs = [
    pipewire
    libX11
    libXi
    libXtst
  ];
}
