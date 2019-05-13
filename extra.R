library(jsonlite)
library(purrr)

get_value_by_key <- function(mylist, mykey) {
	return(unname(unlist(lapply(mylist, function(x) x[mykey]))))
}

# see https://stackoverflow.com/a/19655909
is.blank <- function(x, false.triggers=FALSE){
	if(is.function(x)) return(FALSE)
	# Some of the tests below trigger
	# warnings when used on functions
	return(
		is.null(x) ||                # Actually this line is unnecessary since
		length(x) == 0 ||            # length(NULL) = 0, but I like to be clear
		all(is.na(x)) ||
		all(x=="") ||
		(false.triggers && all(!x))
	)
}

canBeInteger <- function(x) {grepl('^\\d+$', x)}
cannotBeInteger <- function(x) {!grepl('^\\d+$', x)}

updateNetworkTable <- function(networkName, columnName, columnValue) {
	updatedNetworkTableColumns <- NA
	# what if it's a vector?
	# should we ever use I()?
	if (is.list(columnValue)) {
		if (every(columnValue, is.atomic)) {
			updatedNetworkTableColumns <- data.frame(
								 name = networkName,
								 #columnName = paste(list(unlist(columnValue))),
								 #columnName = I(list(unlist(columnValue))),
								 columnName = paste0(toJSON(unlist(columnValue), auto_unbox = TRUE)),
								 stringsAsFactors=FALSE)
		} else {
			# do I need to check for is.recursive?
			updatedNetworkTableColumns <- data.frame(
								 name = networkName,
								 columnName = paste0(toJSON(columnValue)),
								 #columnName = serializeJSON(columnValue)[1],
								 stringsAsFactors=FALSE)
		}
	} else {
		updatedNetworkTableColumns <- data.frame(name = networkName, columnName = columnValue, stringsAsFactors=FALSE)
	}
	colnames(updatedNetworkTableColumns) <- c('name', columnName)
	row.names(updatedNetworkTableColumns) <- c(networkName)
	# TODO: use SUID here as matching key 
	loadTableData(updatedNetworkTableColumns, table = 'network')
}
