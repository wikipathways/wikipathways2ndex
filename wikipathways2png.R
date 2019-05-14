library(dplyr)
library(here)
library(RCy3)
library(jsonlite)
library(rWikiPathways)
library(tidyr)

# Using dev version at present
# https://github.com/wikipathways/cytoscape-wikipathways-app/blob/develop/WikiPathways-3.3.73.jar
#installApp('WikiPathways')
#system("bash ./install_dev_wikipathways_app.sh")
#installApp('WikiPathways')

wikipathways2png <- function(OUTPUT_DIR, preprocessed, wikipathwaysID) {
	net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysID, '"'))

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
	filepath_san_ext_utf8 <- file.path(OUTPUT_DIR, filename)
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

	filepathPng <- paste0(filepath_san_ext, '.png')

	if (file.exists(filepathPng)) {
		stop(paste0('File already exists: ', filepathPng))
	}

	# save as png
	exportResponse <- exportImage(filepath_san_ext, 'PNG', zoom=200)

	exportResponseFile <- exportResponse[["file"]]
	if (exportResponseFile != filepathPng) {
		write(paste('Warning in wikipathways2cx.R:', exportResponseFile, 'not the same as', filepathPng, sep = '\n'), stderr())
	}

	result <- list(file=filepathPng, name=networkName, success=TRUE, error=NA)

	closeSession(FALSE)
	return(result)
}
