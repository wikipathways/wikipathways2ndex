with import <nixpkgs> { config.allowUnfree = true; };
let
  cytoscape371 = callPackage ./cytoscape.nix {}; 
in [
    # Add packages from nix-env -qaP | grep -i needle queries
    #dos2unix
    #cytoscape
    cytoscape371
    tmux

    # TODO: should we use something other than xvfb_run? See README.md.
    #xorg.xf86videodummy
    #xpra
    xvfb_run

    # R and R packages
    R
] ++ (with rPackages; [
  RCy3
  rWikiPathways
  dplyr
  here
  purrr
  readr
  rjson
  tidyr
  # needed for running tests:
  RUnit
  graph
  igraph
])
