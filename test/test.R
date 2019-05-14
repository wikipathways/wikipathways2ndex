#-------------------------------------------------------------------------------
library (RCy3)
library (RUnit)
library (graph)
library(here)
library (igraph)

CX_OUTPUT_DIR = tempdir()

source(here('wikipathways2cx.R'))
source(here('wikipathways2png.R'))

#-------------------------------------------------------------------------------
run.tests = function()
{
    options('warn'=0) # deprecation warnings (and others) are stored and reported
    
    # before doing anything else, make sure that the Cytoscape plugin version is one we can respond to
    test.app.version()
    
    # start with a clean slate, and no windows
    deleteAllNetworks()     

    test.wikipathways2cx()
    test.wikipathways2png()
    
    closeSession(FALSE)
    options('warn'=0)
    
} # run.tests
#-------------------------------------------------------------------------------
# almost every test needs to
#
#   1) announce it's name to stdout
#   2) delete any previous network with the same title, should any exist
#
# these services are provided here
#
test.prep = function (title, make.net=TRUE)
{
    write (noquote (sprintf ('------- %s', title)), stderr ())
    
    if(!make.net)
        return()
    
    if (title %in% as.character(getNetworkList())){
        deleteNetwork(title)
    }
    
    net.suid = createNetworkFromIgraph(makeSimpleIgraph(), title=title)
    return(unname(net.suid))
} 

#-------------------------------------------------------------------------------
test.app.version = function ()
{
    title = 'test.app.version'
    test.prep(title,FALSE)
    app.version.string = cytoscapeVersionInfo()
    app.version.string = unname(app.version.string['apiVersion'])
    string.tmp = gsub ('[a-z]', '', app.version.string)
    major.minor.version = as.numeric (string.tmp)
    checkTrue (major.minor.version >= 1)
    
} 

#-------------------------------------------------------------------------------
test.wikipathways2cx = function ()
{
    title = 'test.wikipathways2cx'
    test.prep(title,FALSE)
    response <- wikipathways2cx(CX_OUTPUT_DIR, list(), 'WP554')
    checkEquals (response$error, NA)
    checkTrue (response$success)
    checkTrue (file.exists(file.path(CX_OUTPUT_DIR, 'WP554__ACE_Inhibitor_Pathway__Homo_sapiens.cx')))
}

#-------------------------------------------------------------------------------
test.wikipathways2png = function ()
{
    title = 'test.wikipathways2png'
    test.prep(title,FALSE)
    response <- wikipathways2png(CX_OUTPUT_DIR, list(), 'WP554')
    checkEquals (response$error, NA)
    checkTrue (response$success)
    checkTrue (file.exists(file.path(CX_OUTPUT_DIR, 'WP554__ACE_Inhibitor_Pathway__Homo_sapiens.png')))
}

run.tests()
