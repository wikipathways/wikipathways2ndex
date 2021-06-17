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
library(rstudioapi)

INTERACTIVE <- Sys.getenv("RSTUDIO") == 1

if (INTERACTIVE && (Sys.getenv("NDEX_USER") == "" || is.null(Sys.getenv("NDEX_USER"))) || Sys.getenv("NDEX_PWD") == "" || is.null(Sys.getenv("NDEX_PWD"))) {
  NDEX_USER <-
    rstudioapi::showPrompt("prompt", "Enter your NDEx username")
  NDEX_PWD <- rstudioapi::askForPassword("Enter your NDEx password")
}

if (INTERACTIVE) {
  # clear the console
  rstudioapi::sendToConsole("\014") 
}

print(paste0("NDEX_USER: ", NDEX_USER))

Sys.setenv("NDEX_USER" = NDEX_USER)
Sys.setenv("NDEX_PWD" = NDEX_PWD)

source('./wikipathways2ndex.R')
source('./wikipathways2cx.R')
source('./get_pathways.R')
source('./extra.R')

BATCH_SIZE = 10

exportersByName <- list(
  "cx" = list(
    preprocessor = function() {
      return(list())
    },
    exporter = wikipathways2cx
  ),
  "ndex" = list(preprocessor = wikipathways2ndexPreprocess,
                exporter = wikipathways2ndex)
)

export_subset <-
  function(outdir_raw,
           exporterName,
           preprocessed,
           pathway_ids_batch) {
    outdir <- normalizePath(outdir_raw)
    exporter <- exportersByName[exporterName][[1]]$exporter
    if (!is.function(exporter)) {
      print_help(parser)
      stop("valid exporter must be specified.n", call. = FALSE)
    }
    
    if (!INTERACTIVE) {
      system(paste0(
        "(cd ",
        here("nix_rcy3/extras"),
        "; bash cytoscapestart.sh)"
      ))
    }
    deleteAllNetworks()
    results <- list()
    tryCatch({
      results <- tibble(pathway_id = pathway_ids_batch) %>%
        mutate(returned = map(pathway_id, function(pathway_id) {
          exporter(outdir, preprocessed, pathway_id)
        })) %>%
        mutate(name = map_chr(returned, "name")) %>%
        mutate(output = map_chr(returned, "output")) %>%
        mutate(success = map_lgl(returned, "success")) %>%
        mutate(error = map_chr(returned, "error")) %>%
        select(pathway_id, name, success, error, output)
    }, warning = function(w) {
      write(paste(
        paste0(
          'Warning in exporter ',
          exporterName,
          ', called by export_subset in export.R:'
        ),
        w,
        sep = '\n'
      ), stderr())
    }, error = function(e) {
      # we only need to close it here, because it otherwise closes in wikipathways2ndex/wikipathways2cx/etc
      closeSession(FALSE)
      write(paste(
        paste0(
          'Error in exporter ',
          exporterName,
          ', called by export_subset in export.R:'
        ),
        e,
        sep = '\n'
      ), stderr())
    }, interrupt = function(i) {
      closeSession(FALSE)
      write(paste(
        paste0(
          'Interrupted exporter ',
          exporterName,
          ', called by export_subset in export.R:'
        ),
        i,
        sep = '\n'
      ), stderr())
    }, finally = {
      deleteAllNetworks()
      if (!INTERACTIVE) {
        system(paste0(
          "(cd ",
          here("nix_rcy3/extras"),
          "; bash cytoscapestop.sh)"
        ))
      }
    })
    return(results)
  }

my_option_list = list(
  make_option(
    c("--head"),
    type = "numeric",
    default = Inf,
    help = "limit to first X inputs [default= %default]",
    metavar = "integer"
  ),
  make_option(
    c("--tail"),
    type = "numeric",
    default = Inf,
    help = "limit to last Y inputs [default= %default]",
    metavar = "integer"
  )
)

parser <-
  OptionParser(
    usage = paste0("%prog [options] input exporter outdir"),
    description = paste0(
      "input values: <a filepath>,<the string 'AnalysisCollection'> valid exporter values=<",
      paste(names(exportersByName), collapse = '>,<'),
      "> valid outdir values: <a filepath>"
    ),
    option_list = my_option_list
  )
