with import <nixpkgs> { config.allowUnfree = true; };

let
  # Pull request made: https://github.com/NixOS/nixpkgs/pull/56498
  cytoscape371 = callPackage ./cytoscape.nix {}; 
in
runCommand "dummy" {
  # Customizable development requirements
  buildInputs = with rPackages; [
    cytoscape371
    tmux

    # TODO: should we use something other than xvfb_run? See README.md.
    #xorg.xf86videodummy
    #xpra
    xvfb_run

    # needed for kludge for double/integer bug
    jq

    # R and R packages
    R
    dplyr
    here
    purrr
    RCy3
    readr
    rjson
    tidyr
    # needed for running tests:
    RUnit
    graph
    igraph

  ];
} ""
