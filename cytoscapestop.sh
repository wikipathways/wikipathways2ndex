#! /usr/bin/env nix-shell
#! nix-shell ./nix_shell_shebang_dependencies.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

cytoscape_command_name='.xvfb-run-wrapped cytoscape'
tmux_session_name='wikipathways2ndex'

# TODO: should we use the R script or do this in bash?
#Rscript cytoscapestop.R
if [[ $(ps -o pid= -C "$cytoscape_command_name" | wc -l) -gt 0 ]] && [[ $(tmux ls | grep $tmux_session_name) ]]; then
	echo 'Cytoscape is running. Shutting down...' > /dev/stderr
	# Send command to the tmux session to launch cytoscape w/ the Xvfb fake display
	tmux send-keys 'shutdown --force' C-m
fi

# kludge to wait for cytoscape to shutdown
# TODO: if I leave Cytoscape running for awhile, running ./cytoscapestop.sh
# doesn't end the Xvfb process. We had sleep 5. Is 5 seconds not long enough?
echo 'waiting for cytoscape to stop...'
sleep 5

if [[ $(ps -o pid= -C "$cytoscape_command_name" | wc -l) -gt 0 ]]; then
	echo 'Warning: did "xvfb-run <your-cmd>" fail to exit?' > /dev/stderr
	# header and Xvfb entry for processes
	echo $(ps aux | head -n 1) > /dev/stderr
	echo $(ps aux | grep Xvfb) > /dev/stderr
	echo 'Maybe one of these commands will end the Xvfb process:' > /dev/stderr
	for Xvfb_pid in $(ps aux | grep Xvfb | awk '{print $2}'); do
		echo "kill -15 $Xvfb_pid" > /dev/stderr
	done
elif [[ $(ps aux | grep Xvfb | wc -l) -gt 1 ]]; then
	echo 'Warning: should not be able to get here in cytoscapestop.sh!' > /dev/stderr
else
	echo 'cytoscape stopped'
fi

if [[ $(tmux ls | grep $tmux_session_name) ]]; then
	# Equivalent to Ctrl-b x to kill pane
	tmux kill-session -t $tmux_session_name
fi
