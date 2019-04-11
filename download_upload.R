#! /usr/bin/env nix-shell
#! nix-shell ./nix_shell_shebang_dependencies.nix -i Rscript

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

# ndexr relies on httr but doesn't handle importing it
library(httr)
library(ndexr)

NDEX_USER <- Sys.getenv("NDEX_USER")
NDEX_PWD <- Sys.getenv("NDEX_PWD")

#NETWORK_ID <- '37800bb2-5bb4-11e9-831d-0660b7976219'
NETWORK_ID <- 'c1b6d333-5bf5-11e9-831d-0660b7976219'

#NETWORK_ID <- '7aed4dd0-14e4-11e6-a1f8-06603eb7f303'
#NETWORK_ID <- 'b78c8f94-1c5c-11e6-a0f9-06603eb7f303'
#NETWORK_ID <- '406b59a0-03e1-11e5-ac0f-000c29cb28fb'

ndexcon <- NA
if (NDEX_USER == '' || NDEX_PWD == '') {
	message <- 'Error: environment variables NDEX_USER and/or NDEX_PWD not set.'
	write(message, stderr())
	write('In your terminal, run:', stderr())
	write('export NDEX_USER=\'your-ndex-username\'', stderr())
	write('export NDEX_PWD=\'your-ndex-password\'', stderr())
	stop(message)
} else {
	ndexcon <- ndex_connect(username=NDEX_USER, password=NDEX_PWD, host="dev2.ndexbio.org", ndexConf=ndex_config$Version_2.0)
}

#tryCatch({
#	ndex_network_set_systemProperties(ndexcon, NETWORK_ID, readOnly=FALSE)
#}, warning = function(w) {
#	write(paste("Warning making network editable in download_upload.R:", w, sep = '\n'), stderr())
#	NA
#}, error = function(err) {
#	write(paste("Error making network editable in download_upload.R:", err, sep = '\n'), stderr())
#	NA
#}, finally = {
#	# Do something
#})

rcx <- ndex_get_network(ndexcon, NETWORK_ID)

print('rcx A')
print(str(rcx, max.level = 2))

