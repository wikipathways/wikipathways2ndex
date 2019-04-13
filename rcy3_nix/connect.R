library(RCy3)

isConnectionError <- function(e) {
	passes <- grepl(paste0('.*Connection refused.*'), perl = TRUE, e$message)
	return(passes)
}

connect <- function(iteration=0) {
	maxIteration <- 15
	sleepTime <- 2
	maxTime <- sleepTime * maxIteration
	tryCatch({
		cytoscapePing()
	}, warning = function(w) {
		write('Warning connecting to Cytoscape:', stderr())
		warning(w)
	}, error = function(e) {
		if (iteration <= maxIteration) {
			if (isConnectionError(e)) {
				msg <- paste('Waiting for Cytoscape to load (', iteration * sleepTime, '/', maxTime, ')...')
				write(msg, stderr())
				Sys.sleep(sleepTime)
				connect(iteration + 1)
			} else if (grepl(paste0('.*cyrestGET.+version.*'), perl = TRUE, gettext(e))) {
				# TODO: we always get a 503 as the first ping response, even when things
				# appear to be working correctly.
				msg <- paste('503 while waiting for Cytoscape to load (', iteration * sleepTime, '/', maxTime, ')...')
				write(msg, stderr())
				Sys.sleep(sleepTime)
				connect(iteration + 1)
			} else {
				write('Error connecting to Cytoscape:', stderr())
				stop(e)
			}
		} else {
			write('Error connecting to Cytoscape:', stderr())
			stop(e)
		}
	})
}
