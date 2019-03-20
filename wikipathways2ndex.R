library(dplyr)
library(here)
library(ndexr)
library(RCy3)
library(rjson)
library(rWikiPathways)
library(tidyr)
library(XML)
library(utf8)

# Using dev version at present
# https://github.com/wikipathways/cytoscape-wikipathways-app/blob/develop/WikiPathways-3.3.73.jar
#installApp('WikiPathways')
#system("bash ./install_dev_wikipathways_app.sh")

source('./unify.R')

NDEX_USER_UUID <- 'ae4b1027-1900-11e9-9fc6-0660b7976219'
NDEX_USER <- Sys.getenv("NDEX_USER")
NDEX_PWD <- Sys.getenv("NDEX_PWD")

ndexcon <- NA
if (NDEX_USER == '' || NDEX_PWD == '') {
	message <- 'Error: environment variables NDEX_USER and/or NDEX_PWD not set.'
	write(message, stderr())
	write('In your terminal, run:', stderr())
	write('export NDEX_USER=\'your-ndex-username\'', stderr())
	write('export NDEX_PWD=\'your-ndex-password\'', stderr())
	stop(message)
} else {
	ndexcon <- ndex_connect(username=NDEX_USER, password=NDEX_PWD, host="dev2.ndexbio.org", ndexConf=ndex_config$Version_2.0)
}

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

# TODO: should we set the following?
#options(encoding = "UTF-8")

makeHtmlLink <- function(IRI, text = '') {
	if (text == '') {
		text <- IRI
	}
	htmlLink <- paste0('<a href="', IRI, '">', text, '</a>')
	return(htmlLink)
}

# see https://stackoverflow.com/a/19655909
is.blank <- function(x, false.triggers=FALSE){
	    if(is.function(x)) return(FALSE) # Some of the tests below trigger
                                     # warnings when used on functions
    return(
	           is.null(x) ||                # Actually this line is unnecessary since
			           length(x) == 0 ||            # length(NULL) = 0, but I like to be clear
					           all(is.na(x)) ||
							           all(x=="") ||
								           (false.triggers && all(!x))
								       )
}

canBeInteger <- function(x) {grepl('^\\d+$', x)}

updateNetworkTable <- function(currentNetworkTableColumns, columnName, columnValue) {
	updatedNetworkTableColumns <- data.frame(columnName = columnValue, stringsAsFactors=FALSE)
	row.names(updatedNetworkTableColumns) <- row.names(currentNetworkTableColumns)
	loadTableData(updatedNetworkTableColumns, table = 'network', data.key.column = 'row.name', table.key.column = 'row.name')
}

