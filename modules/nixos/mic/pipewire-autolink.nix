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
  version = "unstable-2023-12-5";

  src = fetchFromGitHub {
    owner = "babbaj";
    repo = pname;
    rev = "7da5b0565ffa518c056cf4cd4c8b59174203819b";
    sha256 = "sha256-L4WMFdXumwgH0cGxocZ9gOnxdKuV3EjG6ymD1hlEHXk=";
  };

  cargoHash = "sha256-mH7VsXHMZjsZXK6O48/27x7oK2RlbP6CJPbHtx6+uP4=";

  LIBCLANG_PATH = "${libclang.lib}/lib/libclang.so";
  nativeBuildInputs = [
    pkg-config
    clang # https://github.com/NixOS/nixpkgs/issues/124163
  ];

  buildInputs = [
    pipewire
  ];
}
