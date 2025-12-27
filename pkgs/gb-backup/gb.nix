{ lib, makeWrapper, buildGoModule, fetchFromGitHub, lepton
, src # flake input
}:

buildGoModule {
  pname = "gb-backup";
  version = "unstable";

  inherit src;

  vendorHash = "sha256-dPyMxp8NGcsUQbfVTHNCR7Ng1JPecuOhAZBgbQMNAhM=";

  meta = with lib; {
    description = "Gamer Backup, a super opinionated cloud backup system";
    homepage = "https://github.com/leijurv/gb";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ babbaj ];
    platforms = platforms.unix;
  };
}
