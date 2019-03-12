#! /usr/bin/env nix-shell
#! nix-shell ../nix_shell_shebang_dependencies.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

reuse=$1

# from https://unix.stackexchange.com/a/84980
TMPDIR=`mktemp -d 2>/dev/null || mktemp -d -t 'wikipathways2ndextmpdir'`

bash ./cytoscapestart.sh

if [ -d ./cx ]; then
	mv ./cx $TMPDIR
fi
Rscript ./test/test.R
rm WP554__ACE_Inhibitor_Pathway__Homo_sapiens.png
rm -rf ./cx
if [ -d $TMPDIR ]; then
	mv $TMPDIR ./cx
fi

if [[ ! -z $reuse ]]; then
	echo 'Cytoscape left open for further use...' > /dev/stderr
else
	bash ./cytoscapestop.sh
fi
