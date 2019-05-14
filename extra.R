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

getFilepathSanExt <- function(output_dir, name) {
#	# replace any non-alphanumeric characters with underscore.
#	# TODO: what about dashes? BTW, the following doesn't work:
#	filename <- paste0(gsub("[^[:alnum:]]", "_", name))
#	filepath_san_ext <- file.path(output_dir, filename)

	# RCy3 turns a filepath like this:
	#   ./WP4566__Translational_regulation_by_PDGFRÎ±__Homo_sapies
	# into this:
	#   ./WP4566__Translational_regulation_by_PDGFR?__Homo_sapies
	# See https://github.com/cytoscape/RCy3/issues/54
	# Notice that the character
	#   'Î±'
        # takes up two bytes, but the character
	#   'a'
	# takes up just one byte.
	# RCy3 changes
	#   'Î±'
	# to
	#   '±'
	# so we pre-emptively try to do the same thing here.

	# Note that there may be cases where we get a different result from
	# RCy3, e.g., what would happen if there were two single-byte non-ASCII
	# characters next to each other?

	# Also, note that this character:
	#sub_char_final <- '±'
	# is not the same as this character:
	sub_char_final <- '?'

	sub_char_initial <- 'wp_sub_char'
	filepath_san_ext_utf8 <- file.path(output_dir, name)
	Encoding(filepath_san_ext_utf8) <- "UTF-8"
	filepath_san_ext <- gsub(
				 paste0('\\', sub_char_initial),
				 sub_char_final,
				 gsub(
				      paste0('\\', sub_char_initial, '\\', sub_char_initial),
				      sub_char_initial,
				      iconv(filepath_san_ext_utf8, 'UTF-8', 'ASCII', sub = sub_char_initial)
				      )
				 )

	return(filepath_san_ext)
}
