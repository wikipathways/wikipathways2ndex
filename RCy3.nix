{ stdenv, callPackage, fetchFromGitHub, R, rPackages }:

stdenv.mkDerivation rec {
  name = "RCy3-${version}";
  version = "2.3.10";

  cytoscape371 = callPackage ./cytoscape.nix {}; 

  src = fetchFromGitHub {
    owner = "cytoscape";
    repo = "RCy3";
    rev = "e205b1ad94f592cf4d889f842ea1da24ed73807e";
    sha256 = "0g5i7z9a3a81mv1bj9hshwwf3n4d6i32312v0jqv06rx7n9s405q";
  };

  configurePhase = ''
    runHook preConfigure
    export R_LIBS_SITE="$R_LIBS_SITE''${R_LIBS_SITE:+:}$out/library"
    runHook postConfigure
  '';

  buildInputs = [R cytoscape371];
  propagatedBuildInputs = with rPackages; [ BiocGenerics graph httr igraph RJSONIO XML R_utils];

  buildPhase = ''
    runHook preBuild
    runHook postBuild
  '';

  rCommand = "R";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/library
    $rCommand CMD INSTALL $installFlags --configure-args="$configureFlags" -l $out/library .
    runHook postInstall
  '';

  postFixup = ''
    if test -e $out/nix-support/propagated-build-inputs; then
        ln -s $out/nix-support/propagated-build-inputs $out/nix-support/propagated-user-env-packages
    fi
  '';

  meta = {
    homepage = https://github.com/cytoscape/RCy3;
    description = "New version of RCy3, redesigned and collaboratively maintained by Cytoscape developer community";
    license = stdenv.lib.licenses.mit;
    maintainers = [];
    platforms = stdenv.lib.platforms.unix;
  };
}
