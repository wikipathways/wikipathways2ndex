#! /usr/bin/env nix-shell
#! nix-shell nix_shell_shebang_dependencies.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

reuse=$1

#bash ./cytoscapestart.sh
./cytoscapestart.sh

Rscript bulk2cx.R

if [[ ! -z $reuse ]]; then
	echo 'Cytoscape left open for further use...' > /dev/stderr
else
	bash ./cytoscapestop.sh
fi

if ls -1 WP*.png 2>&1 > /dev/null && ls -1 ./cx/ 2>&1 > /dev/null; then
	mv ./WP*.png ./cx/
fi
