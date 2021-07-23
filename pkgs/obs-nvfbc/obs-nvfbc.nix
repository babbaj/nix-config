{ stdenv, lib, meson, ninja, pkg-config, obs-studio, mesa, libGL, libX11, fetchFromGitLab }:

stdenv.mkDerivation {
    pname = "obs-nvfbc";
    version = "master";

    src = fetchFromGitLab {
        owner = "fzwoch";
        repo = "obs-nvfbc";
        rev = "010234f2f8cf5bed3fb0711275544441097173aa";
        sha256 = "0zyvks6gc6fr0a1j5b4y20rcx6ah35v6yiz05f6g3x6bhqi92l33";
    };

    nativeBuildInputs = [ meson pkg-config ninja ];
    buildInputs = [ obs-studio mesa libGL libX11 ];
}
