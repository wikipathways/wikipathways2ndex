library(dplyr)
library(purrr)
library(here)

# ndexr relies on httr but doesn't handle importing it
library(httr)
library(ndexr)

library(RCy3)
library(rjson)
library(rWikiPathways)
library(tidyr)
library(XML)
library(utf8)

# Using dev version of WikiPathways app right now, so commenting this line out:
#installApp('WikiPathways')
#system("bash ./install_dev_wikipathways_app.sh")

source('./get_citation.R')
source('./unify.R')

contextFile <- here("./context.json")
CONTEXT <- readChar(contextFile, file.info(contextFile)$size)

# TODO: should be able to get NDEX_USER_UUID from NDEX_USER or vice versa
NDEX_USER_UUID <- Sys.getenv("NDEX_USER_UUID")
NDEX_USER <- Sys.getenv("NDEX_USER")
NDEX_PWD <- Sys.getenv("NDEX_PWD")

NDEX_HOST=""
NETWORKSET_ID <- ''
if (NDEX_USER == 'wikipathways') {
	# for production
	NDEX_HOST="ndexbio.org"

	# for the set named 'wikipathways-gpml-Homo_sapiens'
	NETWORKSET_ID <- '453c1c63-5c10-11e9-9f06-0ac135e8bacf'
} else {
	# for testing
	NDEX_HOST="dev2.ndexbio.org"

#	# for the set named 'testing'
#	NETWORKSET_ID <- '7dbe0e40-5c05-11e9-831d-0660b7976219'
#
#	# for the set named 'wikipathways-gpml-Homo_sapiens'
#	NETWORKSET_ID <- 'b44b7ca7-4da1-11e9-9fc6-0660b7976219'

	# for the set named 'wikipathways-20190412-gpml-Homo_sapiens'
	NETWORKSET_ID <- '6ecc6399-5d56-11e9-831d-0660b7976219'
}

NDEX_SERVER_URL=paste0("http://", NDEX_HOST, "/v2")

ndexcon <- NA
if (NDEX_USER == '' || NDEX_PWD == '') {
	message <- 'Error: environment variables NDEX_USER and/or NDEX_PWD not set.'
	write(message, stderr())
	write('In your terminal, run:', stderr())
	write('export NDEX_USER=\'your-ndex-username\'', stderr())
	write('export NDEX_PWD=\'your-ndex-password\'', stderr())
	stop(message)
} else {
	ndexcon <- ndex_connect(username=NDEX_USER, password=NDEX_PWD, host=NDEX_HOST, ndexConf=ndex_config$Version_2.0)
	print('ndexcon')
	print(ndexcon)
}

CX_OUTPUT_DIR = tempdir()
write(paste('Created output directory for ndex:', CX_OUTPUT_DIR), stderr())

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
	if(is.function(x)) return(FALSE)
	# Some of the tests below trigger
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
cannotBeInteger <- function(x) {!grepl('^\\d+$', x)}

updateNetworkTable <- function(networkName, columnName, columnValue) {
	updatedNetworkTableColumns <- data.frame(name = networkName, columnName = columnValue, stringsAsFactors=FALSE)
	colnames(updatedNetworkTableColumns) <- c('name', columnName)
	row.names(updatedNetworkTableColumns) <- c(networkName)
	# TODO: use SUID here as matching key 
	loadTableData(updatedNetworkTableColumns, table = 'network')
}

