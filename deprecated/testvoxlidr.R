######################################################
################ FILEPATHS #####BATCH#################
######################################################
# simply change input.filepaths to a single file path
# and output to Examiner folder to run for single file
# input.filepaths <- dir_ls(here::here("data","point_cloud_data","las_files","las_local_coord", "normalized"), glob = '*.las')
# filenames <- path_file(input.filepaths)
# filenames <- gsub('.{0,22}$', '', filenames)

input <- paste0(here::here("data","point_cloud_data","las_files","las_local_coord", "normalized"), "/OREF_1255_normalized_hybrid.las")
filenames <- path_file(input)
filenames <- gsub('.{0,22}$', '', filenames)
output.filepath <- here::here("data","output","whole_stand_pai")
output.distances <- here::here("data","output","point_cloud_distances")
######################################################
################ FUNCTION SETTINGS #####BATCH#########
######################################################
res = 0.04 # downsampling resolution and voxel size
buffer.size = 10 # applies buffer for further reduction
buffer.method = "rectangle" # OPTIONAL: rectangle or circle, defaults to rectangle

cutoff = 0.2 # OPTIONAL: removes Z values under this threshold, lowers runtime
keepGround = FALSE # OPTIONAL: removes all points classified as ground, lowers runtime
thin.voxsize = 0.02 # OPTIONAL: thins PC by sampling random point from vox of given size, lowers runtime

las <- readLAS(input) 
# custom function to modify and reduce the point cloud, see function docu
las <- modifyPC(las, #input point cloud
                  buffer.size = buffer.size, #applies buffer for further reduction
                  buffer.method = buffer.method,
                  cutoff = cutoff, #removes Z values under this threshold
                  keepGround = keepGround #removes all points classified as ground
                  #thin.voxsize = thin.voxsize
                )  #thins PC by sampling random point from vox of given size
  
  
# LADCV = function(z)
# {
#     lad = LAD(z)
#     return(sd(lad)/mean(lad))
# }
# test <- voxel_metrics(las, LADCV(Z))
  
lad <- LAD(las@data$Z, dz = 0.3, k = 0.5, z0 = 1)
cv(LAD(z, dz = 1, k= 0.5, z0= 2)$lad)
sum(na.omit(lad$ladd))
mean(na.omit(lad$ladd))
plot(x = lad$lad, y = lad$z)

#https://www.sciencedirect.com/science/article/pii/S0034425714004003?via%3Dihub
#https://gis.stackexchange.com/questions/344564/creating-a-3d-voxel-plot-with-lad-values-in-lidr