# Usage

It's possible to use this from a remote computer, like this:

In one terminal:
```sh
ssh -Y wikipathways-workspace.gladstone.internal
cd wikipathways2ndex
nix-shell
cytoscape --rest 1234
```

Note: the following command will fail to fully open Cytoscape:
```sh
nohup cytoscape --rest 1234 &
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

