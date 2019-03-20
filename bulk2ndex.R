#! /usr/bin/env nix-shell
#! nix-shell ./nix_shell_shebang_dependencies.nix -i Rscript

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

library(dplyr)
library(purrr)
library(readr)
library(tidyr)
source('./batch2ndex.R')
source('./get_pathways.R')

get_value_by_key <- function(mylist, mykey) {
	return(unname(unlist(lapply(mylist, function(x) x[mykey]))))
}

BATCH_SIZE = 20

tryCatch({
	#pathway_ids <- head(get_value_by_key(getAnalysisCollection(), 'id'), 22)
	#pathway_ids <- get_value_by_key(getAnalysisCollection(), 'id')[20]
	#pathway_ids <- get_value_by_key(getAnalysisCollection(), 'id')
	#pathway_ids <- tail(get_value_by_key(getAnalysisCollection(), 'id'), -339)
	#pathway_ids <- get_value_by_key(getAnalysisCollection(), 'id')
	#pathway_ids <- c("WP26")

	pathway_ids <- c("WP3929")
	#pathway_ids <- c("WP3678")
	for (pathway_ids_batch in split(pathway_ids, ceiling(seq_along(pathway_ids)/BATCH_SIZE))) {
		print('pathway_ids_batch')
		print(pathway_ids_batch)
		results <- batch2ndex(pathway_ids_batch)
		print(as.data.frame(results))
	}
}, warning = function(w) {
	write(paste('Warning in bulk2ndex.R:', w, sep = '\n'), stderr())
}, error = function(e) {
	write(paste('Error in bulk2ndex.R:', e, sep = '\n'), stderr())
	system("bash ./cytoscapestop.sh")
}, interrupt = function(i) {
	write(paste('Interrupted bulk2ndex.R:', i, sep = '\n'), stderr())
	system("bash ./cytoscapestop.sh")
	#stop('Interrupted bulk2ndex.R')
}, finally = {
	# do something
})
