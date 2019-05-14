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
	echo 'Cytoscape is running. Shutting down...' > /dev/stderr
	(cd "$SCRIPT_DIR"; Rscript "./cytoscapestop.R")
	#tmux send-keys 'shutdown --force' C-m
	# kludge to wait for cytoscape to shutdown
	echo 'waiting for cytoscape to stop...'
	sleep 15
fi

Xvfb_pids=$(ps -o pid= -C "Xvfb")
if [[ $(ps -o pid= -C "$cytoscape_command_name" | wc -l) -gt 0 ]]; then
	echo "Warning: $cytoscape_command_name still running. Did it fail to exit properly?" > /dev/stderr
elif [[ -n $Xvfb_pids ]]; then
	echo 'Warning: Xvfb still running. Did "xvfb-run <your-cmd>" fail to exit properly?' > /dev/stderr
	if [[ $(echo -e $Xvfb_pids | wc -l) -eq 1 ]]; then
		kill_Xvfb_cmd="kill -15 $Xvfb_pids"
		# thanks to https://stackoverflow.com/a/1885534
		read -p "Want to run '$kill_Xvfb_cmd' to end the Xvfb process? [y/n] " -n 1 -r
		echo    # (optional) move to a new line
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			$kill_Xvfb_cmd
		fi
	else
		echo "ps a -C 'Xvfb' yields the following:" > /dev/stderr
		echo $(ps a -C 'Xvfb') > /dev/stderr
		echo 'To end the Xvfb process, consider running one of these commands:' > /dev/stderr
		for Xvfb_pid in $(echo -e $Xvfb_pids); do
			echo "kill -15 $Xvfb_pid" > /dev/stderr
		done
	fi
else
	echo 'cytoscape stopped' > /dev/stderr
fi

if [[ $(tmux ls 2> /dev/null) ]]; then
	if [[ $(tmux ls | grep $tmux_session_name 2> /dev/null) ]]; then
		# Equivalent to Ctrl-b x to kill pane
		tmux kill-session -t $tmux_session_name
	fi
fi
