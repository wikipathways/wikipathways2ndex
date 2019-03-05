library(dplyr)
library(tidyr)
library(RCy3)
library(rjson)

source('./connect.R')
connect()

# TODO: where should we output these files? We should allow for specifying the output location.
CX_OUTPUT_DIR = file.path(Sys.getenv('HOME'), 'wikipathways2ndex', 'cx')
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

appInStringAndInstalled <- function(appName, x) {
	# version is not strictly semver. It can have a format like this: 1.1.0.2
	passes <- grepl(paste0('name: ', appName, ', version: \\d\\.\\d(\\.\\d)+, status: Installed'), perl = TRUE, x)
	return(passes)
}

installedApps <- getInstalledApps()
wikipathwaysInstalled <- length(installedApps[appInStringAndInstalled('WikiPathways', installedApps)]) == 1
bridgedbInstalled <- length(installedApps[appInStringAndInstalled('BridgeDb', installedApps)]) == 1

if (!wikipathwaysInstalled) {
	write('Warning: WikiPathways not installed. Installing now...', stderr())
	installApp('WikiPathways')
	write('WikiPathways now installed.', stderr())
}

if (!bridgedbInstalled) {
	write('Warning: BridgeDb not installed. Installing now...', stderr())
	installApp('BridgeDb')
	write('BridgeDb now installed.', stderr())
}

#updateApp('WikiPathways')
#updateApp('BridgeDb')

# To get the data sources that can be converted to HGNC,
# we first get all data sources from here:
# http://webservice.bridgedb.org/Human/sourceDataSources
#
# Then we filter to only include the ones that can be converted to HGNC.
# We do this by checking that the following URL responds with 'true',
# replacing WikiGenes with each different data source:
# http://webservice.bridgedb.org/Human/isMappingSupported/WikiGenes/HGNC
#
# This process yields the following data sources as of 2019-03-04:
ALL_DATASOURCES_CONVERTIBLE_TO_HGNC <- c(
	      'WikiGenes',
	      'RefSeq',
	      'OMIM',
	      'Illumina',
	      'Rfam',
	      'miRBase Sequence',
	      'PDB',
	      'Ensembl',
	      'Affy',
	      'Uniprot-TrEMBL',
	      'Entrez Gene',
	      'UCSC Genome Browser',
	      # should we run mapTableColumn(..., ..., HGNC, HGNC)?
	      'HGNC',
	      'GeneOntology',
	      'UniGene',
	      'Agilent')

wikipathways2cx <- function(wikipathwaysId) {
	print(wikipathwaysId)
	net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysId, '"'))

	networkName <- getNetworkName()
	print(networkName)
	organism <- gsub(".*\\s\\-\\s", "", networkName)
	print(organism)
	filename <- paste0(wikipathwaysId, '__', gsub("_-_", "__", gsub(" ", "_", networkName)))
	filepath_san_ext <- file.path(CX_OUTPUT_DIR, filename)

	# save as png
	# TODO:: why does only the last of the following work?
	# It appears the file must be in the cwd.
	#exportImage(filepath_san_ext, 'PNG', zoom=200)
	#exportImage(file.path(CX_OUTPUT_DIR, wikipathwaysId), 'PNG', zoom=200)
	#exportImage(paste(CX_OUTPUT_DIR, wikipathwaysId, sep = '/'), 'PNG', zoom=200)
	exportImage(paste('/home/ariutta/wikipathways2ndex', filename, sep = '/'), 'PNG', zoom=200)

	if (organism == 'Homo sapiens') {
		# TODO: why does this work for WP3980 but throws an error for WP554?
		mapTableColumn('Ensembl', organism, 'Ensembl', 'HGNC')
		renameTableColumn('HGNC', 'FromEnsembl')
		print('mapTableColumn done')

		datasources <- unique(getTableColumns()[['XrefDatasource']])
		datasourcesInNetworkConvertibleToHGNC <- intersect(datasources, ALL_DATASOURCES_CONVERTIBLE_TO_HGNC)
		for (datasource in datasourcesInNetworkConvertibleToHGNC) {
			mapTableColumn('XrefId', organism, datasource, 'HGNC')
		}

		tableColumns <- as_tibble(getTableColumns())
		hgncCoalesced <- coalesce(!!!select(tableColumns, starts_with('HGNC')))

		hgncified_o <- bind_cols(tableColumns, hgncCoalesced=hgncCoalesced) %>%
			mutate(name=ifelse(is.na(hgncCoalesced) | !(XrefDatasource %in% ALL_DATASOURCES_CONVERTIBLE_TO_HGNC), name, hgncCoalesced))

		#hgncified_t <- select(hgncified_o, 'shared name', 'name', 'XrefId', 'XrefDatasource', 'Type')
		#hgncified_t <- select(hgncified_o, 'shared name', 'FromEnsembl', 'name', 'hgncCoalesced', 'Ensembl', 'XrefId', 'XrefDatasource', 'Type')
		#hgncified_t <- select(hgncified_o, 'shared name', 'name', 'hgncCoalesced', 'Ensembl', 'XrefId', 'XrefDatasource', 'Type')
		hgncified_t <- select(hgncified_o, 'shared name', 'name', 'FromEnsembl', 'hgncCoalesced', 'Ensembl', 'XrefId', 'XrefDatasource', 'Type') %>%
			filter(name != FromEnsembl & XrefDatasource %in% datasourcesInNetworkConvertibleToHGNC)
			#filter((name != FromEnsembl | name != `shared name`) & (XrefDatasource %in% datasourcesInNetworkConvertibleToHGNC))

		print('hgncified_t')
		print(as.data.frame(hgncified_t))

		hgncified <- select(hgncified_o, 'SUID', 'name')

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

		# When available, HGNCs are going into the name column, so we can get rid of
		# the HGNC, HGNC (1), ... columns
		deleteTableColumn('HGNC')
		i <- 1
		for (datasource in datasourcesInNetworkConvertibleToHGNC) {
			deleteTableColumn(paste0('HGNC (', i, ')'))
			i <- i + 1
		}
	}

	# save as cx
	exportResponse <- exportNetwork(filename=filepath_san_ext, type='CX')
	# TODO: right now, exportResponse only has one named item: 'file'.
	# But it should include status info too. Then we could possibly just
	# use exportResponse instead of making the 'response' list further below.

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
