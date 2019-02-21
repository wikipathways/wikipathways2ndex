source('./wikipathways2ndex.R')
library(dplyr)
library(purrr)
library(readr)
library(tidyr)

pathway_ids <- read_lines('./pathway_ids.tsv')
results <- tibble(pathway_id=pathway_ids) %>%
	mutate(ndex_result=map(pathway_id, wikipathways2ndex)) %>%
	mutate(status=ndex_result[[1]][["status"]]) %>%
	mutate(response=ndex_result[[1]][["response"]]) %>%
	select(pathway_id, status, response)
print(results)
commandQuit()
