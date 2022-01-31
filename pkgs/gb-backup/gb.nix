{ lib, makeWrapper, buildGoModule, fetchFromGitHub, lepton 
, src # flake input
}:

buildGoModule {
  pname = "gb-backup";
  version = "unstable-2021-11-01";

  #src = fetchFromGitHub {
  #  owner = "leijurv";
  #  repo = "gb";
  #  rev = "b4eceeff87ca03449cff189807e06de796d5da60";
  #  sha256 = "sha256-5AKo2S7cl79hX3KgwSikpN5g/P+inFbCO/vgCUKeSHw=";
  #};
  inherit src;

  vendorSha256 = "sha256-H3Zf4VNJVX9C3GTeqU4YhNqCIQz1R55MfhrygDgJTxc=";

  nativeBuildInputs = [ makeWrapper ];

  checkInputs = [ lepton ];

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
