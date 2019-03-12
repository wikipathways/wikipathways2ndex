library(rWikiPathways)

getAnalysisCollection <- function(species='Homo sapiens', reactome=FALSE) {
	analysisCollectionPathways<-getPathwaysByCurationTag('Curation:AnalysisCollection')
	humanAnalysisCollectionPathways<-analysisCollectionPathways[unname(unlist(lapply(analysisCollectionPathways, function(x) {x['species'] == species})))]

	result <- humanAnalysisCollectionPathways

	if (!reactome) {
		reactomePathways<-getPathwaysByCurationTag('Curation:Reactome_Approved')
		reactomePathwayWikiPathwaysIds<-unname(unlist(lapply(reactomePathways, function(x) x["id"])))
		nonReactomeHumanAnalysisCollectionPathways<-humanAnalysisCollectionPathways[unname(unlist(lapply(humanAnalysisCollectionPathways, function(x) {!x["id"] %in% reactomePathwayWikiPathwaysIds})))]
		result <- nonReactomeHumanAnalysisCollectionPathways
	}

	return(result)
}
