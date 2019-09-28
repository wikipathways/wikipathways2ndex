library(dplyr)
library(here)
library(RCy3)
library(jsonlite)
library(rWikiPathways)
library(tidyr)

source('./wikipathways_extra.R')
source('./extra.R')

# Using dev version at present
# https://github.com/wikipathways/cytoscape-wikipathways-app/blob/develop/WikiPathways-3.3.73.jar
#installApp('WikiPathways')
#system("bash ./install_dev_wikipathways_app.sh")
#installApp('WikiPathways')

wikipathways2cx <- function(OUTPUT_DIR, preprocessed, wikipathwaysID) {
	result <- load_wikipathways_pathway(wikipathwaysID)
    
	networkName <- getNetworkName()
	organism <- gsub(".*\\s\\-\\s", "", networkName)
	filename <- paste0(wikipathwaysID, '__', gsub("_-_", "__", gsub(" ", "_", networkName)))
	filepath_san_ext <- getFilepathSanExt(OUTPUT_DIR, filename)
	filepathCx <- paste0(filepath_san_ext, '.cx')

	# save as cx
	# TODO: right now, exportResponse only has one named item: 'file'.
	# But it should also include the status info from the cx. 
	exportResponse <- exportNetwork(filename=filepath_san_ext, type='CX')

	exportResponseFile <- exportResponse[["file"]]
	if (exportResponseFile != filepathCx) {
		write(paste('Warning in wikipathways2cx.R:', exportResponseFile, 'not the same as', filepathCx, sep = '\n'), stderr())
	}

	result <- list(output=filepathCx, name=networkName)

	cx <- fromJSON(filepathCx)

	success <- tail(cx$status, n=1)[[1]]$success
	result[["success"]] <- success
	if (!success) {
		result[["error"]] <- tail(cx$status, n=1)[[1]]$error
	} else {
		result[["error"]] <- NA
	}

	closeSession(FALSE)
	return(result)
}
