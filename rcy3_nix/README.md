# Nix Package for RCy3

The version of RCy3 currently (2019-03-12) in nixpkgs is from Bioconductor 3.8.
Bioconductor 3.8 has RCy3 version 2.1.13. To get this version, you can run:
`nix-env -iA nixos.rPackages.RCy3`

But the version of RCy3 on GitHub is 2.3.12. To get this updated version, run:
`nix-env -f ./RCy3.nix -i`

This repo also has some useful code in `extras`:
* `cytoscapestart.sh`: starts Cytoscape in headless mode
* `cytoscapestop.sh`: stops Cytoscape in headless mode
* `about.R`: see version info for Cytoscape, Cytoscape Apps and RCy3

## Development

Update tests: `./test/update_test_RCy3.R.sh`
Run tests: `./test/run.R`

Why is the following error occasionally showing up:
>------- test.filters
Error in checkEqualsNumeric(length(sel$nodes), 17) : 
  Mean relative difference: 0.2142857
Calls: run.tests -> test.filters -> checkEqualsNumeric