##print('rcx$metaData A')
##print(rcx$metaData)
#
##print('rcx$edgeAttributes A')
##print(rcx$edgeAttributes)
###print(str(rcx$edgeAttributes, max.level = 2))
##print('*')
##print('*')
##print('*')
##
##print('rcx$nodeAttributes A')
##print(rcx$nodeAttributes)
##print('*')
##print('*')
##print('*')
#
##print('rcx$edgeAttributes$d A')
##print(str(rcx$edgeAttributes$d, max.level = 2))
#
##rcx$properties[rcx$properties == ""] <- 0
##rcx$properties[rcx$properties == NULL] <- 0
##rcx$properties[rcx$properties == NA] <- 0
##rcx$properties[rcx$properties == NULL] <- 0
#
#rcx$edgeAttributes[is.na(rcx$edgeAttributes)] <- "string"
##print('rcx$edgeAttributes$d de-nulled')
##print(str(rcx$edgeAttributes$d, max.level = 2))
#
#rcx$nodeAttributes[is.na(rcx$nodeAttributes)] <- "string"
##print('rcx$nodeAttributes$d de-nulled')
##print(str(rcx$nodeAttributes$d, max.level = 2))
#
##rcx$properties[is.null(rcx$properties)] <- 0
##rcx$properties <- list(first=1, second=2, third=3, fourth=4, fifth=5, sixth=6, seventh=7, eight=8, ninth=9)
##rcx$properties <- c()
#
##rcx$metaData$properties[rcx$metaData$properties == NULL] <- 0
##rcx$metaData$properties[is.null(rcx$metaData$properties)] <- 0
##rcx$metaData[is.null(rcx$metaData)] <- list()
#
## line below enabled: type 'null' is not supported
##rcx$metaData$properties[[8]] <- list()
## line below disabled: Cannot deserialize instance of `java.util.ArrayList`...
##rcx$metaData$properties[[8]] <- list()
#
## line below enabled: Cannot deserialize instance of `java.util.ArrayList`...
##rcx$metaData$properties[[8]] <- list("hello"="friend")
#
##rcx$metaData$properties[[1]] <- list(hello="friend")
##rcx$metaData$properties[[2]] <- list(hello="friend")
##rcx$metaData$properties[[3]] <- list(hello="friend")
##rcx$metaData$properties[[4]] <- list(hello="friend")
##rcx$metaData$properties[[5]] <- list(hello="friend")
##rcx$metaData$properties[[6]] <- list(hello="friend")
##rcx$metaData$properties[[7]] <- list(hello="friend")
##rcx$metaData$properties[[8]] <- list(hello="friend")
#
##within(rcx$metaData, rm(properties))
##rcx$metaData$properties <- NULL
#
### this yields: Cannot deserialize instance of `java.util.ArrayList` out of VALUE_NUMBER_INT token
##rcx$metaData$properties <- 0
#
### this yields: type 'null' is not supported
##rcx$metaData$properties <- c()
#
### this doesn't even finish running
##rcx$metaData$properties <- list()
#
## this yields: Cannot deserialize instance of `java.util.ArrayList` out of START_OBJECT token
##rcx$properties <- list(first=1, second=2, third=3, fourth=4, fifth=5, sixth=6, seventh=7, eight=8, ninth=9)
#
### this yields: Cannot deserialize instance of `java.util.Map$Entry` out of VALUE_NUMBER_INT token
##rcx$metaData$properties <- list(first=1, second=2, third=3, fourth=4, fifth=5, sixth=6, seventh=7, eight=8, ninth=9)
#
### this yields: type 'null' is not supported
##rcx$properties <- NULL
##rcx$metaData$properties <- NULL
#
### this yields: type 'null' is not supported
##rcx$properties <- c()
##rcx$metaData$properties <- c()
#
### this yields: type 'null' is not supported
##rcx$properties <- 0
##rcx$metaData$properties <- 0
#
### this yields: Cannot deserialize instance of `java.util.Map$Entry` out of VALUE_NUMBER_INT token
##rcx$properties <- list(first=1, second=2, third=3, fourth=4, fifth=5, sixth=6, seventh=7, eight=8, ninth=9)
##rcx$metaData$properties <- list(first=1, second=2, third=3, fourth=4, fifth=5, sixth=6, seventh=7, eight=8, ninth=9)
#
### this yields: Cannot deserialize instance of `java.util.Map$Entry` out of VALUE_STRING token
##rcx$properties <- list(first="hey", second="hey", third="hey", fourth="hey", fifth="hey", sixth="hey", seventh="hey", eight="hey", ninth="hey")
##rcx$metaData$properties <- list(first="hey", second="hey", third="hey", fourth="hey", fifth="hey", sixth="hey", seventh="hey", eight="hey", ninth="hey")
#
### this yields: type 'null' is not supported
##rcx$properties <- list(first=list(), second=list(), third=list(), fourth=list(), fifth=list(), sixth=list(), seventh=list(), eight=list(), ninth=list())
##rcx$metaData$properties <- list(first=list(), second=list(), third=list(), fourth=list(), fifth=list(), sixth=list(), seventh=list(), eight=list(), ninth=list())
#
### this yields: Cannot deserialize instance of `java.util.Map$Entry` out of START_ARRAY token
##rcx$properties <- list(first=list(1), second=list(1), third=list(1), fourth=list(1), fifth=list(1), sixth=list(1), seventh=list(1), eight=list(1), ninth=list(1))
##rcx$metaData$properties <- list(first=list(1), second=list(1), third=list(1), fourth=list(1), fifth=list(1), sixth=list(1), seventh=list(1), eight=list(1), ninth=list(1))
#
### this yields: Cannot deserialize instance of `java.util.ArrayList` out of START_OBJECT token
##rcx$properties <- list(first=list("wow"="now"), second=list("wow"="now"), third=list("wow"="now"), fourth=list("wow"="now"), fifth=list("wow"="now"), sixth=list("wow"="now"), seventh=list("wow"="now"), eight=list("wow"="now"), ninth=list("wow"="now"))
##rcx$metaData$properties <- list(first=list("wow"="now"), second=list("wow"="now"), third=list("wow"="now"), fourth=list("wow"="now"), fifth=list("wow"="now"), sixth=list("wow"="now"), seventh=list("wow"="now"), eight=list("wow"="now"), ninth=list("wow"="now"))
#
### this yields: Cannot deserialize instance of `java.util.Map$Entry` out of START_ARRAY token
##rcx$properties <- list(first=list(c(1)), second=list(c(1)), third=list(c(1)), fourth=list(c(1)), fifth=list(c(1)), sixth=list(c(1)), seventh=list(c(1)), eight=list(c(1)), ninth=list(c(1)))
##rcx$metaData$properties <- list(first=list(c(1)), second=list(c(1)), third=list(c(1)), fourth=list(c(1)), fifth=list(c(1)), sixth=list(c(1)), seventh=list(c(1)), eight=list(c(1)), ninth=list(c(1)))
#
## this yields: type 'null' is not supported
#rcx$properties <- NULL
#rcx$metaData$properties <- NULL
#
#rcx <- rcx_asNewNetwork(rcx)
#
### type '5' is not supported
##rcx$metaData[is.na(rcx$metaData)] <- 5
##rcx$nodes[is.na(rcx$nodes)] <- 5
##rcx$edges[is.na(rcx$edges)] <- 5
##rcx$networkAttributes[is.na(rcx$networkAttributes)] <- 5
##rcx$nodeAttributes[is.na(rcx$nodeAttributes)] <- 5
##rcx$edgeAttributes[is.na(rcx$edgeAttributes)] <- 5
##rcx$cartesianLayout[is.na(rcx$cartesianLayout)] <- 5
##rcx$cyVisualProperties <- NULL
###rcx$cyVisualProperties[is.na(rcx$cyVisualProperties)] <- 5
#
### type '8' is not supported
##rcx$metaData[is.na(rcx$metaData)] <- 5
##rcx$nodes[is.na(rcx$nodes)] <- 6
##rcx$edges[is.na(rcx$edges)] <- 7
##rcx$networkAttributes[is.na(rcx$networkAttributes)] <- 8
##rcx$nodeAttributes[is.na(rcx$nodeAttributes)] <- 9
##rcx$edgeAttributes[is.na(rcx$edgeAttributes)] <- 10
##rcx$cartesianLayout[is.na(rcx$cartesianLayout)] <- 11
##rcx$cyVisualProperties <- NULL
#
### Error parsing element in CX stream: Expecting new aspect fragment at line: 1, column: 60140
##rcx$metaData[is.na(rcx$metaData)] <- 55
##rcx$nodes[is.na(rcx$nodes)] <- 6
##rcx$edges[is.na(rcx$edges)] <- 7
##rcx$networkAttributes[is.na(rcx$networkAttributes)] <- "string"
##rcx$nodeAttributes[is.na(rcx$nodeAttributes)] <- 9
##rcx$edgeAttributes[is.na(rcx$edgeAttributes)] <- 10
##rcx$cartesianLayout[is.na(rcx$cartesianLayout)] <- 11
##rcx$cyVisualProperties <- NULL
#
### Error parsing element in CX stream: malformed CX json: element 'applies_to' has mal-formed long integer: null. Error: For input string: "null"
##rcx$metaData[is.na(rcx$metaData)] <- 55
##rcx$nodes[is.na(rcx$nodes)] <- 6
##rcx$edges[is.na(rcx$edges)] <- 7
##rcx$networkAttributes[is.na(rcx$networkAttributes)] <- "string"
##rcx$nodeAttributes[is.na(rcx$nodeAttributes)] <- 9
##rcx$edgeAttributes[is.na(rcx$edgeAttributes)] <- 10
##rcx$cartesianLayout[is.na(rcx$cartesianLayout)] <- 11
#
### Error parsing element in CX stream: Expecting new aspect fragment at line: 1, column: 400477
##rcx$metaData[is.na(rcx$metaData)] <- 55
##rcx$nodes[is.na(rcx$nodes)] <- 6
##rcx$edges[is.na(rcx$edges)] <- 7
##rcx$networkAttributes[is.na(rcx$networkAttributes)] <- "string"
##rcx$nodeAttributes[is.na(rcx$nodeAttributes)] <- 9
##rcx$edgeAttributes[is.na(rcx$edgeAttributes)] <- 10
##rcx$cartesianLayout[is.na(rcx$cartesianLayout)] <- 11
##rcx$cyVisualProperties$applies_to[is.na(rcx$cyVisualProperties$applies_to)] <- 335
#
### sand timer icon, can't click
##rcx$metaData[is.na(rcx$metaData)] <- 55
##rcx$nodes[is.na(rcx$nodes)] <- 6
##rcx$edges[is.na(rcx$edges)] <- 7
##rcx$networkAttributes[is.na(rcx$networkAttributes)] <- "string"
##rcx$nodeAttributes[is.na(rcx$nodeAttributes)] <- 9
##rcx$edgeAttributes[is.na(rcx$edgeAttributes)] <- 10
##rcx$cartesianLayout[is.na(rcx$cartesianLayout)] <- 11
##rcx$cyVisualProperties$applies_to <- NULL
#
### Error parsing element in CX stream: malformed CX json: element 'applies_to' has mal-formed long integer: hey. Error: For input string: "hey"
##rcx$metaData[is.na(rcx$metaData)] <- 55
##rcx$nodes[is.na(rcx$nodes)] <- 6
##rcx$edges[is.na(rcx$edges)] <- 7
##rcx$networkAttributes[is.na(rcx$networkAttributes)] <- "string"
##rcx$nodeAttributes[is.na(rcx$nodeAttributes)] <- 9
##rcx$edgeAttributes[is.na(rcx$edgeAttributes)] <- 10
##rcx$cartesianLayout[is.na(rcx$cartesianLayout)] <- 11
##rcx$cyVisualProperties$applies_to[is.na(rcx$cyVisualProperties$applies_to)] <- "hey"
#
### Error parsing element in CX stream: Expecting new aspect fragment at line: 1, column: 400471
##rcx$metaData[is.na(rcx$metaData)] <- 55
##rcx$nodes[is.na(rcx$nodes)] <- 6
##rcx$edges[is.na(rcx$edges)] <- 7
##rcx$networkAttributes[is.na(rcx$networkAttributes)] <- "string"
##rcx$nodeAttributes[is.na(rcx$nodeAttributes)] <- 9
##rcx$edgeAttributes[is.na(rcx$edgeAttributes)] <- 10
##rcx$cartesianLayout[is.na(rcx$cartesianLayout)] <- 11
##rcx$cyVisualProperties$applies_to[is.na(rcx$cyVisualProperties$applies_to)] <- 0
#
### Error parsing element in CX stream: Expecting new aspect fragment at line: 1, column: 385045
##rcx$metaData[is.na(rcx$metaData)] <- 55
##rcx$nodes[is.na(rcx$nodes)] <- 6
##rcx$edges[is.na(rcx$edges)] <- 7
##rcx$networkAttributes[is.na(rcx$networkAttributes)] <- "string"
##rcx$nodeAttributes[is.na(rcx$nodeAttributes)] <- 9
##rcx$edgeAttributes[is.na(rcx$edgeAttributes)] <- 10
##rcx$cartesianLayout[is.na(rcx$cartesianLayout)] <- 11
##rcx$cyVisualProperties <- tail(rcx$cyVisualProperties, -3)
#
## 

