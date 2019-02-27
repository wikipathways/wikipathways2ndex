# wikipathways2ndex

Convert pathways from [WikiPathways](http://wikipathways.org) to CX format and export to [NDEx](http://ndexbio.org).

# Installation

Just install [Nix](https://nixos.org/nix/download.html), and the rest of the dependencies will be taken care of for you.

# Usage

## Headless Option

1. Clone and enter this repo:

```sh
git clone https://github.com/wikipathways/wikipathways2ndex.git
cd wikipathways2ndex
```

2. Create an account at [NDEx](http://ndexbio.org) if you don't have one. Then set your NDEx username and password:

```sh
export NDEX_USER="username-for-your-ndex-account"
export NDEX_PWD="password-for-your-ndex-account"
```

3. In the file `pathway_ids.tsv`, specify the WikiPathways IDs you'd like to convert and export to NDEx.

4. Execute: `./run.sh`

FYI: we used [`xvfb-run`](http://elementalselenium.com/tips/38-headless) as a dummy display to enable running Cytoscape in headless mode.

## GUI Option

It's possible to run Cytoscape on a remote computer while viewing it on your local computer.

In one terminal:
```sh
ssh -Y wikipathways-workspace.gladstone.internal
cd wikipathways2ndex
nix-shell
cytoscape --rest 1234
```

In another terminal:
```sh
ssh wikipathways-workspace.gladstone.internal
cd wikipathways2ndex
nix-shell
export NDEX_USER="username-for-your-ndex-account"
export NDEX_PWD="password-for-your-ndex-account"
Rscript wikipathways2ndex.R
#R -f wikipathways2ndex.R
unset NDEX_USER # optional
unset NDEX_PWD # optional
```

# TODO
Should we use something other than `xvfb-run`?
xf86videodummy is maybe supposed to be the replacement for xvfb.
`nix-env -iA nixos.xorg.xf86videodummy`
It's also possible to [use `xpra` like `xvfb-run`](https://unix.stackexchange.com/questions/279567/how-to-use-xpra-like-xvfb-run)
`nix-env -iA nixos.xpra`

Why does the following command fail to fully open Cytoscape?
```sh
nohup cytoscape --rest 1234 &
```

# Troubleshooting

If you get a curl error, it's likely your session had an error and didn't shutdown correctly.

```sh
ps aux | grep Xvfb # get pid
kill -9 <pid> # use the pid from the previous step
```

tmux attach
Ctrl-b x
