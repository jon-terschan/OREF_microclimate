######################################################
################## IMPORT SETTINGS ###################
######################################################
input.filepaths <- dir_ls(here::here("data","point_cloud_data","las_files","las_local_coord"), glob = '*.las')
filenames <- path_file(input.filepaths)
filenames <- gsub('.{0,10}$', '', filenames) # remove file ending from file names
output.filepath <- here::here("data","point_cloud_data","las_files","las_local_coord", "clipped_classif")

######################################################
################ FUNCTION SETTINGS #####BATCH#########
######################################################
csf.settings <- csf(sloop_smooth = TRUE, #cloth simulation parameters,
                    class_threshold = 0.1, #see ?csf for help
                    cloth_resolution = 0.3, 
                    rigidness = 1, 
                    time_step = 0.65)
buffer.size = 20  #buffer size in m
buffer.method = "rectangle" # "circle", based on origin

######################################################
#################### EXECUTE FUNCTION ####ca. 30 mins#
######################################################
walk2(input.filepaths, filenames, 
      buffer.size = buffer.size,
      buffer.method = buffer.method,
      clip_classif)