rcx$networkAttributes[is.na(rcx$networkAttributes)] <- "string"
rcx$nodeAttributes[is.na(rcx$nodeAttributes)] <- "string"
rcx$edgeAttributes[is.na(rcx$edgeAttributes)] <- "string"

#rcx$metaData[is.na(rcx$metaData)] <- 55
#rcx$nodes[is.na(rcx$nodes)] <- 6
#rcx$edges[is.na(rcx$edges)] <- 7
#rcx$networkAttributes[is.na(rcx$networkAttributes)] <- "string"
##rcx$nodeAttributes[is.na(rcx$nodeAttributes)] <- 9
#rcx$edgeAttributes[is.na(rcx$edgeAttributes)] <- 10
#rcx$cartesianLayout[is.na(rcx$cartesianLayout)] <- 11

print('rcx$cyVisualProperties$properties de-nulled')
print(str(rcx$cyVisualProperties$properties, max.level = 2))
print(rcx$cyVisualProperties$properties)

rcx$cyVisualProperties$applies_to[is.na(rcx$cyVisualProperties$applies_to)] <- 0
#rcx$cyVisualProperties <- tail(rcx$cyVisualProperties, -3)
#rcx$cyVisualProperties$properties[is.na(rcx$cyVisualProperties$properties)] <- ""

