library(dplyr)
library(purrr)
library(here)

# ndexr relies on httr but doesn't handle importing it
library(httr)
library(ndexr)

if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
if (!requireNamespace("rWikiPathways", quietly = TRUE))
  BiocManager::install("rWikiPathways")


library(RCy3)
library(jsonlite)
library(rWikiPathways)
library(tidyr)
library(XML)
library(utf8)

# Using dev version of WikiPathways app right now, so commenting this line out:
#installApp('WikiPathways')
#system("bash ./install_dev_wikipathways_app.sh")

source('./wikipathways_extra.R')
source('./extra.R')

MARKER_MAPPINGS <- fromJSON('./MarkerMappings.json')
VALUE_MAPPINGS <- fromJSON('./ValueMappings.json')
SBO_IRI_BY_TERM <- fromJSON('./interaction-type.jsonld')[['@context']]
TERM_BY_SBO_IRI <- SBO_IRI_BY_TERM %>%
  lmap(function(x) {
    term <- names(x)
    IRI <- unlist(x)
    result <- list()
    result[[IRI]] <- term
    return(result)
  })

# TODO: should be able to get NDEX_USER_UUID from NDEX_USER or vice versa
NDEX_USER_UUID <- Sys.getenv("NDEX_USER_UUID")
NDEX_USER <- Sys.getenv("NDEX_USER")
NDEX_PWD <- Sys.getenv("NDEX_PWD")

if (NDEX_USER == '' || NDEX_PWD == '') {
  NDEX_USER <- readline('Enter your NDEx username: ')
  NDEX_PWD <- readline('Enter your NDEx password: ')
  if (NDEX_USER == '' || NDEX_PWD == '') {
    message <- 'Error: environment variables NDEX_USER and/or NDEX_PWD not set.'
    write(message, stderr())
    write('In your terminal, run:', stderr())
    write('export NDEX_USER=\'your-ndex-username\'', stderr())
    write('export NDEX_PWD=\'your-ndex-password\'', stderr())
    stop(message)
  }
}

NDEX_HOST=""
NETWORKSET_ID <- ''
if (NDEX_USER == 'wikipathways') {
	# for production
	NDEX_HOST="ndexbio.org"

	# for the set named 'testing' on the production server
	#NETWORKSET_ID <- '49867158-6dd5-11e9-848d-0ac135e8bacf'

	# for the set named 'WikiPathways Collection - Homo sapiens' on the production server
	NETWORKSET_ID <- '453c1c63-5c10-11e9-9f06-0ac135e8bacf'
} else {
	# for testing
	NDEX_HOST="test.ndexbio.org"

	# for the set named 'testing' on the test server
	#NETWORKSET_ID <- '7dbe0e40-5c05-11e9-831d-0660b7976219'

	# for the set named 'WikiPathways Collection - Homo sapiens' on the test server
	NETWORKSET_ID <- 'b44b7ca7-4da1-11e9-9fc6-0660b7976219'
}

NDEX_SERVER_URL=paste0("http://", NDEX_HOST, "/v2")

RCY3_SUPPORTED_NDEX_HOSTS <- c("ndexbio.org", "test.ndexbio.org")

ndexcon <- ndex_connect(username=NDEX_USER, password=NDEX_PWD, host=NDEX_HOST, ndexConf=ndex_config$Version_2.0)

# TODO: should we set the following?
#options(encoding = "UTF-8")

makeHtmlLink <- function(IRI, text = '') {
	if (text == '') {
		text <- IRI
	}
	htmlLink <- paste0('<a href="', IRI, '">', text, '</a>')
	return(htmlLink)
}

