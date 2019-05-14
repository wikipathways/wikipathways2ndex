#! /usr/bin/env nix-shell
#! nix-shell ../nix_shell_shebang_dependencies.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

# see https://stackoverflow.com/a/246128/5354298
get_script_dir() { echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
SCRIPT_DIR=$(get_script_dir)

# NOTE: the first and second commands both work on Ubuntu, but
# only the second works on Nix.
#cytoscape_command_name='.xvfb-run-wrapped cytoscape'
cytoscape_command_name='.xvfb-run-wrapp'

tmux_session_name='wikipathways2ndex'
if [[ $(ps -o pid= -C "$cytoscape_command_name" | wc -l) -gt 0 ]] && [[ $(tmux ls | grep $tmux_session_name) ]]; then
	echo 'Using existing Cytoscape instance...' > /dev/stderr
elif [[ $(ps -o pid= -C "$cytoscape_command_name" | wc -l) -gt 0 ]]; then
	echo "Cytoscape running but not tmux $tmux_session_name?" > /dev/stderr
elif [[ $(tmux ls | grep $tmux_session_name) ]]; then
	echo "tmux $tmux_session_name running but not Cytoscape?" > /dev/stderr
else
	echo 'Starting Cytoscape...' > /dev/stderr
	# Equivalent to Ctrl-b c to create a new window,
	# followed by Ctrl-b d to detach
	tmux new-session -d -s $tmux_session_name

	# Send command to the tmux session to launch cytoscape w/ the Xvfb fake display
	tmux send-keys 'xvfb-run cytoscape --rest 1234' C-m

	(cd "$SCRIPT_DIR"; Rscript "./cytoscapestart.R")
fi