#
#print('rcx de-nulled')
#print(str(rcx, max.level = 2))
#print(rcx)
#
##print('rcx$cyVisualProperties de-nulled')
##print(str(rcx$cyVisualProperties, max.level = 2))
##print(rcx$cyVisualProperties)
#
##print('rcx$cyVisualProperties$properties de-nulled')
##print(str(rcx$cyVisualProperties$properties, max.level = 2))
#
##print('rcx$properties B')
##print(rcx$properties)
##print('*')
##print('*')
##print('*')
##
##print('rcx$metaData B')
##print(rcx$metaData)
##print('*')
##print('*')
##print('*')
##
##print('rcx$metaData$properties B')
##print(rcx$metaData$properties)
##print('*')
##print(str(rcx$metaData$properties, max.level = 2))
##print('*')
##print('*')
##
##print('rcx$metaData$properties[[8]] B')
##print(rcx$metaData$properties[[8]])
###print('str(rcx$metaData$properties[[8]], max.level = 2)')
###print(str(rcx$metaData$properties[[8]], max.level = 2))
##print('*')
##print('*')
##print('*')
#
##print('rcx$edgeAttributes B')
##print(rcx$edgeAttributes)
###print(str(rcx$edgeAttributes, max.level = 2))
##print('*')
##print('*')
##print('*')
##
##print('rcx$nodeAttributes B')
##print(rcx$nodeAttributes)
##print('*')
##print('*')
##print('*')
#
##rcx$edgeAttributes$d[rcx$edgeAttributes$d == NA] <- 0
##rcx$edgeAttributes$d[rcx$edgeAttributes$d == NULL] <- 0
##print('rcx de-nulled edges')
##print(str(rcx, max.level = 2))
#
##rcx$nodeAttributes$d[rcx$nodeAttributes$d == NA] <- 0
##rcx$nodeAttributes$d[rcx$nodeAttributes$d == NULL] <- 0
##print('rcx de-nulled nodes')
##print(str(rcx, max.level = 2))
#
#print('updating metaData...')
#rcx <- rcx_updateMetaData(rcx)
##print('rcx updated metaData')
##print(str(rcx, max.level = 2))
#
##rcx$properties[rcx$properties == NULL] <- ""
##print('rcx de-nulled')
##print(str(rcx, max.level = 2))

networkIdCreated <- ndex_create_network(ndexcon, rcx)
print('networkIdCreated')
print(networkIdCreated)
#networkIdUpdated <- ndex_update_network(ndexcon, rcx, NETWORK_ID)
#print(networkIdUpdated)
