# This file is only needed to get the path to RCy3
# in update_test_RCy3.R.sh.
# TODO: can we get the path without this file?
with import <nixpkgs> {};
callPackage ../RCy3.nix {}
