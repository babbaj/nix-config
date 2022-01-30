{ fetchFromGitHub , lib, stdenv, python3, gtk3, libwnck
, gobject-introspection, wrapGAppsHook
}:


let
  pythonEnv = python3.withPackages(ps: with ps; [ pygobject3 psutil pycairo ]);
in
stdenv.mkDerivation rec {
  pname = "SysMonTask";
  version = "1.x.x";

  src = fetchFromGitHub {
    owner = "KrispyCamel4u";
    repo = "SysMonTask";
    rev = "v${version}";
    sha256 = "sha256-hKckFKsnYGmCytn4/FKOpFUE7qbnzNwKFPeBDMNH+q8=";
  };

  #patches = [ ./poz.patch ];

  #postPatch = ''
  #  substituteInPlace setup.py \
  #      --replace '1.x.x' '1.0.0'
  #'';

  doCheck = false;

  buildInputs = [ pythonEnv gtk3 libwnck gobject-introspection wrapGAppsHook ];

    installPhase = ''
        echo uwu
        ls
        exit 1
        #sed -i 's/python/python3/g' clipster
        #mkdir -p $out/bin/
        #cp clipster $out/bin/
    '';
}
