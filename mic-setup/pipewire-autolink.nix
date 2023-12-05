{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, pkg-config
, clang
, pipewire
, libclang
}:

rustPlatform.buildRustPackage rec {
  pname = "pipewire-autolink";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "babbaj";
    repo = pname;
    rev = "fd771a14161e4830e8494866d52b78ccf11ce270";
    sha256 = "sha256-pRwkdhgxZuD0jGsVIXSOQjsEuxYa5Zv4OQwSgfgQnUU=";
  };

  cargoSha256 = "sha256-hNOyjMzkzcweRdF7Abb+IcOn1veScvyleZy0yLO8gV8=";

  LIBCLANG_PATH = "${libclang.lib}/lib/libclang.so";
  nativeBuildInputs = [
    pkg-config
    clang # https://github.com/NixOS/nixpkgs/issues/124163
  ];

  buildInputs = [
    pipewire
  ];
}
