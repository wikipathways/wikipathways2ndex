# ############################
# Load PFOCR results into NDEx
# ############################

# 1. Read in a "clean" csv containing only the PFOCR results intended for 
#    deposition into NDEx, e.g., pathway and network figures with > 10 genes;
#    see clean-pfocr4ndex.R.
# 2. Optionally define exportNetworkToNDExTEST() to export to test server.
# 3. Set Cytoscape style.
# 4. Loop through data extraction and prep; dataframe creation; network
#    creation and data load; and export to NDEx.


library(RCy3)
library(dplyr)

## Set working dir
setwd("/git/wikipathways/wikipathways2ndex/pfocr2ndex")

## Read in "clean" csv; see clean-pfocr4ndex.R
pfocr.clean <- read.csv("results-clean-1000.csv", stringsAsFactors = F)
fig.list.clean <- unique(pfocr.clean$figure)

## Define export to TEST server
.CyndexBaseUrl <- gsub('(.+?)\\/(v\\d+)$','\\1\\/cyndex2\\/\\2', 'http://localhost:1234/v1')
exportNetworkToNDExTEST <- function(username, password, isPublic, 
                                    network=NULL, metadata=NULL, 
                                    base.url = .defaultBaseUrl){
  suid <- getNetworkSuid(network,base.url)
  res <- cyrestPOST(paste('networks',suid,sep = '/'),
                    body = list(serverUrl="http://ndexbio.org/v2",
                                username=username,
                                password=password,
                                serverUrl='test.ndexbio.org',
                                metadata=metadata,
                                isPublic=isPublic),
                    base.url = .CyndexBaseUrl)
  return(res$data$uuid)
}

## Setup Cytoscape default style
setNodeColorDefault("#FFFFFF")
setNodeBorderWidthDefault(1.0)

## Loop through each figure
sapply(fig.list.clean, function(f) {  # subset for testing, e.g., fig.list.clean[1:5]
  # Create df gene hits per figure
  df <- data.frame(pfocr.clean[which(pfocr.clean$figure==f),], stringsAsFactors = F)
  
  # Attempt extract figure number from filename
  fn <- gsub("PMC\\d+__.*[0]{0,3}([S]{0,1}[1-9]{0,1}[0-9][a-z]{0,1})[_HTML]{0,5}\\.jpg", "\\1", f)
  fn.num <- gsub("[a-z]$","",fn)
  fn.num <- gsub("^S","",fn.num)
  if (is.na(as.integer(fn.num)))
    fn <- "Not found" # replace garbage matches with clear note

  # Extract and prep data
  print(paste("Processing ",f,"..."))
  pmcid <- df$pmcid[[1]]
  df <- df %>% mutate(id=hgnc_symbol) %>% select(-c("pmcid","figure"))
  fi <- gsub("\\.jpg", "", f) #figure ID
  ff <- gsub("PMC\\d+__", "", f)  #figure filename
  
  # Create network and load network table data into Cytoscape
  net <- createNetworkFromDataFrames(df, title=fi, collection = fi)
  net.df <- data.frame(suid=net, pmcid=pmcid, pfocrID=fi, figureNumber=fn,
                       organism="Homo sapiens",
                       methods="OCR",
                       rightsHolder="WikiPathways",
                       rights="Waiver-No Rights Reserved (CC0)",
                       figureURL=paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",pmcid,"/bin/",ff),
                       paperURL=paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",pmcid))
  ## TODO: add caption to net.df as 'description'
  ## TODO: add reference string to net.df as 'reference'
  loadTableData(net.df, 'suid', 'network','SUID')
  
  # Confirm style and export to NDEx
  setVisualStyle('default')
  exportNetworkToNDExTEST("alexanderpico","password",T,net)
  
  # Clean up Cytoscape
  deleteNetwork(net)
})
