library(dplyr)
library(purrr)
library(here)

library(RCy3)
library(jsonlite)
library(rWikiPathways)
library(tidyr)
library(XML)
library(utf8)

source('./extra.R')
#source('./get_citation.R')

# TODO: should we set the following?
#options(encoding = "UTF-8")

# Using dev version of WikiPathways app right now, so commenting this line out:
#installApp('WikiPathways')
#system("bash ./install_dev_wikipathways_app.sh")

contextFile <- here("./context.json")
CONTEXT <- readChar(contextFile, file.info(contextFile)$size)

load_wikipathways_pathway <- function(wikipathwaysID) {
	tmp_dir = tempdir()
	result <- list()
	tryCatch({
		# TODO: why does net.suid != suid, as gotten later on?
		net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysID, '"'))

		# FROM WIKIPATHWAYS APP
		networkTableColumns <- getTableColumns(table = 'network', columns = 'name,title,organism,description,pmids')

		name <- networkTableColumns[["name"]]
		title <- networkTableColumns[["title"]]
		organism <- networkTableColumns[["organism"]]
		description <- networkTableColumns[["description"]]
		raw_pmids <- networkTableColumns[["pmids"]]
		if (!is.blank(raw_pmids)) {
			pathway_raw_pmids = paste(wikipathwaysID, raw_pmids, sep = ': ')
			cat(pathway_raw_pmids, file=here("raw_pmids.txt"), append=TRUE, sep = "\n")
			pmids <- as.integer(Filter(canBeInteger, unlist(strsplit(raw_pmids, "\\s*,\\s*"))))
			if (!is.blank(pmids)) {
				pmIRIs <- map(pmids, function(pmid) {
					return(paste0('pubmed:', pmid))
				})

				updateNetworkTable(name, "pmids", pmIRIs)
				# TODO: look at the pmids code in wikipathways2ndex.
				# Should some of it be moved here?

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


		# FROM WikiPathways WEBSERVICE
		pathwayInfo <- getPathwayInfo(wikipathwaysID)
		#wikipathwaysID <- pathwayInfo[1]
		#url <- pathwayInfo[2]

		if (is.blank(title)) {
			title <- pathwayInfo[3]
			#write(paste("Warning: title not found by cytoscape app but was by getPathwayInfo in wikipathways_extra.R:", title), stderr())
			updateNetworkTable(name, "title", title)
		}

		if (is.blank(organism)) {
			organism <- pathwayInfo[4]
			#write(paste("Warning: organism not found by cytoscape app but was by getPathwayInfo in wikipathways_extra.R:", organism), stderr())
			updateNetworkTable(name, "organism", organism)
		}

		wikipathwaysVersion <- pathwayInfo[5]

		if (is.blank(description)) {
			#write("Warning: description not found by cytoscape app in wikipathways_extra.R", stderr())
			pathway_latin1 <- getPathway(wikipathwaysID)
			Encoding(pathway_latin1) <- "latin1"
			pathway <- as_utf8(pathway_latin1)

			# if we get an error when trying to get description, we skip it and continue.
			description <- tryCatch({
				#write("Trying to get description by getPathway in wikipathways_extra.R", stderr())
				# TODO: can't parse GPML for WP23. Complains about encoding.
				pathwayParsed <- xmlTreeParse(pathway, asText = TRUE, useInternalNodes = TRUE, getDTD=FALSE)
				# TODO: look into formatting description as HTML. Is the string wikitext?
				# For example, '\n' could be '<br>'
				descriptionCandidate <- xmlSerializeHook(getNodeSet(pathwayParsed,
							 "/gpml:Pathway/gpml:Comment[@Source='WikiPathways-description']/text()",
							 c(gpml = "http://pathvisio.org/GPML/2013a")))[[1]]
				descriptionCandidate
			}, warning = function(w) {
				write(paste("Warning getting description in wikipathways_extra.R:", w, sep = '\n'), stderr())
				return('')
			}, error = function(err) {
				write(paste("Error getting description in wikipathways_extra.R:", err, sep = '\n'), stderr())
				return('')
			}, finally = {
				# Do something
			})
			#write(paste("Warning: description not found by cytoscape app but was by getPathway in wikipathways_extra.R:", description, sep = '\n'), stderr())

			updateNetworkTable(name, "description", description)
		}

		# replace any non-alphanumeric characters with underscore.
		# TODO: what about dashes? BTW, the following doesn't work:
		filename <- paste0(gsub("[^[:alnum:]]", "_", name))
		filepath_san_ext <- file.path(tmp_dir, filename)

		updateNetworkTable(name, "@context", CONTEXT)

		wikipathwaysIRI = paste0('http://identifiers.org/wikipathways/', wikipathwaysID, '_r', wikipathwaysVersion)
		updateNetworkTable(name, "wikipathwaysIRI", wikipathwaysIRI)

		updateNetworkTable(name, "wikipathwaysID", wikipathwaysID)
		updateNetworkTable(name, "wikipathwaysVersion", wikipathwaysVersion)
		updateNetworkTable(name, "license", 'Waiver-No Rights Reserved (CC0)')
		# Our license language is here:
		# https://www.wikipathways.org/index.php/WikiPathways:License_Terms#The_License.2FWaiver

		# We could alternatively provided HTML, e.g.:
		#rights = '<p xmlns:dct="http://purl.org/dc/terms/"> <a rel="license" href="http://creativecommons.org/publicdomain/zero/1.0/"> <img src="http://i.creativecommons.org/p/zero/1.0/88x31.png" style="border-style: none;" alt="CC0" /> </a> <br /> To the extent possible under law, <a rel="dct:publisher" href="https://www.wikipathways.org">https://www.wikipathways.org</a> has waived all copyright and related or neighboring rights to this work. </p>',

		ontologyTerms <- getOntologyTerms(wikipathwaysID) %>%
			# converting from
			# list of Named chr
			# to
			# list of named lists
			map(function(x) {list("id"=x[["id"]], "name"=x[["name"]], "ontology"=x[["ontology"]])})

		pathwayOntologyTerms <- keep(ontologyTerms, function(x) {x["ontology"] == 'Pathway Ontology'}) %>%
			map(`[`, c("id", "name"))
		if (length(pathwayOntologyTerms) > 0) {
			updateNetworkTable(name, "pathwayOntologyTag", pathwayOntologyTerms)
		}

		celltypeOntologyTerms <- keep(ontologyTerms, function(x) {x["ontology"] == 'Cell Type'}) %>%
			map(`[`, c("id", "name"))
		if (length(celltypeOntologyTerms) > 0) {
			updateNetworkTable(name, "celltypeOntologyTag", celltypeOntologyTerms)
		}

		diseaseOntologyTerms <- keep(ontologyTerms, function(x) {x["ontology"] == 'Disease'}) %>%
			map(`[`, c("id", "name"))
		if (length(diseaseOntologyTerms) > 0) {
			updateNetworkTable(name, "diseaseOntologyTag", diseaseOntologyTerms)
		}

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

		unlink(tmp_dir)
	}, warning = function(w) {
		write(paste("Warning somewhere in wikipathways_extra.R:", w, sep = '\n'), stderr())
		NA
	}, error = function(err) {
		closeSession(FALSE)
		write(paste("Error somewhere in wikipathways_extra.R:", err, sep = '\n'), stderr())
		message <- paste(result[["error"]], err, sep = ' ')
		result[["error"]] <- message
		result[["success"]] <- FALSE
	}, interrupt = function(i) {
		closeSession(FALSE)
		stop('Interrupted wikipathways_extra.R')
	}, finally = {
		# do something
	})

	return(result)
}
