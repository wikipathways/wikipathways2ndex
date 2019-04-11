#! /usr/bin/env nix-shell
#! nix-shell ./nix_shell_shebang_dependencies.nix -i Rscript

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

library("easyPubMed")
# Other libraries that might be useful here:
# handlr (not in nixpkgs)
# rcitoid (not in nixpkgs)
# wosr
# europepmc

#try({
#	#query_string <- "17376010[uid] or 10.1038/sj.ki.5000011[doi]"
#	query_string <- "17376010[uid]"
#	pubmed_ids <- get_pubmed_ids(query_string)
#	Sys.sleep(1) # avoid server timeout
#	paper_data <- fetch_pubmed_data(pubmed_ids, format = "abstract")
#	paper_data[paper_data == ""] <- "<br>"
#	paper_data_trimmed <- paper_data[3:length(paper_data) - 1]
#	citation <- paste0(c("<p>", paste0(paper_data_trimmed, collapse = ""), "</p>"), collapse = "")
#	print(citation)
#	#cat(paste(papers[1:65], collapse = ""))
#	#cat(paste(dami_papers[1:65], collapse = ""))
#}, silent = TRUE)

get_citation <- function(citationID) {
	citation <- ""
	tryCatch({
		query_string <- paste0(citationID, "[uid]")
		# TODO: handle doi values like 10.1038/sj.ki.5000011
		#query_string <- paste0(citationID, "[doi]")
		pubmed_ids <- get_pubmed_ids(query_string)
		Sys.sleep(1) # avoid server timeout
		paper_data <- fetch_pubmed_data(pubmed_ids, format = "abstract")
		paper_data[paper_data == ""] <- "<br>"
		paper_data_trimmed <- paper_data[3:length(paper_data) - 1]
		citation <- paste0(c("<p>", paste0(paper_data_trimmed, collapse = ""), "</p>"), collapse = "")
	}, warning = function(w) {
		write(paste("Warning somewhere in get_citation.R:", w, sep = '\n'), stderr())
	}, error = function(err) {
		write(paste("Error somewhere in get_citation.R:", err, sep = '\n'), stderr())
	}, interrupt = function(i) {
		stop('Interrupted get_citation.R')
	}, finally = {
		# do something
	})

	return(citation)
}
