#! /usr/bin/env nix-shell
#! nix-shell ./nix_shell_shebang_dependencies.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.


Rscript cytoscapestop.R

# kludge to wait for cytoscape to shutdown
# TODO: if I leave Cytoscape running for awhile, running ./cytoscapestop.sh
# doesn't end the Xvfb process. We had sleep 5. Is 5 seconds not long enough?
sleep 15

if [[ $(ps aux | grep Xvfb | wc -l) -gt 1 ]]; then
	echo 'Warning: did "xvfb-run <your-cmd>" fail to exit?' > /dev/stderr
	# header and Xvfb entry for processes
	echo $(ps aux | head -n 1) > /dev/stderr
	echo $(ps aux | grep Xvfb) > /dev/stderr
#	# TODO: how about using one of the following instead to get Xvfb pid(s)?
#	# TODO: get rid of the ps process from this list
#	ps -o pid -C 'Xvfb'
#	pidof 'Xvfb'
	echo 'Maybe one of these commands will end the Xvfb process:' > /dev/stderr
	for Xvfb_pid in $(ps aux | grep Xvfb | awk '{print $2}'); do
		echo "kill -15 $Xvfb_pid" > /dev/stderr
	done
fi
tmux kill-session -t wikipathways2ndex
