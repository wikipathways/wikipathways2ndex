library(dplyr)
library(tidyr)
library(RCy3)

#############################################################
# NOTE: this just does Ensembl -> HGNC:
#   mapTableColumn('Ensembl', organism, 'Ensembl', 'HGNC')
# unify2hgnc_from_xrefid.R could be the basis for creating
# code for unification for other sources and targets.
#############################################################

appInStringAndInstalled <- function(appName, x) {
	# version is not strictly semver. It can have a format like this: 1.1.0.2
	passes <- grepl(paste0('name: ', appName, ', version: \\d\\.\\d(\\.\\d)+, status: Installed'), perl = TRUE, x)
	return(passes)
}

installedApps <- getInstalledApps()
bridgedbInstalled <- length(installedApps[appInStringAndInstalled('BridgeDb', installedApps)]) == 1

if (!bridgedbInstalled) {
	write('Warning: BridgeDb not installed. Installing now...', stderr())
	installApp('BridgeDb')
	write('BridgeDb now installed.', stderr())
}

#updateApp('BridgeDb')

unify <- function(organism) {
	# TODO: it appears I can't run mapTableColumn for mouse and human pathways in
	# the same batch. Any of these combos work:
	# * just WP1 (mouse)
	# * just WP241 (human)
	# * WP241, WP550, WP554 (human)
	# but this fails:
	# * WP1 (mouse) and WP241 (human)
	if (organism == 'Homo sapiens') {
		mapTableColumn('Ensembl', organism, 'Ensembl', 'HGNC')

		hgncified <- mutate(as_tibble(getTableColumns()), name=ifelse(is.na(HGNC), name, HGNC)) %>%
			select('SUID', 'name')

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

		deleteTableColumn('HGNC')
	}
}
