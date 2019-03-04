#! /usr/bin/env nix-shell
#! nix-shell deps.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.


# Equivalent to Ctrl-b c to create a new window,
# followed by Ctrl-b d to detach
tmux new-session -d -s wikipathways2ndex

# Send command to the tmux session to launch cytoscape w/ the Xvfb fake display
tmux send-keys 'xvfb-run cytoscape --rest 1234' C-m

# kludge to wait for cytoscape to launch
sleep 30

Rscript bulk_to_cx.R

# kludge to wait for cytoscape to shutdown
sleep 10

if [[ $(ps aux | grep Xvfb | wc -l) -gt 1 ]]; then
	echo 'Warning: did xvfb-run your-cmd fail to exit?' > /dev/stderr
fi
tmux kill-session -t wikipathways2ndex
