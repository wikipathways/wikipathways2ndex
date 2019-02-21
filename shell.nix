# For more info, see
# https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html
# https://nixos.org/nix/manual/#sec-nix-shell
#
# For R specifically: https://nixos.org/nixpkgs/manual/#r-packages

with import <nixpkgs> { config.allowUnfree = true; };
#with import ./custom_pkgs/requirements.nix { inherit pkgs; };
stdenv.mkDerivation rec {
  name = "env";
  # Mandatory boilerplate for buildable env
  env = buildEnv { name = name; paths = buildInputs; };
  cytoscape371 = callPackage ./cytoscape.nix {}; 
  builder = builtins.toFile "builder.sh" ''
    source $stdenv/setup; ln -s $env $out
  '';

  # Customizable development requirements
  buildInputs = with rPackages; [
    # Add packages from nix-env -qaP | grep -i needle queries
    #dos2unix
    #cytoscape

    # TODO: xf86videodummy is maybe supposed to be the replacement for xvfb?
    #xorg.xf86videodummy
    xvfb_run

    dplyr
    purrr
    readr
    tidyr
    cytoscape371
    R
    RCy3

    #nix-env -iA nixos.rPackages.RCy3

    # With Python configuration requiring a special wrapper
    # find names here: https://github.com/NixOS/nixpkgs/blob/release-17.03/pkgs/top-level/python-packages.nix
#    (python36.buildEnv.override {
#      ignoreCollisions = true;
#      extraLibs = with python36Packages; [
#        # Add pythonPackages without the prefix
#        dill
#        # TODO clean up how I'm specifying the homoglyphs package.
#        # When I first tried it, I couldn't just add homoglyphs below like this:
#        #homoglyphs
#        # I had to install it using pypi2nix:
#        #   (cd custom_pkgs; pypi2nix -V 3 -e homoglyphs==1.3.2)
#        #   (cd custom_pkgs; pypi2nix -V 3 -e homoglyphs==1.3.2 -e confusable_homoglyphs==3.2.0 -e bs4)
#        # and then use packages."homoglyphs", which looks ugly.
#        #packages."confusable-homoglyphs"
#        #packages."homoglyphs"
#        #packages."bs4"
#      ];
#    })
  ];
#  + (with rPackages; [
#    RCy3
#  ]);

  # Customizable development shell setup with at last SSL certs set
  shellHook = ''
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
  '';
}