wikipathways2ndex <- function(wikipathwaysID) {
	result <- list()
	tryCatch({
		ndexVersion = format(Sys.time(), "%Y%m%d")
		print(paste('Processing wikipathwaysID:', wikipathwaysID, '...'))

		# TODO: why does net.suid != suid, as gotten later on?
		net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysID, '"'))

		networks <- ndex_user_get_networksummary(ndexcon, userId=NDEX_USER_UUID)

#		print('names(networks)')
#		print(names(networks))
#		print('head(networks, n = 1)')
#		print(head(networks, n = 1))

		# FROM WIKIPATHWAYS APP
		networkTableColumns <- getTableColumns(table = 'network', columns = 'name,title,organism,description,pmids')
#		print('networkTableColumns')
#		print(networkTableColumns)

#		networkTableColumns1 <- getTableColumns(table = 'network')
#		print('networkTableColumns1')
#		print(networkTableColumns1)

		title <- networkTableColumns[["title"]]
		organism <- networkTableColumns[["organism"]]
		description <- networkTableColumns[["description"]]
		#pmids <- as.integer(unlist(strsplit(networkTableColumns[["pmids"]], "\\s*,\\s*")))
		pmids <- NA
		raw_pmids <- networkTableColumns[["pmids"]]
		if (is.blank(raw_pmids)) {
			write("Warning: pmids not found by cytoscape app in wikipathways2ndex.R", stderr())
		} else {
			#pmids <- as.integer(unlist(strsplit(raw_pmids, "\\s*,\\s*")))
			pmids <- as.integer(Filter(canBeInteger, unlist(strsplit(raw_pmids, "\\s*,\\s*"))))
		}

		# FROM WEBSERVICE
		pathwayInfo <- getPathwayInfo(wikipathwaysID)
		#wikipathwaysID <- pathwayInfo[1]
		#url <- pathwayInfo[2]
		if (is.blank(title)) {
			title <- pathwayInfo[3]
			write(paste("Warning: title not found by cytoscape app but was by getPathwayInfo in wikipathways2ndex.R:", title), stderr())
		}
		if (is.blank(organism)) {
			organism <- pathwayInfo[4]
			write(paste("Warning: organism not found by cytoscape app but was by getPathwayInfo in wikipathways2ndex.R:", organism), stderr())
		}
		wikipathwaysVersion <- pathwayInfo[5]

		name <- paste(wikipathwaysID, title, organism, sep = ' - ')
		wikipathwaysIRI = paste0('http://identifiers.org/wikipathways/', wikipathwaysID, '_r', wikipathwaysVersion)

		renameNetwork(name)

		# replace any non-alphanumeric characters with underscore.
		# TODO: what about dashes? BTW, the following doesn't work:
		#filename <- paste0(gsub("[^[:alnum:\\-]]", "_", name))
		filename <- paste0(gsub("[^[:alnum:]]", "_", name))
		filepath_san_ext <- file.path(CX_OUTPUT_DIR, filename)

		if (is.blank(description)) {
			write("Warning: description not found by cytoscape app in wikipathways2ndex.R", stderr())
			pathway_latin1 <- getPathway(wikipathwaysID)
			Encoding(pathway_latin1) <- "latin1"
			pathway <- as_utf8(pathway_latin1)

			# if we get an error when trying to get description, we skip it and continue.
			description <- tryCatch({
				write("Trying to get description by getPathway in wikipathways2ndex.R", stderr())
				# TODO: can't parse GPML for WP23. Complains about encoding.
				pathwayParsed <- xmlTreeParse(pathway, asText = TRUE, useInternalNodes = TRUE, getDTD=FALSE)
				# TODO: look into formatting description as HTML. Is the string wikitext?
				# For example, '\n' could be '<br>'
				descriptionCandidate <- xmlSerializeHook(getNodeSet(pathwayParsed,
							 "/gpml:Pathway/gpml:Comment[@Source='WikiPathways-description']/text()",
							 c(gpml = "http://pathvisio.org/GPML/2013a")))[[1]]
				write(descriptionCandidate, stderr())
				descriptionCandidate
			}, warning = function(w) {
				write(paste("Warning getting description in wikipathways2ndex.R:", w, sep = '\n'), stderr())
				return('')
			}, error = function(err) {
				write(paste("Error getting description in wikipathways2ndex.R:", err, sep = '\n'), stderr())
				return('')
			}, finally = {
				# Do something
			})
			write(paste("Warning: description not found by cytoscape app but was by getPathway in wikipathways2ndex.R:", description, sep = '\n'), stderr())
			#loadTableData(data.frame(c("description",), c(description,)), table = 'network')
			#loadTableData(data.frame("description" = c(description,),), table = 'network')
			#loadTableData(data.frame("description" = c(description), "dummy" = c("abc"), ), table = 'network')
			#networkTableColumnsCandidate <- data.frame("name" = name, "description" = description)


			print('networkTableColumns')
			print(networkTableColumns)

			#updateNetworkTable(networkTableColumns, "description", "mydescription")

			networkTableColumnsCandidate <- data.frame("name" = name, "description" = "mydescription", stringsAsFactors=FALSE)
			#row.names(networkTableColumnsCandidate) <- row.names(networkTableColumns)
			#row.names(networkTableColumns) <- c(80)
			row.names(networkTableColumnsCandidate) <- c(440)

			print('networkTableColumnsCandidate')
			print(networkTableColumnsCandidate)

			print('loading...')
			#loadTableData(networkTableColumnsCandidate, table = 'network', data.key.column = 'row.names', table.key.column = 'row.names')
			loadTableData(networkTableColumnsCandidate, table = 'network', data.key.column = 'name', table.key.column = 'name')
			#loadTableData(networkTableColumnsCandidate, table = 'network')

#			networkTableColumnsAfter2 <- getTableColumns(table = 'network')
#			print('networkTableColumnsAfter2')
#			print(networkTableColumnsAfter2)

			networkTableColumnsAfter <- getTableColumns(table = 'network', columns = 'name,title,organism,description,pmids')
			print('networkTableColumnsAfter')
			print(networkTableColumnsAfter)

		}

		# TODO: should we reference DataNodes of type Pathway with WithPathways IDs as NDEx subnetworks?
		metadata <- list(author = 'WikiPathways team',
				 wikipathwaysIRI = makeHtmlLink(wikipathwaysIRI),
				 wikipathwaysID = wikipathwaysID,
				 wikipathwaysVersion = wikipathwaysVersion,
				 version = ndexVersion,
				 rightsHolder = 'WikiPathways',
				 # TODO: the docs say to make our own HTML for CC0.
				 # see http://home.ndexbio.org/publishing-in-ndex/#rights
				 # which of the following options should we use?
				 # Our license language here: https://www.wikipathways.org/index.php/WikiPathways:License_Terms#The_License.2FWaiver
				 rights = 'Waiver-No Rights Reserved (CC0)',
				 #rights = '<p xmlns:dct="http://purl.org/dc/terms/"> <a rel="license" href="http://creativecommons.org/publicdomain/zero/1.0/"> <img src="http://i.creativecommons.org/p/zero/1.0/88x31.png" style="border-style: none;" alt="CC0" /> </a> <br /> To the extent possible under law, <a rel="dct:publisher" href="https://www.wikipathways.org">https://www.wikipathways.org</a> has waived all copyright and related or neighboring rights to this work. </p>',
				 networkType = 'pathway'
				 )
				 # these are inserted as network columns by the WikiPathways app:
				 #title = title,
				 #organism = organism,
				 #description = description,

		ontologyTerms <- getOntologyTerms(wikipathwaysID)
		pathwayOntologyTerms <- unlist(lapply(ontologyTerms[unname(unlist(lapply(ontologyTerms, function(x) {x["ontology"] == 'Pathway Ontology'})))], function(x) {x[['name']]}))

		if (!is.blank(pmids)) {
			# NOTE: Rudi said use the latest if there are multiple
			pubmedID <- max(pmids)
			pubmedIRI <- paste0('https://identifiers.org/pubmed/', pubmedID)
			metadata[["reference"]] <- makeHtmlLink(pubmedIRI, paste('PMID', pubmedID))
		}

		if (length(pathwayOntologyTerms) > 0) {
			metadata[["labels"]] <- paste(append(c(wikipathwaysID), pathwayOntologyTerms), collapse = '; ')
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

#		networkTableColumns <- getTableColumns(table = 'network')
#		print('networkTableColumns')
#		print(networkTableColumns)
		#networkTableColumnsUpdated <- data.frame("version" = ndexVersion, "organism" = organism, )
		#print('networkTableColumnsUpdated')
		#print(networkTableColumnsUpdated)
		#loadTableData(networkTableColumnsUpdated, table = 'network')
	    
		# if we get an error when trying to unify, we skip it and continue.
		tryCatch({
			# TODO: can't unify WP715, because it only has metabolites. Complains about HGNC column missing.
			unify(organism)
		}, warning = function(w) {
			write(paste("Warning during unify in wikipathways2ndex.R:", w, sep = '\n'), stderr())
			NA
		}, error = function(err) {
			write(paste("Error during unify in wikipathways2ndex.R:", err, sep = '\n'), stderr())
			NA
		}, finally = {
			# Do something
		})

		filepathCx <- paste0(filepath_san_ext, '.cx')
		filepathCys <- paste0(filepath_san_ext, '.cys')

		closeSession(TRUE, filename=filepath_san_ext)
		openSession(file.location=filepathCys)

		result[["name"]] <- name
		#exportResponse <- exportNetworkToNDEx(NDEX_USER, NDEX_PWD, isPublic=TRUE)
		# NOTE: we need to use this in order to submit to the test/dev2 server.
		# exportNetworkToNDEx only submits to production server.
		suid <- getNetworkSuid(NULL, "http://localhost:1234/v1")

		#networks <- ndex_find_networks(ndexcon, searchString=title, owner='ariutta')
		# http://dev2.ndexbio.org/#/user/ae4b1027-1900-11e9-9fc6-0660b7976219
		#networks <- ndex_find_networks(ndexcon, searchString=title)
		#networks <- ndex_find_networks(ndexcon, searchString=title, accountName='ae4b1027-1900-11e9-9fc6-0660b7976219')
		#networks <- ndex_find_networks(ndexcon, accountName='ae4b1027-1900-11e9-9fc6-0660b7976219')
		#networks <- ndex_find_networks(ndexcon, accountName='ariutta')
		#networks <- ndex_user_get_showcase(ndexcon, userId=NDEX_USER_UUID)
		networks <- ndex_user_get_networksummary(ndexcon, userId=NDEX_USER_UUID)

		matchingNetworks <- as_tibble(networks) %>%
			filter(grepl(paste0('wikipathways\\/', wikipathwaysID), wikipathwaysID) | grepl(paste0(wikipathwaysID, '\\s'), name)) %>%
			filter(version == ndexVersion) %>%
			filter(!isDeleted)

		print('matchingNetworks')
		print(matchingNetworks)

		matchingNetworkCount <- length(matchingNetworks)
		if (matchingNetworkCount > 0 && !is.blank(matchingNetworks)) {
			print('Updating...')
			if (matchingNetworkCount > 1) {
				write(paste0("Warning ", matchingNetworkCount, " matching networks (no more than 1 expected) in wikipathways2ndex.R:"), stderr())
			}
			networkId <- (matchingNetworks %>% head(1))[["externalId"]]
			# get cx and convert to rcx
			exportNetwork(filename=filepath_san_ext, type='CX')
			cx <- readLines(filepathCx, warn=FALSE)
			rcx <- rcx_fromJSON(cx)

			# if we get an error when trying to make editable, we ignore it and continue.
			tryCatch({
				ndex_network_set_systemProperties(ndexcon, networkId, readOnly=FALSE)
			}, warning = function(w) {
				write(paste("Warning making network editable in wikipathways2ndex.R:", w, sep = '\n'), stderr())
				NA
			}, error = function(err) {
				write(paste("Error making network editable in wikipathways2ndex.R:", err, sep = '\n'), stderr())
				NA
			}, finally = {
				# Do something
			})

			print('networkId before')
			print(networkId)
			networkId <- ndex_update_network(ndexcon, rcx, networkId)
			#ndex_delete_network(ndexcon, networkId)
			print('networkId after')
			print(networkId)

			result[["error"]] <- NA
			result[["success"]] <- TRUE

#			write('TODO: fix error about "type null not supported"', stderr())
#			message <- 'Error: "type null not supported"'
#			result[["error"]] <- message
#			result[["success"]] <- FALSE

			result[["response"]] <- networkId

			# if we get an error when trying to make readOnly, we ignore it and continue.
			tryCatch({
				ndex_network_set_systemProperties(ndexcon, networkId, readOnly=TRUE, visibility="PUBLIC", showcase=TRUE)
			}, warning = function(w) {
				write(paste("Warning making network readOnly in wikipathways2ndex.R:", w, sep = '\n'), stderr())
				NA
			}, error = function(err) {
				write(paste("Error making network readOnly in wikipathways2ndex.R:", err, sep = '\n'), stderr())
				NA
			}, finally = {
				# Do something
			})
		} else {
			print('Creating...')
			res <- cyrestPOST(paste('networks', suid, sep = '/'),
				      body = list(serverUrl="http://dev2.ndexbio.org/v2",
						  username=NDEX_USER,
						  password=NDEX_PWD,
						  metadata=metadata,
						  isPublic=TRUE),
				      base.url = "http://localhost:1234/cyndex2/v1")

			networkId <- res$data$uuid
			result[["response"]] <- networkId
			resErrors <- res$errors
			if (length(resErrors) > 0) {
				message <- paste(resErrors, sep = ' ')
				result[["error"]] <- message
				result[["success"]] <- FALSE
			} else {
				result[["error"]] <- NA
				result[["success"]] <- TRUE
				# if we get an error when trying to make readOnly, we ignore it and continue.
				tryCatch({
					ndex_network_set_systemProperties(ndexcon, networkId, readOnly=TRUE, visibility="PUBLIC", showcase=TRUE)
				}, warning = function(w) {
					write(paste("Warning making network readOnly in wikipathways2ndex.R:", w, sep = '\n'), stderr())
					NA
				}, error = function(err) {
					write(paste("Error making network readOnly in wikipathways2ndex.R:", err, sep = '\n'), stderr())
					NA
				}, finally = {
					# Do something
				})
			}
		}

	#		# TODO: how do we add this pathway to a network set?
	#		networkSetID <- '368aff6c-45ef-11e9-9fc6-0660b7976219'
	#		resNetworkSet <- cyrestPOST(paste('networkset', networkSetID, 'members', sep = '/'),
	#			      body = list(serverUrl="http://dev2.ndexbio.org/v2",
	#					  username=NDEX_USER,
	#					  password=NDEX_PWD,
	#					  networks=list(uuid)),
	#			      base.url = "http://localhost:1234/cyndex2/v1")
	}, warning = function(w) {
		write(paste("Warning somewhere in wikipathways2ndex.R:", w, sep = '\n'), stderr())
		NA
	}, error = function(err) {
		write(paste("Error somewhere in wikipathways2ndex.R:", err, sep = '\n'), stderr())
		message <- paste(result[["error"]], err, sep = ' ')
		result[["error"]] <- message
		result[["success"]] <- FALSE
	}, interrupt = function(i) {
		#write(paste('Interrupted wikipathways2ndex.R:', i, sep = '\n'), stderr())
		stop('Interrupted wikipathways2ndex.R')
	}, finally = {
		closeSession(FALSE)
	})

	return(result)
}