if (INTERACTIVE) {
  input <-
    rstudioapi::showPrompt(
      "prompt",
      "Enter input (valid values: <a filepath> or <AnalysisCollection>):",
      default = "AnalysisCollection"
    )
  
  exporter_msg <-
    paste0("Enter exporter (valid values: <",
           paste(names(exportersByName), collapse = '>,<'),
           ">):")
  exporter <-
    rstudioapi::showPrompt("prompt", exporter_msg, default = "ndex")
  
  output <-
    rstudioapi::showPrompt("prompt",
                           "Enter an output (valid value: <a filepath>):",
                           default = "./wikipathways2ndex_output")
  
  head_limit <-
    as.numeric(
      rstudioapi::showPrompt("prompt", "Specify how many pathways to process", default = Inf)
    )
  
  parsed <-
    list(args = c(input, exporter, output),
         options = list(head = head_limit))
  
} else {
  parsed <- parse_args(parser, positional_arguments = 3)
  
}

args <- parsed$args
options <- parsed$options

input <- args[1]
exporterName <- args[2]
outdir_raw <- args[3]

if (!dir.exists(outdir_raw)) {
  write(paste(
    'Warning: Directory',
    outdir_raw,
    'does not exist. Creating now.'
  ),
  stderr())
  dir.create(outdir_raw)
  #} else {
  #	# TODO: can we set this up so this doesn't need to be empty?
  #	# TODO: is there a better way to check for an empty directory?
  #	# NOTE: length must be greater than 2, b/c the list always includes '.' and '..'
  #	if(length(dir(outdir, all.files=TRUE)) > 2) {
  #		stop(paste('Error in export.R: output dir', outdir, 'must be empty.'))
  #	}
}

if (is.null(input)) {
  print_help(parser)
  stop("input must be specified.", call. = FALSE)
}
if (is.null(exporterName)) {
  print_help(parser)
  stop("exporter must be specified.n", call. = FALSE)
}

tryCatch({
  pathway_ids <- list()
  if (grepl('\\.tsv$', input)) {
    pathway_ids <- read_lines(input)
  } else if (input == "AnalysisCollection") {
    pathway_ids <- get_value_by_key(getAnalysisCollection(), 'id')
  } else {
    stop("failed to read in input.n", call. = FALSE)
  }
  
  print(options$head)
  if (is.numeric(options$head) && !is.infinite(options$head)) {
    pathway_ids <- head(pathway_ids, options$head)
  }
  if (is.numeric(options$tail) && !is.infinite(options$tail)) {
    pathway_ids <- tail(pathway_ids, options$tail)
  }
  
  print(paste0("processing ", length(pathway_ids), " pathway_ids"))

  preprocessor <- exportersByName[exporterName][[1]]$preprocessor
  preprocessed <- preprocessor()
  
  # TODO: look at wikipathways2ndex regarding grouping by organism
  for (pathway_ids_batch in split(pathway_ids, ceiling(seq_along(pathway_ids) /
                                                       BATCH_SIZE))) {
    print(paste0('Current batch: ', pathway_ids_batch))
    results <-
      export_subset(outdir_raw, exporterName, preprocessed, pathway_ids_batch)
    print(as.data.frame(results))
  }
}, warning = function(w) {
  write(paste('Warning in export.R:', w, sep = '\n'), stderr())
}, error = function(e) {
  write(paste('Error in export.R:', e, sep = '\n'), stderr())
  if (!INTERACTIVE) {
    system(paste0("(cd ", here("nix_rcy3/extras"), "; bash cytoscapestop.sh)"))
  }
}, interrupt = function(i) {
  write(paste('Interrupted export.R:', i, sep = '\n'), stderr())
  if (!INTERACTIVE) {
    system(paste0("(cd ", here("nix_rcy3/extras"), "; bash cytoscapestop.sh)"))
  }
  #stop('Interrupted export.R')
}, finally = {
  # do something
})
