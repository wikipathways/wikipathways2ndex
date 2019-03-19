library(dplyr)
library(purrr)
library(readr)
library(tidyr)
library(RCy3)
source('./wikipathways2ndex.R')


batch2ndex <- function(pathway_ids_batch) {
	system("bash ./cytoscapestart.sh")
	deleteAllNetworks()
	results <- list()
	tryCatch({
		#results <- tibble(x = 1:3, y = c("a", "b", "c"))
		results <- tibble(pathway_id=pathway_ids_batch) %>%
			mutate(ndex_result=map(pathway_id, wikipathways2ndex)) %>%
			mutate(name=map_chr(ndex_result, "name")) %>%
			mutate(response=map_chr(ndex_result, "response")) %>%
			mutate(success=map_lgl(ndex_result, "success")) %>%
			mutate(error=map_chr(ndex_result, "error")) %>%
			select(pathway_id, name, success, error, response)
	}, warning = function(w) {
		write(paste('Warning for wikipathways2ndex in batch2ndex.R:', w, sep = '\n'), stderr())
	}, error = function(e) {
		# we only need to close it here, because it otherwise closes in wikipathways2ndex
		closeSession(FALSE)
		write(paste('Error for wikipathways2ndex in batch2ndex.R:', e, sep = '\n'), stderr())
	}, interrupt = function(i) {
		closeSession(FALSE)
		write(paste('Interrupted batch2ndex.R:', i, sep = '\n'), stderr())
	}, finally = {
		deleteAllNetworks()
		system("bash ./cytoscapestop.sh")
	})
	return(results)
}
