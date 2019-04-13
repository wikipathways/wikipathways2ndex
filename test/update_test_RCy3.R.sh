mv test_RCy3.R test_RCy3.R-old

touch test_RCy3.R

echo '# from https://github.com/cytoscape/RCy3/blob/master/inst/unitTests/test_RCy3.R' >> test_RCy3.R
echo 'library(here)' >> test_RCy3.R

wget https://raw.githubusercontent.com/cytoscape/RCy3/master/inst/unitTests/test_RCy3.R -O ./raw_test_RCy3.R
cat raw_test_RCy3.R >> test_RCy3.R
rm raw_test_RCy3.R

# TODO: Currently have to change any calls to "openSession()" to make that call
# work. Is there a way to avoid changing it?
# see this issue: https://github.com/cytoscape/RCy3/issues/50#issuecomment-472082739

sed -i 's#openSession()#openSession(file.location=here("test", "sampleData", "sessions", "Yeast Perturbation.cys"))#g' test_RCy3.R
