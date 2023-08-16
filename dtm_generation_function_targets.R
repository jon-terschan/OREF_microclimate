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

######### PROCESSING SETTINGS
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
######### PROCESSING SETTINGS


######### IMPORT WHOLE LIST
filepath_list = dir_ls("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/", glob = "*.las")
# list of filenames 
filename_list <- list.files("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/", 
                            pattern = ".las", full.names = F)
customLAS<- function(x) {
  readLAS(x, select = "xyzrn") #customize to change import parameters
}

file_list <- sapply(filepath_list, function(x){
  readLAS(x, select = "xyzrn") 
}, 
simplify = FALSE, USE.NAMES = T)

names(file_list) <- paste0(
  # 1:length(file_list), to add an index to use for single scan reference
  # "_", 
  filename_list)
names(file_list) <- gsub('.{0,4}$', '', names(file_list))

######### CLIP AND CLASSIFY GROUND 
file_list <- lapply(file_list, function(x) {
  clip_circle(x, 0, 0, buffer.size)
})

lapply(file_list, function(x) {
  classify_ground(x, csf.settings)
})

dtm_list <- lapply(file_list, function(x) {
  rasterize_terrain(x, res = dtm.res, algorithm = tin())
})

for (f in 1:length(dtm_list)) {
  writeRaster(dtm_list[[f]], paste0(output.path, names(dtm_list[f]), "_DTM_", dtm.res, "_", buffer.size, ".tif"), overwrite = T)
}

