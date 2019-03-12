library(dplyr)
library(here)
library(RCy3)
library(rjson)
library(rWikiPathways)
library(tidyr)
library(XML)

source('./unify.R')

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

installApp('WikiPathways')

wikipathways2ndex <- function(wikipathwaysID) {
	print(paste('wikipathwaysID:', wikipathwaysID))
	# TODO: why does net.suid != suid, as gotten later on?
	net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysID, '"'))

	pathwayInfo <- getPathwayInfo(wikipathwaysID)
	wikipathwaysID <- pathwayInfo[1]
	url <- pathwayInfo[2]
	name <- pathwayInfo[3]
	organism <- pathwayInfo[4]
	version <- pathwayInfo[5]

	renameNetwork(name)
	#networkName <- getNetworkName()
	#organism <- gsub(".*\\s\\-\\s", "", networkName)
	filename <- paste0(wikipathwaysID, '__', gsub("_-_", "__", gsub(" ", "_", name)))
	filepath_san_ext <- file.path(CX_OUTPUT_DIR, filename)

	pathway <- getPathway(wikipathwaysID)

	# if we get an error when trying to get description, we skip it and continue.
	description <- tryCatch({
		# TODO: can't parse GPML for WP23. Complains about encoding.
		pathwayParsed <- xmlTreeParse(pathway, asText = TRUE, useInternalNodes = TRUE, getDTD=FALSE)
		# TODO: look into formatting description as HTML. Is the string wikitext?
		# For example, '\n' could be '<br>'
		xmlSerializeHook(getNodeSet(pathwayParsed,
					 "/gpml:Pathway/gpml:Comment[@Source='WikiPathways-description']/text()",
					 c(gpml = "http://pathvisio.org/GPML/2013a")))[[1]]
	}, warning = function(w) {
		write(paste("Warning getting description in wikipathways2ndex.R:", w, sep = '\n'), stderr())
		return('')
	}, error = function(err) {
		write(paste("Error getting description in wikipathways2ndex.R:", err, sep = '\n'), stderr())
		return('')
	}, finally = {
		# Do something
	})

	metadata <- list(wikipathwaysID = wikipathwaysID,
			 version = version,
			 # TODO: should reference be to wikipathways?
			 # If yes, should it be url from above or what's below?
			 # If no, how do we choose one citation to use as a reference if we have multiple for a pathway?
			 reference = paste0('http://identifiers.org/wikipathways/', wikipathwaysID, '_r', version),
			 organism = organism,
			 author = 'WikiPathways team',
			 description = description,
			 # TODO: is this what we want?
			 # see http://dev2.ndexbio.org/v2/admin/status?format=full
			 exportFormat = "GSEA Gene Set",
			 rightsHolder = 'WikiPathways',
			 # TODO: the docs say to make our own HTML for CC0.
			 # see http://home.ndexbio.org/publishing-in-ndex/#rights
			 # which of the following options should we use?
			 # Our license language here: https://www.wikipathways.org/index.php/WikiPathways:License_Terms#The_License.2FWaiver
			 rights = 'Waiver-No Rights Reserved (CC0)',
			 #rights = '<p xmlns:dct="http://purl.org/dc/terms/"> <a rel="license" href="http://creativecommons.org/publicdomain/zero/1.0/"> <img src="http://i.creativecommons.org/p/zero/1.0/88x31.png" style="border-style: none;" alt="CC0" /> </a> <br /> To the extent possible under law, <a rel="dct:publisher" href="https://www.wikipathways.org">https://www.wikipathways.org</a> has waived all copyright and related or neighboring rights to this work. </p>',
			 networkType = 'pathway'
			 )

	ontologyTerms <- getOntologyTerms(wikipathwaysID)
	pathwayOntologyTerms <- unlist(lapply(ontologyTerms[unname(unlist(lapply(ontologyTerms, function(x) {x["ontology"] == 'Pathway Ontology'})))], function(x) {x[['name']]}))
	if (length(pathwayOntologyTerms) > 0) {
		metadata[["labels"]] <- paste(pathwayOntologyTerms, collapse = '; ')
	}

	cellTypeOntologyTerms <- unlist(lapply(ontologyTerms[unname(unlist(lapply(ontologyTerms, function(x) {x["ontology"] == 'Cell Type'})))], function(x) {x[['name']]}))
	if (length(cellTypeOntologyTerms) > 0) {
		# cell type isn't exactly tissue
		metadata[["cell"]] <- paste(cellTypeOntologyTerms, collapse = '; ')
	}

	diseaseOntologyTerms <- unlist(lapply(ontologyTerms[unname(unlist(lapply(ontologyTerms, function(x) {x["ontology"] == 'Disease'})))], function(x) {x[['name']]}))
	if (length(diseaseOntologyTerms) > 0) {
		metadata[["disease"]] <- paste(diseaseOntologyTerms, collapse = '; ')
	}

	#networkTableColumns <- getTableColumns(table = 'network')
	#print('networkTableColumns')
	#print(networkTableColumns)
	#networkTableColumnsUpdated <- data.frame("version" = version, "organism" = organism, )
	#print('networkTableColumnsUpdated')
	#print(networkTableColumnsUpdated)
	#loadTableData(networkTableColumnsUpdated, table = 'network')
    
	unify(organism)

	filepathCx <- paste0(filepath_san_ext, '.cx')
	filepathCys <- paste0(filepath_san_ext, '.cys')
	closeSession(TRUE, filename=filepath_san_ext)
	openSession(file.location=filepathCys)

	NDEX_USER <- Sys.getenv("NDEX_USER")
	NDEX_PWD <- Sys.getenv("NDEX_PWD")
	result <- list(name=name)
	if (NDEX_USER == '' || NDEX_PWD == '') {
		message <- 'Error: environment variables NDEX_USER and/or NDEX_PWD not set.'
		write(message, stderr())
		write('In your terminal, run:', stderr())
		write('export NDEX_USER=\'your-ndex-username\'', stderr())
		write('export NDEX_PWD=\'your-ndex-password\'', stderr())
		result[["success"]] <- FALSE
		result[["error"]] <- message
		result[["response"]] <- NA
	} else {
		#exportResponse <- exportNetworkToNDEx(NDEX_USER, NDEX_PWD, isPublic=TRUE)
		# NOTE: we need to use this in order to submit to the test/dev2 server.
		# exportNetworkToNDEx only submits to production server.
		suid <- getNetworkSuid(NULL, "http://localhost:1234/v1")
		print('uploading...')
		res <- cyrestPOST(paste('networks', suid, sep = '/'),
			      body = list(serverUrl="http://dev2.ndexbio.org/v2",
					  username=NDEX_USER,
					  password=NDEX_PWD,
					  metadata=metadata,
					  isPublic=TRUE),
			      base.url = "http://localhost:1234/cyndex2/v1")

		uuid <- res$data$uuid
		result[["response"]] <- uuid
		resErrors <- res$errors
		if (length(resErrors) > 0) {
			message <- paste(resErrors, sep = ' ')
			result[["error"]] <- message
			result[["success"]] <- FALSE
		} else {
			result[["error"]] <- NA
			result[["success"]] <- TRUE
		}

#		# TODO: how do we add this pathway to a network set?
#		networkSetID <- '368aff6c-45ef-11e9-9fc6-0660b7976219'
#		resNetworkSet <- cyrestPOST(paste('networkset', networkSetID, 'members', sep = '/'),
#			      body = list(serverUrl="http://dev2.ndexbio.org/v2",
#					  username=NDEX_USER,
#					  password=NDEX_PWD,
#					  networks=list(uuid)),
#			      base.url = "http://localhost:1234/cyndex2/v1")
	}

	closeSession(FALSE)
	return(result)
}
