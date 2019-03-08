library(here)
library(RCy3)

source('connect.R')
connect()

installApp("enhancedGraphics")

source('./test/test_RCy3.R')

run.tests()

# TODO: the following don't work:
#openSession()
#openSession(file.location="./sampleData/sessions/Yeast Perturbation.cys")
#openSession(file.location="./test/sampleData/sessions/Yeast Perturbation.cys")
# This does:
#openSession(file.location=here("test", "sampleData", "sessions", "Yeast Perturbation.cys"))
