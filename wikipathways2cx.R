library(dplyr)
library(tidyr)
library(RCy3)

# TODO: where should we output these files? We should allow for specifying the output location.
CX_OUTPUT_DIR = file.path(Sys.getenv('HOME'), 'wikipathways2ndex', 'cx')
if (!dir.exists(CX_OUTPUT_DIR)) {
	write(paste0('Warning: Directory', CX_OUTPUT_DIR, 'does not exist. Creating now.'), stderr())
	dir.create(CX_OUTPUT_DIR)
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

wikipathways2cx <- function(wikipathwaysId) {
	print('wikipathwaysId')
	print(wikipathwaysId)

	net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysId, '"'))
	#print('getTableColumns()')
	#print(getTableColumns())
	mapped.cols <- mapTableColumn('XrefId', 'Human', 'Entrez Gene', 'HGNC')
	only.mapped.cols <- mapped.cols[complete.cases(mapped.cols), 'HGNC', drop=FALSE]
	colnames(only.mapped.cols) <- 'XrefId'
	loadTableData(only.mapped.cols, table.key.column = 'SUID')
	initialData <- getTableColumns()
	hgncified <- as_tibble(initialData) %>%
		mutate(oldname=name) %>%
		mutate(newname=ifelse(is.na(HGNC), name, HGNC)) %>%
		mutate_at(.vars = vars(name), .funs = funs(ifelse(is.na(HGNC), name, HGNC)))

	hgncified_df <- as.data.frame(hgncified)
	row.names(hgncified_df) <- hgncified_df[["SUID"]]

	#loadTableData(as.data.frame(hgncified), table.key.column = 'SUID')
	#loadTableData(as.data.frame(hgncified))
	## TODO: why does this work but the two above do not update the name for GALNT13?
	loadTableData(hgncified_df, table.key.column = 'SUID')

	networkName <- getNetworkName()
	filename <- paste0(wikipathwaysId, '__', gsub("_-_", "__", gsub(" ", "_", networkName)))
	exportResponse <- exportNetwork(filename=file.path(CX_OUTPUT_DIR, filename), type='CX')
	closeSession(FALSE)
	return(exportResponse)
}
