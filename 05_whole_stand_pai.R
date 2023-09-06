######################################################
################ FILEPATHS #####BATCH#################
######################################################
# simply change input.filepaths to a single file path
# and output to Examiner folder to run for single file
# input.filepaths <- dir_ls(here::here("data","point_cloud_data","las_files","las_local_coord", "normalized"), glob = '*.las')
# filenames <- path_file(input.filepaths)
# filenames <- gsub('.{0,22}$', '', filenames)
input <- paste0(here::here("data","point_cloud_data","las_files","las_local_coord", "normalized"), "/OREF_1245_normalized_hybrid.las")
filenames <- path_file(input)
filenames <- gsub('.{0,22}$', '', filenames)
output.filepath <- here::here("data","output","whole_stand_pai")
output.distances <- here::here("data","output","point_cloud_distances")

######################################################
################ FUNCTION SETTINGS #####BATCH#########
######################################################
res = 0.1 # downsampling resolution and voxel size in point cloud unit (m)
buffer.size = 10 # applies buffer for further reduction in point cloud unit (m)
buffer.method = "rectangle" # OPTIONAL: rectangle or circle, defaults to rectangle
correction.factor = 1.1 # apply correction factor to the PAI estimation, see Li et al 2017
cutoff = 0.5 # OPTIONAL: removes Z height below this threshold, lowers runtime
keepGround = FALSE # OPTIONAL: removes all points classified as ground, lowers runtime
thin.voxsize = 0.02 # OPTIONAL: thins PC by sampling random point from vox of given size, lowers runtime
calc.nn.k = 5 # OPTIONAL: K value to initiate k nearest neighbor search and create a dist file, 
              # increases runtime by a fair bit, see function docu

######################################################
#################### EXECUTE FUNCTION ################
######################################################
walk2(input, 
      filenames, 
      res = res, 
      buffer.size = buffer.size,
      correction.factor = correction.factor,
      #calc.nn.k = calc.nn.k, #OPTIONAL, calculate distance of k nearest neighbors
      estimatePAI)
# calculate distances of k nearest neighbors, see function docu
# las_distances <- calcDistances(las, k=5)