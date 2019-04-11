# wikipathways2ndex

Convert pathways from [WikiPathways](http://wikipathways.org) to CX format and export to [NDEx](http://ndexbio.org).

# Installation

Just install [Nix](https://nixos.org/nix/download.html), and the rest of the dependencies will be taken care of for you.

# Usage

1. Clone and enter this repo:

```sh
git clone https://github.com/wikipathways/wikipathways2ndex.git
cd wikipathways2ndex
```

Temporary: until the updated version (>= 3.3.7-3) of the WikiPathways app for Cytoscape is put into production, do this:

```sh
bash ./install_dev_wikipathways_app.sh
```

2. Create an account at [NDEx](http://ndexbio.org) if you don't have one. Then set your NDEx username and password (perhaps in `~/.profile`):

```sh
export NDEX_USER="username-for-your-ndex-account"
export NDEX_PWD="password-for-your-ndex-account"
```

3. Execute: `rm -rf cx; ./export.R AnalysisCollection ndex`

To see more options, run `./export.R --help`

FYI: we used [`xvfb-run`](http://elementalselenium.com/tips/38-headless) as a dummy display to enable running Cytoscape in headless mode.

# Troubleshooting

If you get a curl error, it's likely your session had an error and didn't shutdown correctly.

```sh
ps aux | grep Xvfb # get pid
kill -9 <pid> # use the pid from the previous step
tmux kill-session
```

# TODO
Should we use something other than `xvfb-run`?
xf86videodummy is maybe supposed to be the replacement for xvfb.
`nix-env -iA nixos.xorg.xf86videodummy`
It's also possible to [use `xpra` like `xvfb-run`](https://unix.stackexchange.com/questions/279567/how-to-use-xpra-like-xvfb-run)
`nix-env -iA nixos.xpra`

[Interesting example](https://github.com/NixOS/nixpkgs/blob/37694c8cc0e9ecab60d06f1d9a2fd0073bcc5fa3/pkgs/development/r-modules/generic-builder.nix#L29) of using R or R in X.

Why does the following command fail to fully open Cytoscape?
```sh
nohup cytoscape --rest 1234 &
```

Error running tests:

------- test.customGraphics
Opening ./sampleData/sessions/Yeast Perturbation.cys...
RCy3::commandsPOST, HTTP Error Code: 500
 url=http://localhost:1234/v1/commands/session/open
 body={
 "file": "./sampleData/sessions/Yeast Perturbation.cys" 
}
Error in commandsPOST(paste0("session open ", type, "=\"", file.location,  : 
  File 'Yeast Perturbation.cys' not found:
Calls: run.tests -> test.customGraphics -> openSession -> commandsPOST

### Headless kludge

Put job running and detach:

```
screen -R
rm -rf cx; ./export.R AnalysisCollection ndex
# Ctrl+a
# d
```

Now you can leave. To check up on the job and then close the screen:

```
screen -R
# look at what's going on. if it's good, then:
# Ctrl+a
# K
```

Input is not proper UTF-8, indicate encoding !
Bytes: 0xE6 0x6B 0x20 0x52
Error getting description in wikipathways2ndex.R:
Error: 1: Input is not proper UTF-8, indicate encoding !
Bytes: 0xE6 0x6B 0x20 0x52

wget 'https://github.com/wikipathways/cytoscape-wikipathways-app/blob/develop/WikiPathways-3.3.73.jar?raw=true' -O ~/CytoscapeConfiguration/3/apps/installed/WikiPathways-v3.3.7-3.jar
