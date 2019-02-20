library(RCy3)
wikipathwaysInString <- function(x) {
	passes <- grepl('name: WikiPathways, version: \\d\\.\\d\\.\\d, status: Installed', perl = TRUE, x)
	return(passes)
}
installedApps <- getInstalledApps()
wikipathwaysInstalled <- length(installedApps[wikipathwaysInString(installedApps)]) == 1
if (!wikipathwaysInstalled) {
	write('Warning: WikiPathways not installed. Installing now...', stderr())
	installApp('WikiPathways')
	write('WikiPathways now installed.', stderr())
}

bridgedbInString <- function(x) {
	passes <- grepl('name: BridgeDb, version: \\d\\.\\d\\.\\d, status: Installed', perl = TRUE, x)
	return(passes)
}
installedApps <- getInstalledApps()
bridgedbInstalled <- length(installedApps[bridgedbInString(installedApps)]) == 1
if (!bridgedbInstalled) {
	write('Warning: BridgeDb not installed. Installing now...', stderr())
	installApp('BridgeDb')
	write('BridgeDb now installed.', stderr())
}

#updateApp('WikiPathways')
#updateApp('BridgeDb')

wikipathways2ndex <- function(wikipathwaysId) {
	net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysId, '"'))
	mapped.cols <- mapTableColumn('XrefId','Human','Entrez Gene','Ensembl')
	only.mapped.cols <- mapped.cols[complete.cases(mapped.cols), 'Ensembl', drop=FALSE]
	colnames(only.mapped.cols) <- 'XrefId'
	loadTableData(only.mapped.cols,table.key.column = 'SUID')
	NDEX_USER <- Sys.getenv("NDEX_USER")
	NDEX_PWD <- Sys.getenv("NDEX_PWD")
	succeeded <- FALSE
	if (NDEX_USER == '' || NDEX_PWD == '') {
		write('Error: environment variables NDEX_USER and/or NDEX_PWD not set.', stderr())
		write('In your terminal, run:', stderr())
		write('export NDEX_USER=\'your-ndex-username\'', stderr())
		write('export NDEX_PWD=\'your-ndex-password\'', stderr())
		succeeded <- FALSE
	} else {
		#exportNetworkToNDEx(NDEX_USER, NDEX_PWD, isPublic=TRUE)
		exportNetworkToNDEx(NDEX_USER, NDEX_PWD, isPublic=TRUE, base.url='http://test.ndexbio.org/v2')
		succeeded <- TRUE
	}
	return(succeeded)
}

wikipathways2ndex('WP12')
