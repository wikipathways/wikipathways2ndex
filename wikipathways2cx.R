library(dplyr)
library(here)
library(RCy3)
library(rjson)
library(rWikiPathways)
library(tidyr)

source('./unify.R')

# Using dev version at present
# https://github.com/wikipathways/cytoscape-wikipathways-app/blob/develop/WikiPathways-3.3.73.jar
#installApp('WikiPathways')
#system("bash ./install_dev_wikipathways_app.sh")
#installApp('WikiPathways')

# TODO: where should we output these files? We should allow for specifying the output location.
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

wikipathways2cx <- function(wikipathwaysID) {
	net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysID, '"'))

	pathwayInfo <- getPathwayInfo(wikipathwaysID)
	print('pathwayInfo')
	print(pathwayInfo)

	ontologyTerms <- getOntologyTerms(wikipathwaysID)
	diseaseOntologyTerms <- unlist(lapply(ontologyTerms[unname(unlist(lapply(ontologyTerms, function(x) {x["ontology"] == 'Disease'})))], function(x) {x[['name']]}))
	print('diseaseOntologyTerms')
	print(diseaseOntologyTerms)
    
	# This code gets username, but not the actual name of the user.
#	pathwayHistory <- getPathwayHistory(wikipathwaysID, 19700101)
#	print('pathwayHistory')
#	print(pathwayHistory)

	networkName <- getNetworkName()
	organism <- gsub(".*\\s\\-\\s", "", networkName)
	filename <- paste0(wikipathwaysID, '__', gsub("_-_", "__", gsub(" ", "_", networkName)))
	# TODO: when we export to CX via Cytoscape and try opening that same file with the same filepath,
       	# fromJSON gives an error for non-ASCII filepaths, e.g., any incl/ characters like Greek alpha: α
	# WP4566__Translational_regulation_by_PDGFRα__Homo_sapien
	#filepath_san_ext <- file.path(CX_OUTPUT_DIR, filename)

	filepath_san_ext_raw <- file.path(CX_OUTPUT_DIR, filename)
	Encoding(filepath_san_ext_raw) <- "UTF-8"
	#filepath_san_ext <- iconv(filepath_san_ext_raw, 'UTF-8', 'ASCII', "byte")
	#filepath_san_ext <- iconv(filepath_san_ext_raw, 'UTF-8', 'ASCII', sub = "?")
	sub_char <- "?"
	filepath_san_ext <- gsub(paste0('\\', sub_char, '\\', sub_char), sub_char, iconv(filepath_san_ext_raw, 'UTF-8', 'ASCII', sub = sub_char))

	networkTableColumns <- getTableColumns(table = 'network')
	print('networkTableColumns')
	print(networkTableColumns)
	networkTableColumnsUpdated <- data.frame("version" = c(pathwayInfo[5]), "organism")
	print('networkTableColumnsUpdated')
	print(networkTableColumnsUpdated)
	loadTableData(networkTableColumnsUpdated, table = 'network')

	# save as png
	exportImage(filepath_san_ext, 'PNG', zoom=200)

	unify(organism)

	filepathCx <- paste0(filepath_san_ext, '.cx')
	filepathCys <- paste0(filepath_san_ext, '.cys')
	#closeSession<-function(TRUE, filename=filepathCys)
	closeSessionName <- closeSession(TRUE, filename=filepath_san_ext)
	openSession(file.location=filepathCys)

	# save as cx
	exportResponse <- exportNetwork(filename=filepath_san_ext, type='CX')
	# TODO: right now, exportResponse only has one named item: 'file'.
	# But it should also include the status info from the cx. 
	# Then w could possibly just use exportResponse instead of making the
	# 'result' list further below.

	result <- list(file=filepathCx, name=networkName, response=exportResponse[["file"]])

	cx <- fromJSON(file=filepathCx)
	success <- tail(cx, n=1)[[1]]$status[[1]]$success
	result[["success"]] <- success
	if (!success) {
		result[["error"]] <- tail(cx, n=1)[[1]]$status[[1]]$error
	} else {
		result[["error"]] <- NA
	}

	closeSession(FALSE)
	return(result)
}
