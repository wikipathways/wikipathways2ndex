library(dplyr)
library(purrr)
library(readr)
library(tidyr)
library(RCy3)
source('./wikipathways2cx.R')


get_file <- function(mylist) {
	myfile <- mylist[["file"]]
	passes <- grepl(paste0('name: ', appName, ', version: \\d\\.\\d(\\.\\d)+, status: Installed'), perl = TRUE, x)
	return(passes)
}

get_value_by_key <- function(mylist, mykey) {
	passes <- grepl(paste0('name: ', appName, ', version: \\d\\.\\d(\\.\\d)+, status: Installed'), perl = TRUE, x)
	return(passes)
}


tryCatch({
	pathway_ids <- read_lines('./pathway_ids.tsv')
	
#	for (pathway_id in pathway_ids) {
#		wikipathways2cx(pathway_id)
#	}

	results <- tibble(pathway_id=pathway_ids) %>%
		mutate(ndex_result=map(pathway_id, wikipathways2cx)) %>%
		mutate(file=map_chr(ndex_result, "file")) %>%
		mutate(success=map_lgl(ndex_result, "success")) %>%
		mutate(error=map_chr(ndex_result, "error")) %>%
		separate(file, into = c("path_plus_pathway_id", "pathway_name", "organism_plus_cx"), sep = "__", remove = FALSE) %>%
		separate(organism_plus_cx, into = c("organism", "extension"), sep = "\\.") %>%
		select(pathway_id, file, pathway_name, organism, success, error)

	#print(results)
	print(as.data.frame(results))
}, warning = function(w) {
	write('Warning for wikipathways2cx in bulk_to_cx.R:', stderr())
	warning(w)
	#write(paste0('Warning:', w), stderr())
}, error = function(e) {
	# we only need to close it here, because it otherwise closes in wikipathways2cx
	closeSession(FALSE)
	write('Error for wikipathways2cx in bulk_to_cx.R:', stderr())
	warning(e)
	#stop(e)
	#write(paste0('Error:', w), stderr())
}, finally = {
	commandQuit()
})
