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

tryCatch({
	# Launch
	system(paste0("bash ", file.path(SCRIPT_DIR, "..", "nix_rcy3", "extras", "cytoscapestart.sh")))

	source(file.path(SCRIPT_DIR, 'tests.R'))
	run.tests()
}, warning = function(w) {
	write(paste('Warning in run.R:', w, sep = '\n'), stderr())
}, error = function(e) {
	write(paste('Error in run.R:', e, sep = '\n'), stderr())
}, interrupt = function(i) {
	write(paste('Interrupted run.R:', i, sep = '\n'), stderr())
}, finally = {
	# Shutdown
	system(paste0("bash ", file.path(SCRIPT_DIR, "..", "nix_rcy3", "extras", "cytoscapestop.sh")))
})
