library(dplyr)
library(here)
library(RCy3)
library(rjson)
library(tidyr)

source('./connect.R')
connect()
source('./unify.R')

installApp('WikiPathways')

wikipathways2ndex <- function(wikipathwaysId) {
	net.suid <- commandsGET(paste0('wikipathways import-as-pathway id="', wikipathwaysId, '"'))

	networkName <- getNetworkName()
	organism <- gsub(".*\\s\\-\\s", "", networkName)

	unify(organism)

	NDEX_USER <- Sys.getenv("NDEX_USER")
	NDEX_PWD <- Sys.getenv("NDEX_PWD")
	result <- list(name=networkName)
	if (NDEX_USER == '' || NDEX_PWD == '') {
		message <- 'Error: environment variables NDEX_USER and/or NDEX_PWD not set.'
		write(message, stderr())
		write('In your terminal, run:', stderr())
		write('export NDEX_USER=\'your-ndex-username\'', stderr())
		write('export NDEX_PWD=\'your-ndex-password\'', stderr())
		result[["success"]] <- FALSE
		result[["error"]] <- message
		result[["response"]] <- NA
	} else {
		exportResponse <- exportNetworkToNDEx(NDEX_USER, NDEX_PWD, isPublic=TRUE)
		# See https://github.com/wikipathways/wikipathways2ndex/issues/1
		#exportResponse <- exportNetworkToNDEx(NDEX_USER, NDEX_PWD, isPublic=TRUE, base.url='http://dev2.ndexbio.org/v2')
		#exportResponse <- exportNetworkToNDEx(NDEX_USER, NDEX_PWD, isPublic=TRUE, base.url='http://test.ndexbio.org/v2')
		result[["success"]] <- TRUE
		result[["error"]] <- NA
		result[["response"]] <- exportResponse
	}

	closeSession(FALSE)
	return(result)
}
