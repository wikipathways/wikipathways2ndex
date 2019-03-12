#! /usr/bin/env nix-shell
#! nix-shell ./nix_shell_shebang_dependencies.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.


Rscript cytoscapestop.R

# kludge to wait for cytoscape to shutdown
sleep 5

if [[ $(ps aux | grep Xvfb | wc -l) -gt 1 ]]; then
	echo 'Warning: did xvfb-run your-cmd fail to exit?' > /dev/stderr
fi
tmux kill-session -t wikipathways2ndex
