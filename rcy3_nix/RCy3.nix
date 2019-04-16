{ stdenv, callPackage, fetchFromGitHub, R, rPackages, which, coreutils }:

stdenv.mkDerivation rec {
  name = "RCy3-${version}";
  version = "2.3.12";

  cytoscape371 = callPackage ./cytoscape.nix {}; 

  src = fetchFromGitHub {
    owner = "cytoscape";
    repo = "RCy3";
    rev = "0d8c8b0351ab399604ca28d01faf436a1e207e3e";
    sha256 = "1npj2acqry733290d55jds5aryns84gsxkqnqah4a3iy1kx4b29c";
  };

  configurePhase = ''
    runHook preConfigure
    export R_LIBS_SITE="$R_LIBS_SITE''${R_LIBS_SITE:+:}$out/library"
    runHook postConfigure
  '';

  buildInputs = [ R cytoscape371 which coreutils ];
  propagatedBuildInputs = with rPackages; [ BiocGenerics graph httr igraph RJSONIO XML R_utils ];

  patchPhase = ''
    substituteInPlace ./R/Session.R \
      --replace ./sampleData/ $(dirname $(dirname $(which cytoscape)))/share/sampleData/
  '';

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

  doInstallCheck = stdenv.hostPlatform == stdenv.buildPlatform;
  installCheckPhase = ''
    RCy3VersionOutput=$(R -q --slave -e 'library(RCy3); packageVersion("RCy3");')
    [[ $RCy3VersionOutput =~ (^|[^0-9a-zA-Z\.\-])${version}([^0-9a-zA-Z\.\-]|$) ]]
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