# returns a list of network ids
getNetworksInSet <- function(networksetId) {
	networks <- list()
	tryCatch({
		networks_r <- GET(
			 paste(NDEX_SERVER_URL, 'networkset', networksetId, sep = '/'),
			 accept_json(),
			 authenticate(NDEX_USER, NDEX_PWD)
			 )
		stop_for_status(networks_r)
		networksInSet <- content(networks_r)$networks

		networks <- as_tibble(list(networkIdInSet=networksInSet)) %>%
			mutate(data=map(networkIdInSet, function(networkIdInSet) {
				returned <- tryCatch({
					res <- ndex_network_get_summary(ndexcon, networkIdInSet)
					externalId <- res$externalId
					isDeleted <- res$isDeleted
					properties <- res$properties
					wikipathwaysIDRow <- properties[properties$predicateString == "wikipathwaysID" , ]
					wikipathwaysID <- wikipathwaysIDRow$value
					
					# wikipathwaysID can be logical(0)
					if (length(wikipathwaysID) == 0 || wikipathwaysID == "") {
					  print(paste("Missing wikipathwaysID for network ", externalId))
					}
					
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
			  mutate(isDeleted=map_lgl(data, "isDeleted"))

	}, warning = function(w) {
		write(paste("Warning in getNetworksInSet in wikipathways2ndex.R:", w, sep = '\n'), stderr())
		NA
	}, error = function(err) {
		write(paste("Error in getNetworksInSet in wikipathways2ndex.R:", err, sep = '\n'), stderr())
	}, interrupt = function(i) {
		stop('Interrupted in getNetworksInSet in wikipathways2ndex.R')
	}, finally = {
		# Do something?
	})

	return(networks)
}

prepareNetworkSet <- function(networksetId) {
	print('Preparing network set...')

	networks <- getNetworksInSet(networksetId)
	return(networks)
}

wikipathways2ndexPreprocess <- function() {
	networks <- prepareNetworkSet(NETWORKSET_ID)
	return(list(networksInSet=networks))
}

wikipathways2ndex <- function(OUTPUT_DIR, preprocessed, wikipathwaysID) {
	networksInSet <- preprocessed$networksInSet
	
	result <- list()
	tryCatch({
		print(paste('Processing wikipathwaysID:', wikipathwaysID, '...'))
		result <- load_wikipathways_pathway(wikipathwaysID)

		if (!(NDEX_HOST %in% RCY3_SUPPORTED_NDEX_HOSTS)) {
		  stop(paste0(
		    "Error: ",
		    NDEX_HOST,
		    " not in RCY3_SUPPORTED_NDEX_HOSTS."
		  ))
		}		
		
		networkTableColumnNames <- getTableColumnNames(table = 'network')
		networkTableColumns <- getTableColumns(table = 'network', columns = 'wikipathwaysIRI,name,title,organism,description')

		nameForCytoscape <- networkTableColumns[["name"]]
		title <- networkTableColumns[["title"]]
		organism <- networkTableColumns[["organism"]]
		description <- networkTableColumns[["description"]]

		nameForNDEx <- paste(wikipathwaysID, title, organism, sep = ' - ')
		renameNetwork(nameForNDEx)

		updateNetworkTable(nameForNDEx, "rightsHolder", 'WikiPathways')

		# TODO: the NDEx docs say to make our own HTML for CC0:
		# http://home.ndexbio.org/publishing-in-ndex/#rights
		# But Rudi or Alex said to just use the CC0 string.
		renameTableColumn('license', 'rights', table = 'network')

		updateNetworkTable(nameForNDEx, "author", 'WikiPathways team')

		# version for NDEx is a datestamp
		updateNetworkTable(nameForNDEx, "version", format(Sys.time(), "%Y%m%d"))

		updateNetworkTable(nameForNDEx, "networkType", 'pathway')

		nodeTableColumnNames <- getTableColumnNames()
		edgeTableColumnNames <- getTableColumnNames(table = 'edge')

		# Only map Ensembl to HGNC for Human, because we can't run
		# mapTableColumn for a batch containing both mouse and human
		# pathways.
		#
		# These work:
		# * WP1 alone (mouse)
		# * WP241 alone (human)
		# * WP241, WP550, WP554 (human)
		#
		# But this fails:
		# * WP1 (mouse) and WP241 (human)
		#
		# TODO: look at changing export.R to group pathways by organism so that
		# every pathway in any given batch has the same organism as the other
	       	# pathways in that batch.
		if (organism == 'Homo sapiens') {
			sourceColumnName <- 'Ensembl'
			targetColumnName <- 'HGNC'

			# if we get an error when trying to make node names use HGNC, we skip it and continue.
			tryCatch({
				# TODO: can we get rid of the check for the Ensembl column?
				if (sourceColumnName %in% nodeTableColumnNames) {
					nodeTableColumns <- getTableColumns()
					#if (!is.blank(nodeTableColumns$Ensembl)) {}
					if (!is.blank(nodeTableColumns[sourceColumnName])) {
						mapTableColumn(sourceColumnName, organism, sourceColumnName, targetColumnName)

						hgncified <- as_tibble(getTableColumns()) %>%
							mutate("__gpml:textlabel"=name) %>%
							mutate(name=ifelse(is.na(HGNC), name, HGNC))

						## TODO: why do neither of the two lines below correctly update the name column?
						## For example, try converting WP554 and verify that prostacyclin is now named GALNT13.
						## But further update: that's wrong. prostacyclin is a metabolite.
						#loadTableData(as.data.frame(hgncified))
						#loadTableData(as.data.frame(hgncified), table.key.column = 'SUID')

						## Maybe I need it's something about tidyr not using row names?
						## We could take a look at using something like this:
						## column_to_rownames(hgncified_df, var = "SUID")

						# The following code does work, but couldn't it be simplified?
						hgncified_df <- as.data.frame(hgncified)
						row.names(hgncified_df) <- hgncified_df[["SUID"]]
						loadTableData(hgncified_df, table.key.column = 'SUID')
						nodeTableColumnNames <- getTableColumnNames()
					}
				}
			}, warning = function(w) {
				write(paste("Warning using HGNC for node names in wikipathways2ndex.R:", w, sep = '\n'), stderr())
				NA
			}, error = function(err) {
				write(paste("Error using HGNC for node names in wikipathways2ndex.R:", err, sep = '\n'), stderr())
				NA
			}, finally = {
				# Do something
			})
		}

		if ('StartArrow' %in% edgeTableColumnNames && 'EndArrow' %in% edgeTableColumnNames) {
			tryCatch({
				edgeTable <- as_tibble(getTableColumns(table = 'edge')) %>%
					mutate(start_normalized=map_chr(StartArrow, function(StartArrow) {
						normalized <- ''
						if (hasName(VALUE_MAPPINGS, StartArrow)) {
							normalized <- VALUE_MAPPINGS[[StartArrow]]
						} else {
							write(paste("Warning: no normalized for StartArrow ", StartArrow, " in wikipathways2ndex.R:", w, sep = '\n'), stderr())
							normalized <- 'none'
						}
						return(normalized)
					})) %>%
					mutate(end_normalized=map_chr(EndArrow, function(EndArrow) {
						normalized <- ''
						if (hasName(VALUE_MAPPINGS, EndArrow)) {
							normalized <- VALUE_MAPPINGS[[EndArrow]]
						} else {
							write(paste("Warning: no normalized for EndArrow ", EndArrow, " in wikipathways2ndex.R:", w, sep = '\n'), stderr())
							normalized <- 'none'
						}
						return(normalized)
					})) %>%
					mutate(normalized=ifelse(end_normalized != 'none', end_normalized, start_normalized)) %>%
					mutate(sboType=map_chr(normalized, function(normalized) {
						sboType <- NA
						if (hasName(MARKER_MAPPINGS[[normalized]], 'sbo')) {
							sboType <- MARKER_MAPPINGS[[normalized]][['sbo']]
						} else {
							sboType <- 'SBO:0000374'
						}
						return(paste0(sboType, collapse = ', '))
						#return(toJSON(sboType, auto_unbox = TRUE))
					})) %>%
					mutate(type=map_chr(normalized, function(normalized) {
						biopaxTypes <- c()
						if (hasName(MARKER_MAPPINGS[[normalized]], 'bp')) {
							biopaxType <- paste0('biopax:', MARKER_MAPPINGS[[normalized]][['bp']][['name']])
							biopaxTypes <- c(biopaxType)
						}

						sboTypes <- c()
						if (hasName(MARKER_MAPPINGS[[normalized]], 'sbo')) {
							sboTypes <- MARKER_MAPPINGS[[normalized]][['sbo']]
						} else {
							sboTypes <- c('SBO:0000374')
						}

						sboTypeLinks <- sboTypes %>%
							map(function(sboType) {
								IRI <- paste0("http://identifiers.org/biomodels.sbo/", sboType)
								sboTypeLink <- makeHtmlLink(IRI = IRI,
										    text = TERM_BY_SBO_IRI[[IRI]])
								return(sboTypeLink)
							})

						wikipathwaysTypeLinks <- c()
						if (hasName(MARKER_MAPPINGS[[normalized]], 'wp')) {
							wikipathwaysType <- paste0('wikipathways:', MARKER_MAPPINGS[[normalized]][['wp']])
							wikipathwaysTypeLink <- makeHtmlLink(IRI = gsub(
											      "wikipathways:",
											      "http://vocabularies.wikipathways.org/wp#",
											      wikipathwaysType),
									    text = wikipathwaysType)
							wikipathwaysTypeLinks <- c(wikipathwaysTypeLink)
						}
						return(paste0(purrr::flatten(list(sboTypeLinks, wikipathwaysTypeLinks, biopaxTypes)), collapse = ', '))
					})) %>%
					select(sboType, type, SUID)

	##			## Maybe I need it's something about tidyr not using row names?
	##			## We could take a look at using something like this:
	##			## column_to_rownames(hgncified_df, var = "SUID")
	##
				# The following code does work, but couldn't it be simplified?
				edgeTable_df <- as.data.frame(edgeTable)
				row.names(edgeTable_df) <- edgeTable_df[["SUID"]]
				loadTableData(edgeTable_df, table.key.column = 'SUID', table = 'edge')
			}, warning = function(w) {
				write(paste("Warning mapping edge types in wikipathways2ndex.R:", w, sep = '\n'), stderr())
				NA
			}, error = function(err) {
				write(paste("Error mapping edge types in wikipathways2ndex.R:", err, sep = '\n'), stderr())
				NA
			}, finally = {
				# Do something
			})
		}

		# TODO: should we reference DataNodes of type Pathway with WithPathways IDs as NDEx subnetworks?

		metadata <- list(labels=c(wikipathwaysID))
		if ("pathwayOntologyTag" %in% networkTableColumnNames) {
			pathwayOntologyTag <- getTableColumns(
					table = 'network',
					columns = 'pathwayOntologyTag')[['pathwayOntologyTag']]
			pathwayOntologyTerms <- fromJSON(
				getTableColumns(
						table = 'network',
						columns = 'pathwayOntologyTag')[['pathwayOntologyTag']]
			) %>% as_tibble()

			pathwayOntologyTermsHTML <- pathwayOntologyTerms %>%
				pmap(function(id, name) {
					makeHtmlLink(IRI = gsub("PW:", "https://identifiers.org/pw/PW:", id), text = name)
				})
			metadata[["labels"]] <- paste(append(metadata[["labels"]], pathwayOntologyTermsHTML), collapse = ', ')

			deleteTableColumn('pathwayOntologyTag', table = 'network')
			metadata[["__wikipathways:pathwayOntologyTag"]] <- paste0(pathwayOntologyTerms$id, collapse = ', ')
			#updateNetworkTable(nameForNDEx, "__wikipathways:pathwayOntologyTag", pathwayOntologyTerms$id)
		}

		if ("celltypeOntologyTag" %in% networkTableColumnNames) {
			celltypeOntologyTerms <- fromJSON(
							getTableColumns(
								table = 'network',
								columns = 'celltypeOntologyTag')[['celltypeOntologyTag']]) %>%
				as_tibble()

			celltypeOntologyTermsHTML <- celltypeOntologyTerms %>%
				pmap(function(id, name) {
					makeHtmlLink(IRI = gsub("CL:", "https://identifiers.org/cl/CL:", id), text = name)
				})

			# cell type isn't exactly tissue
			metadata[["cell"]] <- paste(celltypeOntologyTermsHTML, collapse = ', ')

			deleteTableColumn('celltypeOntologyTag', table = 'network')
			metadata[["__wikipathways:celltypeOntologyTag"]] <- paste0(celltypeOntologyTerms$id, collapse = ', ')
			#updateNetworkTable(nameForNDEx, "__wikipathways:celltypeOntologyTag", celltypeOntologyTerms$id)
		}

		if ("diseaseOntologyTag" %in% networkTableColumnNames) {
			diseaseOntologyTerms <- fromJSON(
							getTableColumns(
								table = 'network',
								columns = 'diseaseOntologyTag')[['diseaseOntologyTag']]) %>%
				as_tibble()
			diseaseOntologyTermsHTML <- diseaseOntologyTerms %>%
				pmap(function(id, name) {
					makeHtmlLink(IRI = gsub("DOID:", "https://identifiers.org/doid/DOID:", id), text = name)
				})

			metadata[["disease"]] <- paste(diseaseOntologyTermsHTML, collapse = ', ')

			deleteTableColumn('diseaseOntologyTag', table = 'network')
			metadata[["__wikipathways:diseaseOntologyTag"]] <- paste0(diseaseOntologyTerms$id, collapse = ', ')
			#updateNetworkTable(nameForNDEx, "__wikipathways:diseaseOntologyTag", diseaseOntologyTerms$id)
		}

		result[["name"]] <- nameForNDEx

		if ("pmids" %in% networkTableColumnNames) {
			pmids <- fromJSON(
					getTableColumns(
						table = 'network',
						columns = 'pmids')[["pmids"]])
			pmidsHTML <- list(pmids) %>%
				pmap(function(pmid) {
					makeHtmlLink(IRI = gsub("pubmed:", "https://identifiers.org/pubmed:", pmid), text = pmid)
				})

			metadata[["citations"]] <- paste(pmidsHTML, collapse = ', ')
			#metadata[["citationsList"]] <- toJSON(pmids, auto_unbox = FALSE)

			deleteTableColumn('pmids', table = 'network')
			metadata[["__gpml:hasPublicationXref"]] <- paste0(pmids, collapse = ', ')
			#renameTableColumn('pmids', '__gpml:hasPublicationXref', table = 'network')
		}

		renameTableColumn('title', '__gpml:name', table = 'network')
		renameTableColumn('GraphID', '__gpml:GraphID', table = 'node')
		if ('GroupID' %in% nodeTableColumnNames) {
			renameTableColumn('GroupID', '__gpml:GroupID', table = 'node')
		}
		renameTableColumn('XrefDatasource', '__gpml:XrefDatasource', table = 'node')
		renameTableColumn('XrefId', '__gpml:XrefId', table = 'node')

#		# TODO: should we change these?
#		renameTableColumn('ConnectorType', '__gpml:connectorType', table = 'edge')
#		renameTableColumn('LineThickness', '__gpml:lineThickness', table = 'edge')
#		renameTableColumn('LineStyle', '__gpml:lineStyle', table = 'edge')
#		renameTableColumn('Color', '__gpml:color', table = 'edge')
#		renameTableColumn('Type', '__gpml:type', table = 'edge')

		deleteTableColumn('row.names', table = 'network')
		deleteTableColumn('row.names', table = 'node')
		deleteTableColumn('row.names', table = 'edge')

		suid <- getNetworkSuid(NULL, "http://localhost:1234/v1")

		matchingNetworkIds <- (networksInSet %>%
			filter(!is.na(wikipathwaysID) & wikipathwaysID == !!wikipathwaysID & !isDeleted))$externalId

		matchingNetworkCount <- length(matchingNetworkIds)
		if (matchingNetworkCount > 0 && !is.blank(matchingNetworkIds)) {
			print('Updating...')

			if (matchingNetworkCount > 1) {
				stop(paste0(
				    "Error: ",
				    matchingNetworkCount,
				    " matching networks when just 0 or 1 expected in wikipathways2ndex.R."
				    ))
			}

			networkId <- head(matchingNetworkIds, 1)
			
			print(paste0('Pathway ', wikipathwaysID, ' found in NDEx as network ', networkId, '. Updating...'))
			
			# make network editable
			ndex_network_set_systemProperties(ndexcon, networkId, readOnly=FALSE)
			
			print(paste0('Pathway ', wikipathwaysID, ' not found in NDEx. Posting as new network.'))
			
			# associate the pathway we downloaded from WikiPathways
			# with the UUID on NDEx
			res <- cyrestPUT(paste('networks', suid, 'NDEXUUID', sep = '/'),
        body = list(serverUrl=NDEX_SERVER_URL,
                    username=NDEX_USER,
                    password=NDEX_PWD,
                    uuid=networkId),
        base.url = "http://localhost:1234/cyndex2/v1")
			
			# TODO: add some error handling to catch the case where the previous
			# call fails. This could be due to being logged into the wrong NDEx
			# or not logged in at all in Cytoscape.
			
			# TODO: figure out how to programmatically log into the desired
			# NDEx profile in the NDEx app for Cytoscape.
	
			res <- cyrestPUT(paste('networks', suid, sep = '/'),
				      body = list(serverUrl=NDEX_SERVER_URL,
						  username=NDEX_USER,
						  password=NDEX_PWD,
						  metadata=metadata,
						  isPublic=TRUE),
					  base.url = "http://localhost:1234/cyndex2/v1")
			
			result[["output"]] <- res$data$uuid
			resErrors <- res$errors
			if (length(resErrors) > 0) {
				message <- paste(resErrors, sep = ' ')
				result[["error"]] <- message
				result[["success"]] <- FALSE
			} else {
				result[["error"]] <- NA
				result[["success"]] <- TRUE
			}
		} else {
			# NOTE: we need to use cyrestPOST in order to submit to the test/dev2 server.
			# exportNetworkToNDEx only submits to production server.
			print(paste0('Pathway ', wikipathwaysID, ' not found in NDEx. Posting as new network.'))
			res <- cyrestPOST(paste('networks', suid, sep = '/'),
				      body = list(serverUrl=NDEX_SERVER_URL,
						  username=NDEX_USER,
						  password=NDEX_PWD,
						  metadata=metadata,
						  isPublic=TRUE),
					  base.url = "http://localhost:1234/cyndex2/v1")
			result[["output"]] <- res$data$uuid
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

		networkId <- result[["output"]]

		r <- POST(
			  paste(NDEX_SERVER_URL, 'networkset', NETWORKSET_ID, 'members', sep = '/'),
			  body = list(networkId),
			  encode = "json",
			  authenticate(NDEX_USER, NDEX_PWD)
			  )
		stop_for_status(r)

		# if we get an error when trying to make readOnly, we ignore it and continue.
		tryCatch({
			# the ndexr package doesn't support index_level="ALL", so instead
		        # I need to use httr and work directly with the webservice
			r <- PUT(
				 paste(NDEX_SERVER_URL, 'network', networkId, 'systemproperty', sep = '/'),
				 # showcase=FALSE because the network _set_ is showcased,
				 # not each individual network
				 body = list(readOnly=TRUE, visibility="PUBLIC", showcase=FALSE, index_level="ALL"),
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
		# what if the session is already closed?
		closeSession(FALSE)
	})

	return(result)
}
