#! /usr/bin/env nix-shell
#! nix-shell nix_shell_shebang_dependencies.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

if [[ $(ps aux | grep Xvfb | wc -l) -gt 1 ]] && [[ $(tmux ls | grep wikipathways2ndex) ]]; then
	echo 'Using existing Cytoscape instance...' > /dev/stderr
else
	echo 'Starting Cytoscape...' > /dev/stderr
	# Equivalent to Ctrl-b c to create a new window,
	# followed by Ctrl-b d to detach
	tmux new-session -d -s wikipathways2ndex

	# Send command to the tmux session to launch cytoscape w/ the Xvfb fake display
	tmux send-keys 'xvfb-run cytoscape --rest 1234' C-m

	Rscript cytoscapestart.R
fi
