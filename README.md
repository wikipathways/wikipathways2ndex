# wikipathways2ndex

Convert pathways from [WikiPathways](http://wikipathways.org) to CX format and
export to [NDEx](http://ndexbio.org).

## Installation

Just install [Nix](https://nixos.org/nix/download.html). Then when you run
`./export.R` the first time, all required dependencies will be installed for
you.

## Usage

1. Clone and enter this repo:

```sh
git clone https://github.com/wikipathways/wikipathways2ndex.git
cd wikipathways2ndex
```

Temporary: until the updated version (>= 3.3.7-7) of the WikiPathways app for Cytoscape is put into production, do this:

```sh
bash ./install_dev_wikipathways_app.sh
```

2. Create an account at [NDEx](http://ndexbio.org) if you don't have one. Then set your NDEx username and password (perhaps in `~/.profile`):

```sh
export NDEX_USER_UUID="userid-for-your-ndex-account"
export NDEX_USER="username-for-your-ndex-account"
export NDEX_PWD="password-for-your-ndex-account"
```

If you don't have permissions to edit the NDEx Network Sets specified in `wikipathways2ndex.R`,
you'll need to change to one you can edit.

3. Execute: `./export.R AnalysisCollection ndex ./output-dir`

To see more options, run `./export.R --help`

To put job running and detach:

```
screen -R
./export.R AnalysisCollection ndex ./output-dir
# Ctrl+a
# d
```

Now you can leave. To check up on the job and then close the screen:

```
screen -R
# look at what's going on. if the job is complete, you can kill the screen:
# Ctrl+a
# K
```

## Further Details

We used [`xvfb-run`](http://elementalselenium.com/tips/38-headless) as a dummy display to enable running Cytoscape in headless mode. Should we use something other than `xvfb-run`?
xf86videodummy is maybe supposed to be the replacement for xvfb.
`nix-env -iA nixos.xorg.xf86videodummy`
It's also possible to [use `xpra` like `xvfb-run`](https://unix.stackexchange.com/questions/279567/how-to-use-xpra-like-xvfb-run)
`nix-env -iA nixos.xpra`

[Interesting example](https://github.com/NixOS/nixpkgs/blob/37694c8cc0e9ecab60d06f1d9a2fd0073bcc5fa3/pkgs/development/r-modules/generic-builder.nix#L29) of using R or R in X.
