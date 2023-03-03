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
    rev = "4edce7bef6d9df2c5f1147c2ed39ae11f84550a6";
    sha256 = "sha256-3oigkTrUnYjAgNZsNQ53vy2/3PKfurk8HIf5VsOTUUs=";
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
