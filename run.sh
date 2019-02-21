#! /usr/bin/env nix-shell
#! nix-shell deps.nix -i bash

# NOTE: Instead of using this:
# #! /usr/bin/env bash
# we used a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang),
# which allows us to specify and load the exact version of every required dependency.


# Equivalent to Ctrl-b c to create a new window,
# followed by Ctrl-b d to detach
tmux new-session -d -s wikipathways2ndex
# Send command to the tmux session to launch cytoscape w/ the Xvfb fake display
tmux send-keys 'xvfb-run cytoscape --rest 1234' C-m
# kludge to wait for cytoscape to launch
sleep 30
Rscript run.R
# kludge to wait for cytoscape to shutdown
sleep 10
tmux kill-session -t wikipathways2ndex