wikipathways2ndex <- function(wikipathwaysID) {
	result <- list()
	tryCatch({
		ndexVersion = format(Sys.time(), "%Y%m%d")
		print(paste('Processing wikipathwaysID:', wikipathwaysID, '...'))

		# TODO: why does net.suid != suid, as gotten later on?
		net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysID, '"'))

		# FROM WIKIPATHWAYS APP
		networkTableColumns <- getTableColumns(table = 'network', columns = 'name,title,organism,description,pmids')

		nameInitial <- networkTableColumns[["name"]]
		title <- networkTableColumns[["title"]]
		organism <- networkTableColumns[["organism"]]
		description <- networkTableColumns[["description"]]
		raw_pmids <- networkTableColumns[["pmids"]]
		if (!is.blank(raw_pmids)) {
			pathway_raw_pmids = paste(wikipathwaysID, raw_pmids, sep = ': ')
			cat(pathway_raw_pmids, file=here("raw_pmids.txt"), append=TRUE, sep = "\n")
			pmids <- as.integer(Filter(canBeInteger, unlist(strsplit(raw_pmids, "\\s*,\\s*"))))
			if (!is.blank(pmids)) {
				pmIRIs <- paste(map(pmids, function(pmid) {
					return(paste0('pubmed:', pmid))
				}), collapse = '; ')

				updateNetworkTable(nameInitial, "pmids", pmIRIs)

				# TODO: decide with Rudi and Alex what to do here
#				# NOTE: Rudi said use the latest if there are multiple
#				pubmedID <- max(pmids)
#
#				# format as HTML IRI link
#				pubmedIRI <- paste0('https://identifiers.org/pubmed/', pubmedID)
#				metadata[["reference"]] <- makeHtmlLink(pubmedIRI, paste('PMID', pubmedID))
#
#				# format as HTML citation
#				citation <- get_citation(pubmedID)
#				metadata[["reference"]] <- citation
			}
			notpmids <- Filter(cannotBeInteger, unlist(strsplit(raw_pmids, "\\s*,\\s*")))
			if (length(notpmids) > 0) {
				pathway_text = paste(wikipathwaysID, paste(notpmids, collapse = ', '), sep = ': ')
				cat(pathway_text, file=here("notpmids.txt"), append=TRUE, sep = "\n")
			}
		}


		# FROM WEBSERVICE
		pathwayInfo <- getPathwayInfo(wikipathwaysID)
		#wikipathwaysID <- pathwayInfo[1]
		#url <- pathwayInfo[2]

		updateNetworkTable(nameInitial, "@context", list("@context"=CONTEXT))

		if (is.blank(title)) {
			title <- pathwayInfo[3]
			#write(paste("Warning: title not found by cytoscape app but was by getPathwayInfo in wikipathways2ndex.R:", title), stderr())
			updateNetworkTable(nameInitial, "title", title)
		}

		if (is.blank(organism)) {
			organism <- pathwayInfo[4]
			#write(paste("Warning: organism not found by cytoscape app but was by getPathwayInfo in wikipathways2ndex.R:", organism), stderr())
			updateNetworkTable(nameInitial, "organism", organism)
		}

		wikipathwaysVersion <- pathwayInfo[5]

		if (is.blank(description)) {
			#write("Warning: description not found by cytoscape app in wikipathways2ndex.R", stderr())
			pathway_latin1 <- getPathway(wikipathwaysID)
			Encoding(pathway_latin1) <- "latin1"
			pathway <- as_utf8(pathway_latin1)

			# if we get an error when trying to get description, we skip it and continue.
			description <- tryCatch({
				#write("Trying to get description by getPathway in wikipathways2ndex.R", stderr())
				# TODO: can't parse GPML for WP23. Complains about encoding.
				pathwayParsed <- xmlTreeParse(pathway, asText = TRUE, useInternalNodes = TRUE, getDTD=FALSE)
				# TODO: look into formatting description as HTML. Is the string wikitext?
				# For example, '\n' could be '<br>'
				descriptionCandidate <- xmlSerializeHook(getNodeSet(pathwayParsed,
							 "/gpml:Pathway/gpml:Comment[@Source='WikiPathways-description']/text()",
							 c(gpml = "http://pathvisio.org/GPML/2013a")))[[1]]
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
			#write(paste("Warning: description not found by cytoscape app but was by getPathway in wikipathways2ndex.R:", description, sep = '\n'), stderr())

			updateNetworkTable(nameInitial, "description", description)
		}

		name <- paste(wikipathwaysID, title, organism, sep = ' - ')
		wikipathwaysIRI = paste0('http://identifiers.org/wikipathways/', wikipathwaysID, '_r', wikipathwaysVersion)

		renameNetwork(name)

		# replace any non-alphanumeric characters with underscore.
		# TODO: what about dashes? BTW, the following doesn't work:
		#filename <- paste0(gsub("[^[:alnum:\\-]]", "_", name))
		filename <- paste0(gsub("[^[:alnum:]]", "_", name))
		filepath_san_ext <- file.path(CX_OUTPUT_DIR, filename)

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
				 # Disabled the following, because it's being handled by @context
#			  	 # TODO: update to be able to handle non-human
#				 organism = paste('Human', '9606', organism, sep = '; ')
				 )

		ontologyTerms <- getOntologyTerms(wikipathwaysID)
		pathwayOntologyTerms <- unlist(lapply(ontologyTerms[unname(unlist(lapply(ontologyTerms, function(x) {x["ontology"] == 'Pathway Ontology'})))], function(x) {x[['name']]}))

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

		tableColumnsPreCys <- getTableColumns()

		i <- sapply(tableColumnsPreCys, is.factor)
		tableColumnsPreCys[i] <- lapply(tableColumnsPreCys[i], as.character)


		CYTOSCAPE_NA<-""
		tableColumnsCorrected <- as.data.frame(
						       as_tibble(tableColumnsPreCys) %>%
							       replace(.=="NULL", CYTOSCAPE_NA) %>%
							       replace(.=="null", CYTOSCAPE_NA) %>%
							       replace(.=="", CYTOSCAPE_NA) %>%
							       replace(.=="NA", CYTOSCAPE_NA) %>%
							       replace(.=="<NA>", CYTOSCAPE_NA) %>%
							       replace(.==NA, CYTOSCAPE_NA) %>%
							       replace(is.null(.), CYTOSCAPE_NA) %>%
							       replace(is.na(.), CYTOSCAPE_NA)
						       )
		loadTableData(as.data.frame(tableColumnsCorrected), table.key.column = 'SUID')

#		# Some or all of these are actually Groups
#		emptyNodes <- as_tibble(tableColumnsPreCys) %>%
#			filter(is.na(GraphID) | is.null(GraphID) | GraphID == "")
#
#		selectNodes(emptyNodes$SUID)
#		deleteSelectedNodes()

		tableColumnsCorrectedLoaded <- getTableColumns()

		result[["name"]] <- name

		renameTableColumn('pmids', 'gpml:hasPublicationXref', table = 'network')
		renameTableColumn('title', 'gpml:name', table = 'network')

		suid <- getNetworkSuid(NULL, "http://localhost:1234/v1")

		networks_r <- GET(
			 paste(NDEX_SERVER_URL, 'networkset', NETWORKSET_ID, sep = '/'),
			 accept_json(),
			 authenticate(NDEX_USER, NDEX_PWD)
			 )
		stop_for_status(networks_r)
		setNetworks <- content(networks_r)$networks

		matchingNetworkIds <- (as_tibble(list(setNetworkId=setNetworks)) %>%
			mutate(data=map(setNetworkId, function(setNetworkId) {
				returned <- tryCatch({
					res <- ndex_network_get_summary(ndexcon, setNetworkId)
					externalId <- res$externalId
					isDeleted <- res$isDeleted
					properties <- res$properties
					wikipathwaysIDRow <- properties[properties$predicateString == "wikipathwaysID" , ]
					wikipathwaysID <- wikipathwaysIDRow$value
					list(externalId=externalId, wikipathwaysID=wikipathwaysID, isDeleted=isDeleted)
				}, warning = function(w) {
					write(paste("Warning getting network summary in wikipathways2ndex.R:", w, sep = '\n'), stderr())
					list(externalId=NA, wikipathwaysID=NA, isDeleted=NA)
					#NA
				}, error = function(err) {
					write(paste("Error getting network summary in wikipathways2ndex.R:", err, sep = '\n'), stderr())
					list(externalId=NA, wikipathwaysID=NA, isDeleted=NA)
					#NA
				}, finally = {
					# Do something
				})

				return(returned)
			})) %>%
			mutate(externalId=map_chr(data, "externalId")) %>%
			mutate(wikipathwaysID=map_chr(data, "wikipathwaysID")) %>%
			mutate(isDeleted=map_lgl(data, "isDeleted")) %>%
			filter(!is.na(wikipathwaysID)& wikipathwaysID == !!wikipathwaysID & !isDeleted))$externalId

		matchingNetworkCount <- length(matchingNetworkIds)

		deleteTableColumn('row.names', table = 'network')

		if (matchingNetworkCount > 0 && !is.blank(matchingNetworkIds)) {
			print('Updating...')
			if (matchingNetworkCount > 1) {
				write(paste0("Warning ", matchingNetworkCount, " matching networks (just 0 or 1 expected) in wikipathways2ndex.R. Using first and deleting the rest."), stderr())
				remainingNetworkIds <- tail(matchingNetworkIds, -1)
				for (remainingNetworkId in remainingNetworkIds) {
					ndex_network_set_systemProperties(ndexcon, remainingNetworkId, readOnly=FALSE)
					ndex_delete_network(ndexcon, remainingNetworkId)
				}
			}
			networkId <- head(matchingNetworkIds, 1)

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

#			###################################################################
#			# The code below is a kludge, because update isn't working properly
#			###################################################################
			print('Deleting...')

			# if we get an error when trying to delete, we ignore it and continue.
			tryCatch({
				ndex_delete_network(ndexcon, networkId)
			}, warning = function(w) {
				write(paste("Warning when trying to update in wikipathways2ndex.R:", w, sep = '\n'), stderr())
				NA
			}, error = function(err) {
				write(paste("Error when trying to update in wikipathways2ndex.R:", err, sep = '\n'), stderr())
				NA
			}, finally = {
				# Do something
			})

			# TODO:: the code below is the same as what's in the "else"
			# section further down in this file
			print('Re-creating...')
			res <- cyrestPOST(paste('networks', suid, sep = '/'),
				      body = list(serverUrl=NDEX_SERVER_URL,
						  username=NDEX_USER,
						  password=NDEX_PWD,
						  metadata=metadata,
						  isPublic=TRUE),
					  base.url = "http://localhost:1234/cyndex2/v1")
			result[["response"]] <- res$data$uuid
			resErrors <- res$errors
			if (length(resErrors) > 0) {
				message <- paste(resErrors, sep = ' ')
				result[["error"]] <- message
				result[["success"]] <- FALSE
			} else {
				result[["error"]] <- NA
				result[["success"]] <- TRUE
			}

#			###################################################################
#			# None of the methods below work properly.
#			# 1. cyrestPUT gives an error about encoding
#			# 2. produces a network that never displays
#			# 3. produces a  Cytoscape collection instead of an NDEx network
#			###################################################################
#
#			# 1. Update using existing libraries
#
#			#exportResponse <- updateNetworkInNDEx(NDEX_USER, NDEX_PWD, isPublic=TRUE)
#			# NOTE: we need to something else in order to submit to the test/dev2 server.
#			# updateNetworkInNDEx only submits to production server.
#
#			res <- cyrestPUT(paste('networks', suid, sep = '/'),
#				      body = list(serverUrl=NDEX_SERVER_URL,
#						  username=NDEX_USER,
#						  password=NDEX_PWD,
#						  metadata=metadata,
#						  isPublic=TRUE),
#					  base.url = "http://localhost:1234/cyndex2/v1")
#
#			# get cx and convert to rcx
#			# 2. Try getting it by posting to NDEx and downloading
#			res <- cyrestPOST(paste('networks', suid, sep = '/'),
#				      body = list(serverUrl=NDEX_SERVER_URL,
#						  username=NDEX_USER,
#						  password=NDEX_PWD,
#						  metadata=metadata,
#						  isPublic=TRUE),
#				      base.url = "http://localhost:1234/cyndex2/v1")
#			networkIdUpdatePlaceholder <- res$data$uuid
#			rcx <- ndex_get_network(ndexcon, networkIdUpdatePlaceholder)
#			# We don't need it any more
#			ndex_delete_network(ndexcon, networkIdUpdatePlaceholder)
#			rcx$networkAttributes$d[is.na(rcx$networkAttributes$d)] <- "string"
#			rcx$nodeAttributes$d[is.na(rcx$nodeAttributes$d)] <- "string"
#			rcx$edgeAttributes$d[is.na(rcx$edgeAttributes$d)] <- "string"
#			rcx$cyVisualProperties$applies_to[is.na(rcx$cyVisualProperties$applies_to)] <- 0
#			rcx <- rcx_updateMetaData(rcx)
#
##			# 3. Try getting it by exporting as CX and opening
##			#    This method isn't working. It gives this message:
##			#    "This network is part of a Cytoscape collection and cannot be operated on or edited in NDEx."
##			exportNetwork(filename=filepath_san_ext, type='CX')
##			cx <- readLines(filepathCx, warn=FALSE)
##			rcx <- rcx_fromJSON(cx)
##			#rcx <- rcx_asNewNetwork(rcx)
##			rcx$networkAttributes$d[is.na(rcx$networkAttributes$d)] <- "string"
##			rcx$nodeAttributes$d[is.na(rcx$nodeAttributes$d)] <- "string"
##			rcx$edgeAttributes$d[is.na(rcx$edgeAttributes$d)] <- "string"
##			rcx$cyTableColumn$d[is.na(rcx$cyTableColumn$d)] <- "string"
##			rcx$cyTableColumn$s[is.na(rcx$cyTableColumn$s)] <- 0
##			rcx$networkAttributes$s[is.na(rcx$networkAttributes$s)] <- 0
##			rcx$nodeAttributes$s[is.na(rcx$nodeAttributes$s)] <- 0
##			rcx$edgeAttributes$s[is.na(rcx$edgeAttributes$s)] <- 0
##			rcx$cyVisualProperties$applies_to[is.na(rcx$cyVisualProperties$applies_to)] <- 0
##			rcx$cySubNetworks <- NULL
##			rcx$cyViews <- NULL
##			rcx$cyNetworkRelations <- NULL
##			rcx$cyTableColumn <- NULL
##			rcx$cyVisualProperties$view <- NULL
##			rcx$cartesianLayout$view <- NULL
##			rcx <- rcx_updateMetaData(rcx)
#
#			print('rcx B')
#			print(str(rcx, max.level = 2))
#			networkId <- ndex_update_network(ndexcon, rcx, networkId)
#			#ndex_create_network(ndexcon, rcx)
#
#			result[["error"]] <- NA
#			result[["success"]] <- TRUE
#			result[["response"]] <- networkId
		} else {
			# NOTE: we need to use cyrestPOST in order to submit to the test/dev2 server.
			# exportNetworkToNDEx only submits to production server.
			exportNetwork(filename=filepath_san_ext, type='CX')
			print('Creating...')
			res <- cyrestPOST(paste('networks', suid, sep = '/'),
				      body = list(serverUrl=NDEX_SERVER_URL,
						  username=NDEX_USER,
						  password=NDEX_PWD,
						  metadata=metadata,
						  isPublic=TRUE),
					  base.url = "http://localhost:1234/cyndex2/v1")
			result[["response"]] <- res$data$uuid
			resErrors <- res$errors
			if (length(resErrors) > 0) {
				message <- paste(resErrors, sep = ' ')
				result[["error"]] <- message
				result[["success"]] <- FALSE
			} else {
				result[["error"]] <- NA
				result[["success"]] <- TRUE
			}
		}

		networkId <- result[["response"]]

		r <- POST(
			  paste(NDEX_SERVER_URL, 'networkset', NETWORKSET_ID, 'members', sep = '/'),
			  body = list(networkId),
			  encode = "json",
			  authenticate(NDEX_USER, NDEX_PWD)
			  )
		stop_for_status(r)

		# if we get an error when trying to make readOnly, we ignore it and continue.
		tryCatch({
			# the ndexr package doesn't support index_level="ALL", so I need to use httr instead
			#ndex_network_set_systemProperties(ndexcon, networkId, readOnly=TRUE, visibility="PUBLIC", showcase=TRUE)
			r <- PUT(
				 paste(NDEX_SERVER_URL, 'network', networkId, 'systemproperty', sep = '/'),
				 body = list(readOnly=TRUE, visibility="PUBLIC", showcase=TRUE, index_level="ALL"),
				 encode = "json",
				 authenticate(NDEX_USER, NDEX_PWD)
				 )
			stop_for_status(r)
		}, warning = function(w) {
			write(paste("Warning making network readOnly in wikipathways2ndex.R:", w, sep = '\n'), stderr())
			NA
		}, error = function(err) {
			write(paste("Error making network readOnly in wikipathways2ndex.R:", err, sep = '\n'), stderr())
			NA
		}, finally = {
			# Do something
		})
	}, warning = function(w) {
		write(paste("Warning somewhere in wikipathways2ndex.R:", w, sep = '\n'), stderr())
		NA
	}, error = function(err) {
		write(paste("Error somewhere in wikipathways2ndex.R:", err, sep = '\n'), stderr())
		message <- paste(result[["error"]], err, sep = ' ')
		result[["error"]] <- message
		result[["success"]] <- FALSE
	}, interrupt = function(i) {
		stop('Interrupted wikipathways2ndex.R')
	}, finally = {
		closeSession(FALSE)
	})

	return(result)
}
