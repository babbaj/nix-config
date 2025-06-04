{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, pkg-config
, clang
, pipewire
, libclang
, libinput
}:

rustPlatform.buildRustPackage rec {
  pname = "pw-push-to-talk";
  version = "unstable-2023-11-21";

  src = fetchFromGitHub {
    owner = "babbaj";
    repo = pname;
    rev = "83eda75653f2562f56a669078f4763822055385a";
    sha256 = "sha256-+jl5IsDpxYzDxywyvBiUCw6Zn2Oi+It4A1PGXSUaRNw=";
  };

  cargoHash = "sha256-sDJf858Ge+3KB4JQ5pyhqsa6UHSNgXp/wZv3ScEu4/s=";

  LIBCLANG_PATH = "${libclang.lib}/lib/libclang.so";
  nativeBuildInputs = [
    pkg-config
    clang # https://github.com/NixOS/nixpkgs/issues/124163
  ];

  buildInputs = [
    pipewire
    libinput
  ];
}
