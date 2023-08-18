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
input.filepaths <- dir_ls("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/clipped_classif/", glob = '*.las')
filenames <- path_file(input.filepaths)
filenames <- gsub('.{0,14}$', '', filenames)# remove file ending from file names

dsm.filepath <- "D:/OREF_tls_microclimate_project/raster/DSM/"
chm.filepath <- "D:/OREF_tls_microclimate_project/raster/CHM/"

paste0(dsm.filepath, filenames[1],  "_DSM_", model.res,"m", ".tif")

######################################################
################ FUNCTION SETTINGS #####BATCH#########
######################################################
model.res <- 1
las <- readLAS(paste0(input.filepaths[1]), select = "xyzrnc")
dsm <- rasterize_canopy(las, res = model.res, pitfree())
writeRaster(dsm, 
            paste0(dsm.filepath, filenames[1],  "_DSM_", model.res,"m", ".tif"), 
            overwrite = T)

######################################################
#################### getDTM ##############ca. 30 mins#
######################################################
getDTM <- function(input, output) {
  las <- readLAS(input, select = "xyzrnc")
  dtm <- rasterize_terrain(las, res = model.res, algorithm = tin())
  

  message("DTM complete. DSM")
  dsm <- rasterize_canopy(las, res = model.res, pitfree())
  writeRaster(dsm, 
              paste0(dsm.filepath, output,  "_DSM_", model.res,"m", ".tif"), 
              overwrite = T)
  message("Export complete. CHM")
  chm <- dsm - dtm
  message("CHM complete. Export")
  writeRaster(chm, 
              paste0(chm.filepath, output,  "_CHM_", model.res,"m", ".tif"), 
              overwrite = T)
  message("CHM complete. Export")
}
walk2(input.filepaths, filenames, getDTM)

message(paste0(filenames[1], " completed! Moving to next file..."))
