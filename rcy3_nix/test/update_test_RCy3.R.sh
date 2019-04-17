#!/usr/bin/env bash

# see https://stackoverflow.com/a/246128/5354298
get_script_dir() { echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
SCRIPT_DIR=$(get_script_dir)

# Get from github
#wget https://raw.githubusercontent.com/cytoscape/RCy3/master/inst/unitTests/test_RCy3.R -O "$SCRIPT_DIR/test_RCy3.R"

# Get locally
RCy3Path=$(nix-env -f "$SCRIPT_DIR/default.nix" -qa --no-name --out-path)
cp "$RCy3Path/library/RCy3/unitTests/test_RCy3.R" "$SCRIPT_DIR/test_RCy3.R"
