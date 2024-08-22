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
    rev = "e736ca7b2a41b8fbfe713b0a1fa64eb75bb0b523";
    sha256 = "sha256-1Ndg3djt3DAaa5zdD58cdAUpncxBsrPoE0Uej/1hu78=";
  };

  cargoHash = "sha256-pdavyP/MkHxaudcwrfUn2ROiqdTzlSoTDRTIsodFt4o=";

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
