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
source(file.path(SCRIPT_DIR, "connect.R"))
connect()
