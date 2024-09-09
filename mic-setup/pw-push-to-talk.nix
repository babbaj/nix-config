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
    rev = "50276827a51b6621ee1e2c5f44c7b6bba032a87e";
    sha256 = "sha256-TwtqiKWcL8UhVDsqjq8i/yzfyRXA6JkxDiRs/NSeTtc=";
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
