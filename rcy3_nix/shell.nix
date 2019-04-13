# For more info, see
# https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html
# https://nixos.org/nix/manual/#sec-nix-shell
#
# For R specifically: https://nixos.org/nixpkgs/manual/#r-packages

with import <nixpkgs> { config.allowUnfree = true; };
let
  dependencies = import ./dependencies.nix;
in
#with import ./custom_pkgs/requirements.nix { inherit pkgs; };
stdenv.mkDerivation rec {
  name = "env";
  # Mandatory boilerplate for buildable env
  env = buildEnv { name = name; paths = buildInputs; };
  RCy3_2310 = callPackage ./RCy3.nix {}; 
  cytoscape371 = callPackage ./cytoscape.nix {}; 
  builder = builtins.toFile "builder.sh" ''
    source $stdenv/setup; ln -s $env $out
  '';

#  buildInputs = [R cytoscape371] ++
#  		(with rPackages; [ BiocGenerics graph httr igraph RJSONIO XML R_utils]);

  # Customizable development requirements
#  buildInputs = [cytoscape371 tmux xvfb_run jqR] ++
#                (with rPackages; [ dplyr here ]);

  # Customizable development requirements
  buildInputs = dependencies;

  # Customizable development shell setup with at last SSL certs set
  shellHook = ''
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
  '';
}
