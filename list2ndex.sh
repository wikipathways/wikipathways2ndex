#! /usr/bin/env nix-shell
#! nix-shell nix_shell_shebang_dependencies.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

reuse=$1

bash ./cytoscapestart.sh

Rscript bulk2ndex.R

if [[ ! -z $reuse ]]; then
	echo 'Cytoscape left open for further use...' > /dev/stderr
else
	bash ./cytoscapestop.sh
fi
