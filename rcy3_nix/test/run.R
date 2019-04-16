#! /usr/bin/env nix-shell
#! nix-shell ../nix_shell_shebang_dependencies.nix -i Rscript

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

library(RCy3)

# from https://stackoverflow.com/a/15373917
thisFile <- function() {
        cmdArgs <- commandArgs(trailingOnly = FALSE)
        needle <- "--file="
        match <- grep(needle, cmdArgs)
        if (length(match) > 0) {
                # Rscript
                return(normalizePath(sub(needle, "", cmdArgs[match])))
        } else {
                # 'source'd via R console
                return(normalizePath(sys.frames()[[1]]$ofile))
        }
}
SCRIPT_DIR <- dirname(thisFile())

# Launch
system(paste0("bash ", file.path(SCRIPT_DIR, "..", "extras", "cytoscapestart.sh")))

installApp("enhancedGraphics")

source(file.path(SCRIPT_DIR, 'test_RCy3.R'))
run.tests()

source(file.path(SCRIPT_DIR, 'test_deleteTableColumn.R'))
run.tests()

# Shutdown
system(paste0("bash ", file.path(SCRIPT_DIR, "..", "extras", "cytoscapestop.sh")))
