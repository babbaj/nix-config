{ lib, makeWrapper, buildGoModule, fetchFromGitHub, lepton
, src # flake input
}:

buildGoModule {
  pname = "gb-backup";
  version = "unstable";

  inherit src;

  vendorSha256 = "sha256-S0/P1s4eUusq0kgn6HvtsxULlIrkTvpEtvUyFPCCxo0=";

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
