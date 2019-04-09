#! /usr/bin/env nix-shell
#! nix-shell nix_shell_shebang_dependencies.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

# https://github.com/wikipathways/cytoscape-wikipathways-app/blob/master/WikiPathways-3.3.76.jar?raw=true

DEV_VERSION_MAJOR="3"
DEV_VERSION_MINOR="3"
DEV_VERSION_PATCH="7"
DEV_VERSION_SUB="6"

rm $HOME/CytoscapeConfiguration/3/apps/installed/WikiPathways-v*.jar
rm -rf $HOME/CytoscapeConfiguration/app-data/org.wikipathways.cytoscapeapp*

source="https://github.com/wikipathways/cytoscape-wikipathways-app/blob/master/WikiPathways-$DEV_VERSION_MAJOR.$DEV_VERSION_MINOR.$DEV_VERSION_PATCH$DEV_VERSION_SUB.jar?raw=true" 
echo "source: $source"
destination="$HOME/CytoscapeConfiguration/3/apps/installed/WikiPathways-v$DEV_VERSION_MAJOR.$DEV_VERSION_MINOR.$DEV_VERSION_PATCH-$DEV_VERSION_SUB.jar"
echo "destination: $destination"

wget "$source" -O "$destination"
