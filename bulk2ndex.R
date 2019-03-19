library(dplyr)
library(purrr)
library(readr)
library(tidyr)
library(RCy3)
source('./batch2ndex.R')
source('./get_pathways.R')

get_value_by_key <- function(mylist, mykey) {
	return(unname(unlist(lapply(mylist, function(x) x[mykey]))))
}


tryCatch({
	deleteAllNetworks()
	#pathway_ids <- read_lines('./pathway_ids.tsv')
	#pathway_ids <- get_value_by_key(getAnalysisCollection(), 'id')[20]
	#pathway_ids <- get_value_by_key(getAnalysisCollection(), 'id')
	#pathway_ids <- tail(get_value_by_key(getAnalysisCollection(), 'id'), -339)
	pathway_ids <- get_value_by_key(getAnalysisCollection(), 'id')
	batchSize = 20
	for (pathway_ids_batch in split(pathway_ids, ceiling(seq_along(pathway_ids)/batchSize))) {
		print('pathway_ids_batch')
		print(pathway_ids_batch)
		results <- batch2ndex(pathway_ids_batch)
		print(as.data.frame(results))
	}
#	results <- tibble(pathway_id=pathway_ids) %>%
#		mutate(ndex_result=map(pathway_id, wikipathways2ndex)) %>%
#		mutate(name=map_chr(ndex_result, "name")) %>%
#		mutate(response=map_chr(ndex_result, "response")) %>%
#		mutate(success=map_lgl(ndex_result, "success")) %>%
#		mutate(error=map_chr(ndex_result, "error")) %>%
#		select(pathway_id, name, success, error, response)
#
#	print(as.data.frame(results))
}, warning = function(w) {
	write(paste('Warning in bulk2ndex.R:', w, sep = '\n'), stderr())
}, error = function(e) {
	# we don't need closeSession(FALSE) during normal operation, because
	# wikipathways2ndex is supposed to close it
	closeSession(FALSE)
	write(paste('Error in bulk2ndex.R:', e, sep = '\n'), stderr())
}, interrupt = function(i) {
	# we don't need closeSession(FALSE) during normal operation, because
	# wikipathways2ndex is supposed to close it
	closeSession(FALSE)
	write(paste('Interrupted bulk2ndex.R:', i, sep = '\n'), stderr())
}, finally = {
	# need to do this in case the user set the --reuse flag
	system("bash ./cytoscapestart.sh")
})
