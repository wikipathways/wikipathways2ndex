source('./wikipathways2ndex.R')
library(dplyr)
library(readr)
library(tidyr)

pathway_ids <- read_lines('./pathway_ids.tsv')
results <- tibble(pathway_id=pathway_ids) %>%
	mutate(ndex_result=wikipathways2ndex(pathway_id)) %>%
	mutate(status=ndex_result[["status"]]) %>%
	mutate(response=ndex_result[["response"]])
print(results)
