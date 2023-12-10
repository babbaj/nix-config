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

  cargoSha256 = "sha256-BOj9SUlN2HGKpGvHkT5XXZPu2r0d0bCT9HmY0rJ43Mk=";

  LIBCLANG_PATH = "${libclang.lib}/lib/libclang.so";
  nativeBuildInputs = [
    pkg-config
    clang # https://github.com/NixOS/nixpkgs/issues/124163
  ];

  buildInputs = [
    pipewire
  ];
}
