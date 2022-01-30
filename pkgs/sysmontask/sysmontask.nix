{ lib, python3Packages, fetchFromGitHub, libwnck, wrapGAppsHook, gobject-introspection, glib, lshw, fetchurl }:

let
  newLshw = lshw.overrideAttrs({...}: rec {
      version = "B.02.19.2";

      src = fetchurl {
        url = "https://ezix.org/software/files/lshw-${version}.tar.gz";
        sha256 = "sha256-m7NHrIcUIzmjZqF1mshF49uzN+wACqG5m1CsZ1ioD4A=";
      };

      patches = [];
  });
in
with python3Packages;
buildPythonApplication rec {
  pname = "SysMonTask";
  version = "1.x.x";

  src = fetchFromGitHub {
    owner = "KrispyCamel4u";
    repo = "SysMonTask";
    rev = "v${version}";
    sha256 = "sha256-hKckFKsnYGmCytn4/FKOpFUE7qbnzNwKFPeBDMNH+q8=";
  };

  patches = [ ./poz.patch ];

  postPatch = ''
    substituteInPlace setup.py \
        --replace "/usr/" ""
    substituteInPlace sysmontask/sysmontask.py \
        --replace "/usr/share" "$out/share"
  '';

  doCheck = false;

  propagatedBuildInputs = [ pygobject3 psutil pycairo ];

  buildInputs = [ libwnck wrapGAppsHook gobject-introspection ];

  postInstall = ''
    ${glib.dev}/bin/glib-compile-schemas "$out"/share/glib-2.0/schemas
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : "${newLshw}/bin"
    )
  '';
}
