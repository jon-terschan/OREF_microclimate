######################################################
################ FILEPATHS #####BATCH#################
######################################################
# simply change input.filepaths to a single file path
# and output to Examiner folder to run for single file
input.filepaths <- dir_ls(here::here("data","point_cloud_data","las_files","las_local_coord", "clipped_classif"), glob = '*.las')
filenames <- path_file(input.filepaths)
filenames <- gsub('.{0,14}$', '', filenames)# remove file ending from file names
dtm.filepath <- here::here("data","raster","DTM")
dsm.filepath <- here::here("data","raster","DSM")
chm.filepath <- here::here("data","raster","CHM")

######################################################
################ FUNCTION SETTINGS #####BATCH#########
######################################################
model.res = 1   #target DTM/DSM/CSM resolution in m
dtm.algorithm = tin()
dsm.algorithm = pitfree()

######################################################
#################### EXECUTE FUNCTION ####ca. 30 mins#
######################################################
# modOutputs should be your desired outputs as string
# note: removing outputs wont affect average runtime of ~2 mins per file
walk2(input.filepaths, filenames, modOutputs = c("dtm, dsm, chm"), getModels)

######################################################
#################### PLOT OUTPUT MODELS ##############
######################################################
exportPlots(dir_ls(here::here("data","raster","DTM"), glob = '*.tif'))
exportPlots(dir_ls(here::here("data","raster","DSM"), glob = '*.tif'))
exportPlots(dir_ls(here::here("data","raster","CHM"), glob = '*.tif'))