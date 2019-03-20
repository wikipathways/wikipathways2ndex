#! /usr/bin/env nix-shell
#! nix-shell nix_shell_shebang_dependencies.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

echo 'change ~/CytoscapeConfiguration/3/karaf_data/cache/bundle117/bundle.info'
rm $HOME/CytoscapeConfiguration/3/apps/installed/WikiPathways-v*.jar
rm -rf $HOME/CytoscapeConfiguration/app-data/org.wikipathways.cytoscapeapp-3.3.7
wget 'https://github.com/wikipathways/cytoscape-wikipathways-app/blob/develop/WikiPathways-3.3.73.jar?raw=true' -O "$HOME/CytoscapeConfiguration/3/apps/installed/WikiPathways-v3.3.7-3.jar"
