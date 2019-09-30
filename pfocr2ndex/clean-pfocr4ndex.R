# #############################
# Filter PFOCR results for NDEx
# #############################

# 1. Read in csv of PFOCR results.
# 2. Optionally read in intermediate "clean" file if processing in rounds.
# 3. Loop through figures and interactively subset.
# 4. Save "clean" csv for pfocr2ndex.R.

library(RCy3)
library(dplyr)
library(jpeg)

## Set working dir to location with CSV and images to be pruned (e.g., copies)
setwd("~/Dropbox (Gladstone)/Work/Projects/PathwayFigureOCR/2019_10000figs")

## Read in csv of PFOCR results
pfocr <- read.csv("results.csv", stringsAsFactors = F)
fig.list <- unique(pfocr$figure)

## Initialize clean df or read in from last round
#pfocr.clean <- setNames(data.frame(matrix(ncol = 8, nrow = 0)), colnames(pfocr))
pfocr.clean <- read.csv("results-clean-1000.csv", stringsAsFactors = F)

## Screen PFOCRs to prepare a pfocr.clean csv for export to NDEx; see pfocr2ndex.R
sapply(fig.list, function(f) {  # subset for rounds, e.g., fig.list[1:5]
  if (!grepl("^PMC\\d+__",f)){
    print(paste("Skipping",f)) #skip garbage entries
    next
  }
  # Create df gene hits per figure
  df <- data.frame(pfocr[which(pfocr$figure==f),], stringsAsFactors = F)
  
  if (nrow(df) > 10) { #exclude low gene count figs
    print(paste("Processing ",f,"..."))
    
    # Retrieve images from PMC or from local fir 
    f.path<-paste0('images_clean/',f)
    
    ## FROM PMC
    # pmcid <- df$pmcid[[1]]
    # ff <- gsub("PMC\\d+__", "", f)
    # figure_link=paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",pmcid,"/bin/",ff)
    # download.file(figure_link,f.path, mode = 'wb')
    
    # Display image for review 
    jj <- readJPEG(f.path,native=TRUE)
    plot(0:1,0:1,type="n",ann=FALSE,axes=FALSE)
    rasterImage(jj,0,0,1,1)
    ## enter or '-enter (Note: that actually produced pair of single quotes)
    res <- readline(prompt="Press [enter] to skip or [']-[enter] to keep")
    
    # Build clean df and prune collection
    if (res == "''"){
      pfocr.clean <- bind_rows(pfocr.clean,df)
    } else {
      file.remove(f.path)
    }
  }
})

fig.list.clean <- unique(pfocr.clean$figure)  #optional for debugging and stats

## Save "clean" csv for pfocr2ndex.R
write.csv(pfocr.clean, "results-clean-1000.csv", row.names = F)