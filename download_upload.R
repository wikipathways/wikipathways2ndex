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

NETWORK_ID <- 'aedc61b5-5bfe-11e9-831d-0660b7976219'

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

#rcx <- rcx_asNewNetwork(rcx)

rcx$networkAttributes$d[is.na(rcx$networkAttributes$d)] <- "string"
rcx$nodeAttributes$d[is.na(rcx$nodeAttributes$d)] <- "string"
rcx$edgeAttributes$d[is.na(rcx$edgeAttributes$d)] <- "string"
rcx$cyVisualProperties$applies_to[is.na(rcx$cyVisualProperties$applies_to)] <- 0
rcx <- rcx_updateMetaData(rcx)
print('rcx updated metaData')
print(str(rcx, max.level = 2))

networkIdCreated <- ndex_create_network(ndexcon, rcx)
print('networkIdCreated')
print(networkIdCreated)
#ndex_network_set_systemProperties(ndexcon, networkIdCreated, readOnly=TRUE, visibility="PUBLIC", showcase=TRUE)
#networkIdUpdated <- ndex_update_network(ndexcon, rcx, NETWORK_ID)
#print(networkIdUpdated)
