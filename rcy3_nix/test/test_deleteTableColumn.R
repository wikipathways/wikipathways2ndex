# RCytoscape/inst/test_cytoscape.R
#-------------------------------------------------------------------------------
library (RCy3)
library (RUnit)
library (graph)
library (igraph)


#-------------------------------------------------------------------------------
run.tests = function()
{
    options('warn'=0) # deprecation warnings (and others) are stored and reported
    
    # before doing anything else, make sure that the Cytoscape plugin version is one we can respond to
    test.app.version()
    
    # start with a clean slate, and no windows
    deleteAllNetworks()     
    
    test.deleteNetworkTableColumn()
    
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
test.deleteNetworkTableColumn = function ()
{
    title = 'test.deleteNetworkTableColumn'
    test.prep (title,FALSE)
    
    openSession()

    networkTableColumnNames <- getTableColumnNames(table = 'network')
    print(networkTableColumnNames)
    deleteTableColumn('publication', table = 'network')
    networkTableColumnNames <- getTableColumnNames(table = 'network')
    print(networkTableColumnNames)

}
