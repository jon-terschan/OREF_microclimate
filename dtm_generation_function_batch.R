######################################################
################ DEPENDENCIES ########################
######################################################
library(lidR) #to handle Lidar data
library(RCSF) # for CSF based ground classif
library(terra) # for rasterization operations
library(raster)# to EXPORT DTM
library(dplyr)# for walk2
library(purrr)
library(fs) # for dir_ls, i think superior to list files

######################################################
################ FUNCTION SETTINGS ###################
######################################################
input.filepath <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/clipped_classif/"
input.filepaths <- dir_ls("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/clipped_classif/", glob = '*.las')
filenames <- path_file(input.filepaths)
filenames <- gsub('.{0,14}$', '', filenames)# remove file ending from file names
output.filepath <- "D:/OREF_tls_microclimate_project/DTM/"
dtm.res = 1   #target DTM resolution in m

######################################################
#################### PURRR WALK2  ########ca. 30 mins#
######################################################
getDTM <- function(input, output) {
  las <- readLAS(input, select = "xyzrnc")
  dtm_tin <- rasterize_terrain(las, res = dtm.res, algorithm = tin())
  writeRaster(dtm_tin, 
              paste0(output.filepath, output,  "_DTM_", dtm.res,"m", ".tif"), 
              overwrite = T)
}
walk2(input.filepaths, filenames, getDTM)

######################################################
#################### FOR LOOP  #######################
# ca 20 seconds slower than walk2 ####################
######################################################
## DEPRECATED BECAUSE I MOVED CLIPPING AND CLOTH SIMULATION FUNCTION INTO 
## ANOTHER SCRIPT
# for(f in 1:length(filenames)) {
#   inputs  = paste0(input.filepath, filenames[f], ".las")
#   outputs = paste0(output.filepath, filenames[f], "_DTM_", dtm.res, "_",
#                    buffer.size, ".tif")
#   las <- readLAS(inputs, select = "xyzrn")
#   clip_las <- clip_rectangle(las, -buffer.size, -buffer.size, buffer.size, buffer.size)
#   #clip_las <- clip_circle(las, 0, 0, buffer.size) # comment out whichever
#   classif_las <- classify_ground(clip_las, csf.settings)
#   dtm_tin <- rasterize_terrain(classif_las, res = dtm.res, algorithm = tin())
#   writeRaster(dtm_tin, outputs, overwrite = T)
#   print(paste0(" Bing Bong! ", filenames[f], " is done!"))
# }