library(dplyr)
library(purrr)
library(readr)
library(tidyr)
library(RCy3)
source('./wikipathways2ndex.R')
source('./get_pathways.R')


get_file <- function(mylist) {
	myfile <- mylist[["file"]]
	passes <- grepl(paste0('name: ', appName, ', version: \\d\\.\\d(\\.\\d)+, status: Installed'), perl = TRUE, x)
	return(passes)
}

get_value_by_key <- function(mylist, mykey) {
	return(unname(unlist(lapply(mylist, function(x) x[mykey]))))
}


tryCatch({
	deleteAllNetworks()
	#pathway_ids <- read_lines('./pathway_ids.tsv')
	#pathway_ids <- get_value_by_key(getAnalysisCollection(), 'id')[8]
	#pathway_ids <- get_value_by_key(getAnalysisCollection(), 'id')
	pathway_ids <- tail(get_value_by_key(getAnalysisCollection(), 'id'), -20)
	results <- tibble(pathway_id=pathway_ids) %>%
		mutate(ndex_result=map(pathway_id, wikipathways2ndex)) %>%
		mutate(name=map_chr(ndex_result, "name")) %>%
		mutate(response=map_chr(ndex_result, "response")) %>%
		mutate(success=map_lgl(ndex_result, "success")) %>%
		mutate(error=map_chr(ndex_result, "error")) %>%
		select(pathway_id, name, success, error, response)

	print(as.data.frame(results))
}, warning = function(w) {
	write('Warning for wikipathways2ndex in bulk_to_ndex.R:', stderr())
	warning(w)
	#write(paste0('Warning:', w), stderr())
}, error = function(e) {
	# we only need to close it here, because it otherwise closes in wikipathways2ndex
	closeSession(FALSE)
	write(paste('Error for wikipathways2ndex in bulk_to_ndex.R:', e, sep = '\n'), stderr())
	#stop(e)
	#write(paste0('Error:', w), stderr())
}, finally = {
	deleteAllNetworks()
	# letting this be handled in the bash script instead
	#commandQuit()
})
