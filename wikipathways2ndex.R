library(dplyr)
library(tidyr)
library(RCy3)

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

wikipathways2ndex <- function(wikipathwaysId) {
	net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysId, '"'))
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

#	data <- getTableColumns()
#	print('data')
#	print(data[15:25, c("SUID", "name", "HGNC")])
#
#	GALTN13_data <- as_tibble(data) %>%
#		filter(HGNC == 'GALNT13') %>%
#		select(SUID, name, HGNC)
#	print('GALTN13_data')
#	print(GALTN13_data)

	NDEX_USER <- Sys.getenv("NDEX_USER")
	NDEX_PWD <- Sys.getenv("NDEX_PWD")
	result <- list()
	if (NDEX_USER == '' || NDEX_PWD == '') {
		write('Error: environment variables NDEX_USER and/or NDEX_PWD not set.', stderr())
		write('In your terminal, run:', stderr())
		write('export NDEX_USER=\'your-ndex-username\'', stderr())
		write('export NDEX_PWD=\'your-ndex-password\'', stderr())
		result <- list(status='FAIL', response=NA)
	} else {
		exportResponse <- exportNetworkToNDEx(NDEX_USER, NDEX_PWD, isPublic=TRUE)
		#exportResponse <- exportNetworkToNDEx(NDEX_USER, NDEX_PWD, isPublic=TRUE, base.url='http://dev2.ndexbio.org/v2')
		#exportResponse <- exportNetworkToNDEx(NDEX_USER, NDEX_PWD, isPublic=TRUE, base.url='http://test.ndexbio.org/v2')
		result <- list(status='SUCCESS', response=exportResponse)
	}
	closeSession(FALSE)
	return(result)
}
