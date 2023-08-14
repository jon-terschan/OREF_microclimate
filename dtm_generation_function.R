library(lidR) #to handle Lidar data
library(microbenchmark) # for benchmarking
library(RCSF) # for CSF based ground classif
#library(ggplot2) # for plotting
#library(ggpubr) # for arranging multiple ggplots with ggarrange
#library(gstat)  # for invert distance weighting DTM generation
library(terra) # for rasterization operations
library(raster) # for loading raster files

#PROTOTYPE DTM GENERATION FUNCTION AS A WRAPPER
generate_dtm <- function(file.path,
                         file.name,
                         file.type,
                         output.path,
                         buffer.size,
                         csf.settings,
                         dtm.res)
  {
  las <- readLAS(paste0(file.path, file.name, file.type), select = "xyzrn")
  clip_las <- clip_circle(las, 0, 0, buffer.size)
  classif_las <- classify_ground(clip_las, csf.settings)
  dtm_tin <- rasterize_terrain(classif_las, res = dtm.res, algorithm = tin())
  writeRaster(dtm_tin, paste0(output.path, file.name, "_DTM_", dtm.res, "_", buffer.size, ".tif"), overwrite = T)
}

# FUNCTION SETTINGS
file.name <- "OREF_1249_local"
file.type <- ".las"
file.path <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/"
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

# EXECUTE GENERATION FUNCTION
generate_dtm(file.path, file.name, file.type, output.path, buffer.size, 
             csf.settings, dtm.res)


# EXECUTE GENERATION FUNCTION
DTM <- raster(paste0(output.path, file.name, "_DTM_", dtm.res, "_", buffer.size, ".tif"))
plot(DTM)



