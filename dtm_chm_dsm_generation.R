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
################ FILEPATHS #####BATCH#################
######################################################
# simply change input.filepaths to a single file path
# and output to examiner folder to run for single file
input.filepaths <- dir_ls("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/clipped_classif/", glob = '*.las')
filenames <- path_file(input.filepaths)
filenames <- gsub('.{0,14}$', '', filenames)# remove file ending from file names

dtm.filepath <- "D:/OREF_tls_microclimate_project/raster/DTM/"
dsm.filepath <- "D:/OREF_tls_microclimate_project/raster/DSM/"
chm.filepath <- "D:/OREF_tls_microclimate_project/raster/CHM/"

######################################################
################ FUNCTION SETTINGS #####BATCH#########
######################################################
model.res = 1   #target DTM/DSM/CSM resolution in m
dtm.algorithm = tin()
dsm.algorithm = pitfree()

######################################################
#################### getModels########################
######################################################
getModels <- function(input, filename, modOutputs) {
  las <- readLAS(input, select = "xyzrnc")
  dtm <- rasterize_terrain(las, res = model.res, algorithm = dtm.algorithm)
  dsm <- rasterize_canopy(las, res = model.res, dsm.algorithm)
  if(grepl("dtm", modOutputs, fixed=TRUE) == TRUE) {
  writeRaster(dtm, 
              paste0(dtm.filepath, filename,  "_DTM_", model.res,"m", ".tif"), 
              overwrite = T)
  }
  if(grepl("dsm", modOutputs, fixed=TRUE) == TRUE) {
    writeRaster(dsm, 
                paste0(dsm.filepath, filename,  "_DSM_", model.res,"m", ".tif"), 
                overwrite = T)
  }
  if(grepl("chm", modOutputs, fixed=TRUE) == TRUE) {
    chm <- dsm - dtm
    writeRaster(chm, 
                paste0(chm.filepath, filename,  "_CHM_", model.res,"m", ".tif"), 
                overwrite = T)
  }
  message(paste0(filename, " completed! Moving to next file..."))
}

######################################################
#################### EXECUTE FUNCTION ####ca. 30 mins#
######################################################
# modOutputs should be your desired outputs as string
# note: removing outputs wont affect average runtime of ~2 mins per file
walk2(input.filepaths, filenames, modOutputs = c("dtm, dsm, chm"), getModels)

######################################################
#################### FOR LOOP  #######################
# ca 20 seconds slower than walk2 ####################
######################################################
## DEPRECATED: I MOVED CLIPPING AND CLOTH SIMULATION FUNCTION INTO 
## ANOTHER SCRIPT AND DECIDED TO USE CUSTOM FUNCTIONS FOR EVERYTHING
## input.filepath <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/clipped_classif/"
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