with import <nixpkgs> { config.allowUnfree = true; };
let
  cytoscape371 = callPackage ./cytoscape.nix {}; 
  RCy3_2310 = callPackage ./RCy3.nix {}; 
in [
    # Add packages from nix-env -qaP | grep -i needle queries
    #cytoscape
    cytoscape371
    tmux

    # TODO: should we use something other than xvfb_run? See README.md.
    #xorg.xf86videodummy
    #xpra
    xvfb_run

    # R and R packages
    R
    RCy3_2310
] ++ (with rPackages; [
  #RCy3
  here
  # needed for running tests:
  RUnit
  graph
  igraph
])
