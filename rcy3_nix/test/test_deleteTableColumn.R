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
    
    test.deleteTableColumn()
    
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
test.deleteTableColumn = function ()
{
    title = 'test.deleteTableColumn'
    test.prep (title,FALSE)
    
    openSession()

    # network
    table <- 'network'
    columnToKeep <- 'name'
    columnToDelete <- 'publication'

    tableColumnNames <- getTableColumnNames(table = table)
    checkTrue (columnToKeep %in% tableColumnNames)
    checkTrue (columnToDelete %in% tableColumnNames)

    deleteTableColumn(columnToDelete, table = table)

    tableColumnNames <- getTableColumnNames(table = table)
    checkTrue (columnToKeep %in% tableColumnNames)
    checkTrue ( ! (columnToDelete %in% tableColumnNames) )

    # node
    table <- 'node'
    columnToKeep <- 'name'
    columnToDelete <- 'IsSingleNode'

    tableColumnNames <- getTableColumnNames(table = table)
    checkTrue (columnToKeep %in% tableColumnNames)
    checkTrue (columnToDelete %in% tableColumnNames)

    deleteTableColumn(columnToDelete, table = table)

    tableColumnNames <- getTableColumnNames(table = table)
    checkTrue (columnToKeep %in% tableColumnNames)
    checkTrue ( ! (columnToDelete %in% tableColumnNames) )

    # edge
    table <- 'edge'
    columnToKeep <- 'name'
    columnToDelete <- 'EdgeBetweenness'

    tableColumnNames <- getTableColumnNames(table = table)
    checkTrue (columnToKeep %in% tableColumnNames)
    checkTrue (columnToDelete %in% tableColumnNames)

    deleteTableColumn(columnToDelete, table = table)

    tableColumnNames <- getTableColumnNames(table = table)
    checkTrue (columnToKeep %in% tableColumnNames)
    checkTrue ( ! (columnToDelete %in% tableColumnNames) )

}
