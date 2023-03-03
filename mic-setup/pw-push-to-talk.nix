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
    rev = "f060ece75bf80c300e0cfa0d4893ee74be57c32f";
    sha256 = "sha256-U9FbK3OOnFDO+yWwaVTTP9JI/WK+vipQki7NTIrIUu4=";
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
