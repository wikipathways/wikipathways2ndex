library(dplyr)
library(purrr)
library(readr)
library(tidyr)
library(RCy3)

tryCatch({
	source('./wikipathways2cx.R')
	pathway_ids <- read_lines('./pathway_ids.tsv')
	results <- tibble(pathway_id=pathway_ids) %>%
		mutate(cx=map(pathway_id, wikipathways2cx))
#		mutate(status=ndex_result[[1]][["status"]]) %>%
#		mutate(response=ndex_result[[1]][["response"]]) %>%
#		select(pathway_id, status, response)
	print(results)
}, warning = function(w) {
	write('Warning for wikipathways2cx in bulk_to_cx.R:', stderr())
	warning(w)
	#write(paste0('Warning:', w), stderr())
}, error = function(e) {
	closeSession(FALSE)
	write('Error for wikipathways2cx in bulk_to_cx.R:', stderr())
	warning(e)
	#stop(e)
	#write(paste0('Error:', w), stderr())
}, finally = {
	commandQuit()
})
