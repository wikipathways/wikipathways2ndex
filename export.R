#! /usr/bin/env nix-shell
#! nix-shell ./nix_shell_shebang_dependencies.nix -i Rscript

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

library(optparse)
library(here)
library(dplyr)
library(purrr)
library(readr)
library(tidyr)
library(RCy3)
source('./wikipathways2ndex.R')
source('./wikipathways2cx.R')
source('./get_pathways.R')

BATCH_SIZE = 10

get_value_by_key <- function(mylist, mykey) {
	return(unname(unlist(lapply(mylist, function(x) x[mykey]))))
}

exportersByName <- list("cx"=wikipathways2cx, "ndex"=wikipathways2ndex)

export_subset <- function(outdir_raw, pathway_ids_batch, exporterName) {
	outdir <- normalizePath(outdir_raw)
	exporter <- exportersByName[exporterName][[1]]
	if (!is.function(exporter)){
		print_help(parser)
		stop("valid exporter must be specified.n", call.=FALSE)
	}

	system(paste0("(cd ", here("rcy3_nix"), "; bash cytoscapestart.sh)"))
	deleteAllNetworks()
	results <- list()
	tryCatch({
		results <- tibble(pathway_id=pathway_ids_batch) %>%
			mutate(returned=map(pathway_id, function(pathway_id) {exporter(outdir, pathway_id)})) %>%
			mutate(name=map_chr(returned, "name")) %>%
			mutate(response=map_chr(returned, "response")) %>%
			mutate(success=map_lgl(returned, "success")) %>%
			mutate(error=map_chr(returned, "error")) %>%
			select(pathway_id, name, success, error, response)
	}, warning = function(w) {
		write(paste(paste0('Warning in exporter ', exporterName, ', called by export_subset in export.R:'), w, sep = '\n'), stderr())
	}, error = function(e) {
		# we only need to close it here, because it otherwise closes in wikipathways2ndex/wikipathways2cx/etc
		closeSession(FALSE)
		write(paste(paste0('Error in exporter ', exporterName, ', called by export_subset in export.R:'), e, sep = '\n'), stderr())
	}, interrupt = function(i) {
		closeSession(FALSE)
		write(paste(paste0('Interrupted exporter ', exporterName, ', called by export_subset in export.R:'), i, sep = '\n'), stderr())
	}, finally = {
		deleteAllNetworks()
		system(paste0("(cd ", here("rcy3_nix"), "; bash cytoscapestop.sh)"))
	})
	return(results)
}

canBeInteger <- function(x) {grepl('^\\d+$', x)}

option_list2 = list(
  make_option(c("--head"), type="numeric", default=Inf, 
              help="limit to first X inputs [default= %default]", metavar="integer"),
  make_option(c("--tail"), type="numeric", default=Inf, 
              help="limit to last Y inputs [default= %default]", metavar="integer")
); 
 
#parser <- OptionParser(usage = paste0("%prog [options] input=[filepath,AnalysisCollection] exporter=[", paste(names(exportersByName), collapse = ','), "]"), option_list=option_list2)
parser <- OptionParser(usage = paste0("%prog [options] input exporter outdir"),
		       description = paste0("input values: <a filepath>,<the string 'AnalysisCollection'> valid exporter values=<", paste(names(exportersByName), collapse = '>,<'), "> valid outdir values: <a filepath>"),
		       option_list=option_list2)
parsed <- parse_args(parser, positional_arguments = 3);

args <- parsed$args
options <- parsed$options

input <- args[1]
exporterName <- args[2]
outdir_raw <- args[3]
if (!dir.exists(outdir_raw)) {
	write(paste('Warning: Directory', outdir_raw, 'does not exist. Creating now.'), stderr())
	dir.create(outdir_raw)
#} else {
#	# TODO: can we set this up so this doesn't need to be empty?
#	# TODO: is there a better way to check for an empty directory?
#	# NOTE: length must be greater than 2, b/c the list always includes '.' and '..'
#	if(length(dir(outdir, all.files=TRUE)) > 2) {
#		stop(paste('Error in export.R: output dir', outdir, 'must be empty.'))
#	}
}

if (is.null(input)){
	print_help(parser)
	stop("input must be specified.n", call.=FALSE)
}
if (is.null(exporterName)){
	print_help(parser)
	stop("exporter must be specified.n", call.=FALSE)
}

tryCatch({
	pathway_ids <- list()
	if (grepl('\\.tsv$', input)) {
		pathway_ids <- read_lines(input)
	} else if (input == "AnalysisCollection") {
		pathway_ids <- get_value_by_key(getAnalysisCollection(), 'id')
	} else {
		stop("failed to read in input.n", call.=FALSE)
	}

	if (is.numeric(options$head) && !is.infinite(options$head)) {
		pathway_ids <- head(pathway_ids, options$head)
	}
	if (is.numeric(options$tail) && !is.infinite(options$tail)) {
		pathway_ids <- tail(pathway_ids, options$tail)
	}

	for (pathway_ids_batch in split(pathway_ids, ceiling(seq_along(pathway_ids)/BATCH_SIZE))) {
		print('pathway_ids_batch')
		print(pathway_ids_batch)
		results <- export_subset(outdir_raw, pathway_ids_batch, exporterName)
		print(as.data.frame(results))
	}
}, warning = function(w) {
	write(paste('Warning in export.R:', w, sep = '\n'), stderr())
}, error = function(e) {
	write(paste('Error in export.R:', e, sep = '\n'), stderr())
	system(paste0("(cd ", here("rcy3_nix"), "; bash cytoscapestop.sh)"))
}, interrupt = function(i) {
	write(paste('Interrupted export.R:', i, sep = '\n'), stderr())
	system(paste0("(cd ", here("rcy3_nix"), "; bash cytoscapestop.sh)"))
	#stop('Interrupted export.R')
}, finally = {
	# do something
})
