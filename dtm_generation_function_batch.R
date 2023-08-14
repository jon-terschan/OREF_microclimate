library(lidR) #to handle Lidar data
library(microbenchmark) # for benchmarking
library(RCSF) # for CSF based ground classif
#library(ggplot2) # for plotting
#library(ggpubr) # for arranging multiple ggplots with ggarrange
#library(gstat)  # for invert distance weighting DTM generation
library(terra) # for rasterization operations
library(raster)

library(dplyr)
library(purrr)
library(fs)

file.path <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/"
filename.list <- list.files("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/", 
                            pattern = ".las", full.names = F)
output.path <- "D:/OREF_tls_microclimate_project/DTM/"

csf.settings <- csf(sloop_smooth = TRUE, 
                    class_threshold = 0.1, 
                    cloth_resolution = 0.3, 
                    rigidness = 1, 
                    time_step = 0.65)

# dtm resolution in meters
dtm.res = 1
# buffer size in meters
buffer.size = 20

for(f in 1:length(filename.list)) {
  InFile  = paste0(file.path, filename.list[f])
  OutFile = paste0(output.path, filename.list[f], "_DTM_", dtm.res, "_", buffer.size, ".tif")
  las <- readLAS(InFile, select = "xyzrn")
  clip_las <- clip_circle(las, 0, 0, buffer.size)
  classif_las <- classify_ground(clip_las, csf.settings)
  dtm_tin <- rasterize_terrain(classif_las, res = dtm.res, algorithm = tin())
  writeRaster(dtm_tin, OutFile, overwrite = T)
  print(paste0(" Bing Bong! ", filename.list[f], " is done!"))
}

filepath_list = list.files("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/", 
                           pattern = ".las", full.names = T)
# list of filenames 
filename_list <- list.files("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/", 
                            pattern = ".las", full.names = F)
customLAS<- function(x) {
  readLAS(x, select = "xyzrn") #customize to change import parameters
}

get_DTM <- function(f){
  clip_las <- clip_circle(f, 0, 0, buffer.size)
  classif_las <- classify_ground(clip_las, csf.settings)
  dtm_tin <- rasterize_terrain(classif_las, res = dtm.res, algorithm = tin())
  writeRaster(dtm_tin, paste0(output.path, filename(x), "_DTM_", dtm.res, "_", buffer.size, ".tif"), overwrite = T)
}

file_list <- sapply(filepath_list, customLAS, simplify = FALSE, USE.NAMES = T)
names(file_list) <- paste0(
  1:length(file_list), # to add an index to use for single scan reference
  "_", 
  filename_list)

lapply(file_list, function(x) {
  clip_las <- clip_circle(x, 0, 0, buffer.size)
  classif_las <- classify_ground(clip_las, csf.settings)
  dtm_tin <- rasterize_terrain(classif_las, res = dtm.res, algorithm = tin())
  writeRaster(dtm_tin, paste0(output.path, "_DTM_", dtm.res, "_", buffer.size, ".tif"), overwrite = T)
})

# WALK TO APPROACH 
# TO ADD STRING SLICING TO FIX OUTPUT NAMES AND THEN ITS PERFECT
# CODE TO CREATE FOLDER IF NECESSARY IN EXPORT 
# BENCHMARK IT AGAINST THE LOOP 

inputs <- dir_ls("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/", glob = '*.las')
outputs <- path_file(inputs)

getDTM <- function(input, output) {
  las <- readLAS(input, select = "xyzrn")
  clip_las <- clip_circle(las, 0, 0, buffer.size)
  classif_las <- classify_ground(clip_las, csf.settings)
  dtm_tin <- rasterize_terrain(classif_las, res = dtm.res, algorithm = tin())
  writeRaster(dtm_tin, paste0("D:/OREF_tls_microclimate_project/DTM/", output,  "_DTM_", dtm.res, "_", buffer.size, ".tif"), overwrite = T)
}

walk2(inputs, outputs, getDTM)
