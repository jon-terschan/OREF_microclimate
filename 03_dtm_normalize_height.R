######################################################
################FILEPATHS #####BATCH###################
######################################################
# simply change input.filepaths to a single file path
# and output to Examiner folder to generate single outputs
input.filepaths <- dir_ls(here::here("data","point_cloud_data","las_files","las_local_coord", "clipped_classif"), glob = '*.las')
filenames <- path_file(input.filepaths)
filenames <- gsub('.{0,14}$', '', filenames)
output.filepath <- here::here("data","point_cloud_data","las_files","las_local_coord", "normalized")

######################################################
################ FUNCTION SETTINGS ###################
######################################################
model.res = 1 #target DTM resolution in m
dtm.algorithm <- tin() # must be the same as in dtm generation script
tin.settings.hybrid <- tin() # normalization settings hybrid method
tin.settings <- tin() # normalization settings tin method
knnidw.settings <- knnidw() # normalization settings knnidw method

######################################################
#################### EXECUTE FUNCTION ####ca. 30 mins#
######################################################
# Method must be defined as string. 
# Valid methods: dtm, tin, knnidw, hybrid 
# (see https://r-lidar.github.io/lidRbook/norm.html")
# note that execution time ramps up if there is no DTM involved
# hybrid and DTM take roughly 30 mins, the others should take
# MUCH longer, like maybe half a day?
walk2(input.filepaths, filenames, method = "hybrid", normalizeLAS)