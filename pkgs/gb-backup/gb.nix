{ lib, makeWrapper, buildGoModule, fetchFromGitHub, lepton
, src # flake input
}:

buildGoModule {
  pname = "gb-backup";
  version = "unstable";

  inherit src;

  vendorHash = "sha256-vfE5GjJNcE5mE7eEM7QMgXQCCE1T+t6mVy3ideyJJMk=";

  nativeBuildInputs = [ makeWrapper ];

  #checkInputs = [ lepton ];

  # idk why checkInputs doesn't work
  preCheck = ''
    export PATH=$PATH:${lib.makeBinPath [ lepton ]}
  '';

  postFixup = ''
    wrapProgram $out/bin/gb --prefix PATH : ${lib.makeBinPath [ lepton ]}
  '';

  meta = with lib; {
    description = "Gamer Backup, a super opinionated cloud backup system";
    homepage = "https://github.com/leijurv/gb";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ babbaj ];
    platforms = platforms.unix;
  };
}
