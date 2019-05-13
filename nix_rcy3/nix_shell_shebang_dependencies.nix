with import <nixpkgs> { config.allowUnfree = true; };

let
  dependencies = import ./dependencies.nix;
in
runCommand "dummy" {
  # Customizable development requirements
  buildInputs = dependencies;
} ""
