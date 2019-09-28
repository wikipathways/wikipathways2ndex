#! /usr/bin/env nix-shell
#! nix-shell ./nix_shell_shebang_dependencies.nix -i Rscript

library(dplyr)
library(here)
library(rjson)
library(rWikiPathways)
library(tidyr)
library(XML)
library(utf8)

#options(encoding = "UTF-8")

fileName <- 'WP3599.gpml.xml'
#pathway <- readChar(fileName, file.info(fileName)$size)
pathway <- paste0(paste(readLines(fileName, encoding = 'latin1'), sep = '\n'), '\n')
print(pathway)
#Encoding(pathway) <- "latin1"

print('pathway')
print(as_utf8(pathway))

# TODO: can't parse GPML for WP23. Complains about encoding.
pathwayParsed <- xmlTreeParse(pathway, asText = TRUE, useInternalNodes = TRUE, getDTD=FALSE)
#print('pathwayParsed')
#print(pathwayParsed)
# TODO: look into formatting description as HTML. Is the string wikitext?
# For example, '\n' could be '<br>'
description <- xmlSerializeHook(getNodeSet(pathwayParsed,
			 "/gpml:Pathway/gpml:Comment[@Source='WikiPathways-description']/text()",
			 c(gpml = "http://pathvisio.org/GPML/2013a")))[[1]]
print('description')
print(description)
