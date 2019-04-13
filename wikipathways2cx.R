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

CX_OUTPUT_DIR = tempdir()
write(paste('Created output directory for cx:', CX_OUTPUT_DIR), stderr())

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
	# RCy3 turns a filepath like this:
	#   ./WP4566__Translational_regulation_by_PDGFRÎ±__Homo_sapies
	# into this:
	#   ./WP4566__Translational_regulation_by_PDGFR?__Homo_sapies
	# See https://github.com/cytoscape/RCy3/issues/54
	# Notice that the character
	#   'Î±'
        # takes up two bytes, but the character
	#   'a'
	# takes up just one byte.
	# RCy3 changes
	#   'Î±'
	# to
	#   '±'
	# so we pre-emptively try to do the same thing here.

	# Note that there may be cases where we get a different result from
	# RCy3, e.g., what would happen if there were two single-byte non-ASCII
	# characters next to each other?

	# Also, note that this character:
	#sub_char_final <- '±'
	# is not the same as this character:
	sub_char_final <- '?'

	sub_char_initial <- 'wp_sub_char'
	filepath_san_ext_utf8 <- file.path(CX_OUTPUT_DIR, filename)
	Encoding(filepath_san_ext_utf8) <- "UTF-8"
	filepath_san_ext <- gsub(
				 paste0('\\', sub_char_initial),
				 sub_char_final,
				 gsub(
				      paste0('\\', sub_char_initial, '\\', sub_char_initial),
				      sub_char_initial,
				      iconv(filepath_san_ext_utf8, 'UTF-8', 'ASCII', sub = sub_char_initial)
				      )
				 )

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
