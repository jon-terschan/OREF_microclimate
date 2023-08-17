######################################################
################ DEPENDENCIES ########################
######################################################
library(lidR) #to handle Lidar data
library(RCSF) # for CSF based ground classif
library(terra) # for rasterization operations
library(raster) # for loading raster files

######################################################
################ FUNCTION SETTINGS ###################
######################################################
file.name <- "OREF_1249_local"
file.type <- ".las"
file.path <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/"
output.path <- "D:/OREF_tls_microclimate_project/DTM/Examiner"
dtm.res = 1 #target DTM resolution in m

######################################################
#################### SINGLE FILE DTM #################
######################################################
generate_dtm <- function(file.path,
                         file.name,
                         file.type,
                         output.path,
                         buffer.size,
                         csf.settings,
                         dtm.res)
  {
  las <- readLAS(paste0(file.path, file.name, file.type), select = "xyzrnc")
  dtm_tin <- rasterize_terrain(las, res = dtm.res, algorithm = tin())
  writeRaster(dtm_tin, paste0(output.path, file.name, "_DTM_", dtm.res, "m", ".tif"), overwrite = T)
}

######################################################
################ EXECUTE AND EXAMINE #################
######################################################
generate_dtm(file.path, file.name, file.type, output.path, buffer.size, 
             csf.settings, dtm.res)

# READ AND LOOK AT FUNCTION
DTM <- raster(paste0(output.path, file.name, "_DTM_", dtm.res, "m", ".tif"))
plot(DTM)