#! /usr/bin/env nix-shell
#! nix-shell deps.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

reuse=$1

if [[ $(ps aux | grep Xvfb | wc -l) -gt 1 ]] && [[ $(tmux ls | grep wikipathways2ndex) ]]; then
	echo 'Using existing Cytoscape instance...' > /dev/stderr
else
	echo 'Starting Cytoscape...' > /dev/stderr
	bash ./cytoscapestart.sh
fi

Rscript bulk2cx.R

if [[ ! -z $reuse ]]; then
	echo 'Cytoscape left open for further use...' > /dev/stderr
else
	bash ./cytoscapestop.sh
fi

bash ./integer_double_error_kludge.sh

mv ./WP*.png ./cx/
