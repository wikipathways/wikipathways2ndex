library(dplyr)
library(here)
library(RCy3)
library(rjson)
library(tidyr)

source('./connect.R')
connect()
source('./unify.R')

# TODO: where should we output these files? We should allow for specifying the output location.
#CX_OUTPUT_DIR = file.path(Sys.getenv('HOME'), 'wikipathways2ndex', 'cx')
CX_OUTPUT_DIR = here('cx')
if (!dir.exists(CX_OUTPUT_DIR)) {
	write(paste('Warning: Directory', CX_OUTPUT_DIR, 'does not exist. Creating now.'), stderr())
	dir.create(CX_OUTPUT_DIR)
} else {
	# TODO: is there a better way to check for an empty directory?
	# NOTE: length must be greater than 2, b/c the list always includes '.' and '..'
	if(length(dir(CX_OUTPUT_DIR, all.files=TRUE)) > 2) {
		stop(paste('Error for wikipathways2cx in wikipathways2cx.R: output dir', CX_OUTPUT_DIR, 'must be empty.'))
	}
}

installApp('WikiPathways')

wikipathways2cx <- function(wikipathwaysId) {
	net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysId, '"'))

	networkName <- getNetworkName()
	organism <- gsub(".*\\s\\-\\s", "", networkName)
	filename <- paste0(wikipathwaysId, '__', gsub("_-_", "__", gsub(" ", "_", networkName)))
	filepath_san_ext <- file.path(CX_OUTPUT_DIR, filename)

	# save as png
	exportImage(here(filename), 'PNG', zoom=200)
	# TODO:: It appears the file must be in the cwd. If I do this:
	#exportImage(here('cx', filename), 'PNG', zoom=200)
	# I get this error:
	# parse error: Invalid numeric literal at line 1, column 5

	unify(organism)

	# save as cx
	exportResponse <- exportNetwork(filename=filepath_san_ext, type='CX')
	# TODO: right now, exportResponse only has one named item: 'file'.
	# But it should also include the status info from the cx. 
	# Then w could possibly just use exportResponse instead of making the
	# 'response' list further below.

	filepathCx <- paste0(filepath_san_ext, '.cx')

	response <- list(file=filepathCx)

	cx <- fromJSON(file=filepathCx)
	success <- tail(cx, n=1)[[1]]$status[[1]]$success
	response[["success"]] <- success
	if (!success) {
		response[["error"]] <- tail(cx, n=1)[[1]]$status[[1]]$error
	} else {
		response[["error"]] <- NA
	}

	closeSession(FALSE)
	return(response)
}
