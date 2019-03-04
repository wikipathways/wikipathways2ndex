library(dplyr)
library(tidyr)
library(RCy3)

# TODO: where should we output these files? We should allow for specifying the output location.
CX_OUTPUT_DIR = file.path(Sys.getenv('HOME'), 'wikipathways2ndex', 'cx')
if (!dir.exists(CX_OUTPUT_DIR)) {
	write(paste('Warning: Directory', CX_OUTPUT_DIR, 'does not exist. Creating now.'), stderr())
	dir.create(CX_OUTPUT_DIR)
} else {
	# TODO: is there a better way to check for an empty directory?
	# We need length greater than 2, b/c the list includes '.' and '..'
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

# Get all data sources from here:
# http://webservice.bridgedb.org/Human/sourceDataSources
# Then choose the ones that can be converted to HGNC, which can be determined
# by checking that the following URL responds with 'true':
# http://webservice.bridgedb.org/Human/isMappingSupported/WikiGenes/HGNC

HGNCIBLE <- c(
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
	net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysId, '"'))
	tableColumns <- getTableColumns()
	datasources <- unique(tableColumns[['XrefDatasource']])
	hgncibleDatasources <- intersect(datasources, HGNCIBLE)
	for (datasource in hgncibleDatasources) {
		mapped.cols <- mapTableColumn('XrefId', 'Human', datasource, 'HGNC')
		only.mapped.cols <- mapped.cols[complete.cases(mapped.cols), 'HGNC', drop=FALSE]
	}

	tableColumns <- as_tibble(getTableColumns())
	hgncs <- coalesce(!!!select(tableColumns, starts_with('HGNC')))
	hgncified <- bind_cols(tableColumns, hgncCoalesced=hgncs) %>%
		mutate(name=ifelse(is.na(hgncCoalesced), name, hgncCoalesced)) %>%
		select('SUID', 'name')

	hgncified_df <- as.data.frame(hgncified)
	row.names(hgncified_df) <- hgncified_df[["SUID"]]

	#loadTableData(as.data.frame(hgncified), table.key.column = 'SUID')
	#loadTableData(as.data.frame(hgncified))
	## TODO: why does this work but the two above do not update the name for GALNT13?
	loadTableData(hgncified_df, table.key.column = 'SUID')

	deleteTableColumn('HGNC')
	i <- 0
	for (datasource in hgncibleDatasources) {
		deleteTableColumn(paste0('HGNC (', i, ')'))
		i <- i + 1
	}

	print('getTableColumns()')
	print(getTableColumns())

	networkName <- getNetworkName()
	filename <- paste0(wikipathwaysId, '__', gsub("_-_", "__", gsub(" ", "_", networkName)))
	exportResponse <- exportNetwork(filename=file.path(CX_OUTPUT_DIR, filename), type='CX')
	closeSession(FALSE)
	return(exportResponse)
}
