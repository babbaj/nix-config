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
    rev = "75744d67b76e2bea89873c04a12426a111a689a0";
    sha256 = "sha256-su0hXQxjXJ8fohwWPzEGaxTvSAfun3crlh7nDZd/F4k=";
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
