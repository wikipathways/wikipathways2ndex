with import <nixpkgs> { config.allowUnfree = true; };
let
  cytoscape371 = callPackage ./nix_rcy3/cytoscape.nix {}; 
  RCy3_2312 = callPackage ./nix_rcy3/RCy3.nix {}; 
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
    RCy3_2312
] ++ (with rPackages; [
  #RCy3
  rWikiPathways
  ndexr
  httr
  easyPubMed
  dplyr
  here
  optparse
  purrr
  readr
  jsonlite
  tidyr
  utf8
  # needed for running tests:
  RUnit
  graph
  igraph
])
