library(dplyr)
library(tidyr)
library(RCy3)

#############################################################
# NOTE: this is currently only set up to handle mapping to
# HGNC and comparing against this code:
#   mapTableColumn('Ensembl', organism, 'Ensembl', 'HGNC')
#   renameTableColumn('HGNC', 'FromEnsembl')
# But it could be modified to allow for mapping to
# other data sources, even metabolite data sources.
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

unify <- function(organism) {
	if (organism == 'Homo sapiens') {
		datasources <- unique(getTableColumns()[['XrefDatasource']])
		datasourcesInNetworkConvertibleToHGNC <- intersect(datasources, ALL_DATASOURCES_CONVERTIBLE_TO_HGNC)
		for (datasource in datasourcesInNetworkConvertibleToHGNC) {
			mapTableColumn('XrefId', organism, datasource, 'HGNC')
		}

		tableColumns <- as_tibble(getTableColumns())
		hgncCoalesced <- coalesce(!!!select(tableColumns, starts_with('HGNC')))

		hgncified_o <- bind_cols(tableColumns, hgncCoalesced=hgncCoalesced) %>%
			mutate(name=ifelse(is.na(hgncCoalesced) | !(XrefDatasource %in% ALL_DATASOURCES_CONVERTIBLE_TO_HGNC), name, hgncCoalesced))

		hgncified_t <- select(hgncified_o, 'shared name', 'name', 'FromEnsembl', 'hgncCoalesced', 'Ensembl', 'XrefId', 'XrefDatasource', 'Type') %>%
			filter(name != FromEnsembl & XrefDatasource %in% datasourcesInNetworkConvertibleToHGNC)
			#filter((name != FromEnsembl | name != `shared name`) & (XrefDatasource %in% datasourcesInNetworkConvertibleToHGNC))
		if (length(hgncified_t[['name']] > 0)) {
			print('hgncified_t')
			print(as.data.frame(hgncified_t))
		}

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
}
