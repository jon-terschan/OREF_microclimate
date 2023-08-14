########################
#####DEPENDENCIES#######
########################
library(lidR) #to handle Lidar data
library(microbenchmark) # for benchmarking
library(RCSF) # for CSF based ground classif
library(RMCC) # needed for MCC based ground classif
library(ggplot2) # for plotting
library(ggpubr) # for arranging multiple ggplots with ggarrange
library(gstat)  # for invert distance weighting DTM generation
library(terra) # for generating a hillshade layer
########################
#######IMPORT###########
########################
# the basic way to import individual scans 
address1249 <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/OREF_1249_local.las"
address1250 <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/OREF_1250_local.las"
address1254 <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/OREF_1254_local.las"
address1255 <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/OREF_1255_local.las"

# select parameters to load from the las file
# xyz = xyz coordinates
# r = return number
# n = number of returns
# i = intensity 
# more parameters; https://search.r-project.org/CRAN/refmans/lidR/html/readLAS.html
# filter to reduce file size can also filter by height 
las1249 <- readLAS(address1249, select = "xyzrn") # filter = "-keep_first"
las1250 <- readLAS(address1250, select = "xyzrn")
las1254 <- readLAS(address1254, select = "xyzrn")
las1255 <- readLAS(address1255, select = "xyzrn")
#BENCHMARK; import time doesnt increase if you chose to import more parameters, only 
#object size. import time triples if you import laz and not las because it
#unwraps the files 
#lazaddress <- "D:/OREF_tls_microclimate_project/point_cloud_data/testcloud.laz"
#mbm <- microbenchmark("readLAS" = {las1 <- readLAS(address, select = "xyzrn")},
#                      "readLASi" = {lasi <- readLAS(address, select = "xyzrni")},
#                      "readLAZ" = {laz <- readLAS(lazaddress, select = "xyzrn")},
#                      times = 1
#)
#mbm

# list of filepaths 
filepath_list = list.files("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/", 
                           pattern = ".las", full.names = T)
# list of filenames 
filename_list <- list.files("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/", 
                            pattern = ".las", full.names = F)

#load each file as an individual environment object; probably overkill
#for (i in 1:length(filepath_list)) assign(filename_list[i], readLAS(filepath_list[i], select = "xyzrn"))

#i havent found a better way to include function arguments into lapply
customLAS<- function(x) {
  readLAS(x, select = "xyzrn") #customize to change import parameters
}
# strictly speaking makes zero difference if we use
# lapply or this but this keeps the filepaths as names around which is good for
# checking whether the next step makes sense
file_list <- sapply(filepath_list, customLAS, simplify = FALSE, USE.NAMES = T)
# rename list objects according to the name list and a custom index
names(file_list) <- paste0(
  1:length(file_list), # to add an index to use for single scan reference
  "_", 
  filename_list)
# check list object names 
names(file_list)

# now we can take individual files out of the list or operate on parts of the list
las_single_file <- file_list[X]

########################
#######INSPECT##########
########################

#point cloud summary
print(las)

# verify integrity of point cloud 
las_check(las)

# plot point cloud
plot(clip_las1249, color = "Z", bg = "grey", axis = TRUE, legend = TRUE)

########################
#########CLIP###########
########################

#CLIP point clouds to radius
clip_las1249 <- clip_circle(las1249, 0, 0, 20)
clip_las1250 <- clip_circle(las1250, 0, 0, 20) 
clip_las1254 <- clip_circle(las1254, 0, 0, 20) 
clip_las1255 <- clip_circle(las1255, 0, 0, 20) 
############################
##1. GROUND CLASSIFICATION##
############################
#set_lidr_threads(7)
#is.parallelised(classify_ground())  

#PMF -  Progressive Morphological Filter DEPRECATED
#Source; Zhang et al. 2003 https://ieeexplore.ieee.org/document/1202973
#Principle; Detects point with lowest elevation within a given window size, then
#points within a threshold above the lowest elevation are removed and the rest
#is assumed to be ground points. Accruacy depends on window size.
#Runtime; >1h
#Drawbacks; accuracy depends on window size and threshold, tuning required
#?pmf
#las <- classify_ground(clip_las1249, algorithm = pmf(ws = 0.1, th = 0.5))
# ws = window size
# th = threshold size


#CSF -  Cloth Simulation Function
#Source; Zhang et al. 2016 https://www.mdpi.com/2072-4292/8/6/501/htm
#Principle; Flips the point cloud, simulates a 3D cloth being thrown on it and
#then classifies the closest points as ground.
#Runtime; 10 secs or so, superfast
#Drawbacks; RCSF dependency
?csf
steep_settings <- csf(sloop_smooth = TRUE, 
                      class_threshold = 0.1, 
                      cloth_resolution = 0.3, 
                      rigidness = 1, 
                      time_step = 0.65)
classif_las1249 <- classify_ground(clip_las1249, steep_settings)
dtm_tin <- rasterize_terrain(classif_las1249, res = 0.5, algorithm = tin())
plot_dtm3d(dtm_tin, bg = "white") 

flat_settings <- csf(sloop_smooth = TRUE, 
                     class_threshold = 0.1, 
                     cloth_resolution = 1, 
                     rigidness = 3, 
                     time_step = 0.65)
classif_las1254 <- classify_ground(las1254, test_settings)
dtm_tin_1250 <- rasterize_terrain(classif_las1250, res = 0.5, algorithm = tin())
plot_dtm3d(dtm_tin_1250, bg = "white") 


classif_las1254 <- classify_ground(clip_las1255, test_settings)
dtm <- rasterize_terrain(classif_las1254, algorithm = tin(), pkg ="terra")
dtm_prod <- terrain(dtm, v = c("slope", "aspect"), unit = "radians")
dtm_hillshade <- shade(slope = dtm_prod$slope, aspect = dtm_prod$aspect)
plot(dtm_hillshade, col =gray(0:30/30), legend = FALSE)
plot_dtm3d(dtm, bg = "white") 
plot(dtm)

#MCC - MULTISCALE CURVATURE CLASSIFICATION
#Source; Evans and Hudak 2016 https://ieeexplore.ieee.org/document/4137852
#Principle; Iterates over points assessing minimum curvature, gradually approxima
#ting surface area - pretty unintuitively
#Runtime; 
#Drawbacks; 
#?mcc
#las <- classify_ground(las, mcc(1.5,0.3))

############################
#####TRANSECT ASSESSMENT#####
############################

# PLOT A TRANSCRIPT USING GGPLOT
# took me forever to figure out but these are coordinates for two points within
# the point cloud from which a rectangular AOI is formed
p1 <- c( min(las$X), 0 )
p2 <- c( max(las$X), 0 )
#width is in y direction i think
?clip_transect
las_tr <- clip_transect(las, p1, p2, width = 0.5, xz = TRUE)

ggplot(las_tr@data, aes(X,Z, color = Z)) + 
  geom_point(size = 0.5) + 
  coord_equal() + 
  theme_minimal() +
  scale_color_gradientn(colours = height.colors(50))

# custom function from lidr doc to do it all at once
plot_crossection <- function(las,
                             p1 = c(min(las@data$X), mean(las@data$Y)),
                             p2 = c(max(las@data$X), mean(las@data$Y)),
                             width = 0.5, colour_by = NULL) # width can be customized
{
  colour_by <- rlang::enquo(colour_by)
  data_clip <- clip_transect(las, p1, p2, width)
  p <- ggplot(data_clip@data, aes(X,Z)) + geom_point(pch='.') + coord_equal() + theme_minimal()
  
  if (!is.null(colour_by))
    p <- p + aes(color = !!colour_by) + labs(color = "")
  
  return(p)
}
# select area of inerest

p1 <- c( min(classif_las1249$X), 0 )
p2 <- c( max(classif_las1249$X), 0 )
# create transcript showing classification
plot_crossection(classif_las1249, p1 = p1, p2 = p2, colour_by = factor(Classification))
#dev.off()
plot(classif_las1249, color = "Classification")

# I tested whether the CSF produces different DTMs if it gets an entire point
# as input or buffers of various sizes
# WARNING: CODE IS SNAIL SPEED AND NOT OPTIMIZED AT ALL
# par(mfrow = c(2, 2))
# p1 <- c( min(classif_test_full$X), 0 )
# p2 <- c( max(classif_test_full$X), 0 )
# pl1 <- plot_crossection(classif_test_full, p1 = p1, p2 = p2, colour_by = factor(Classification))
# 
# p1 <- c( min(classif_test_30$X), 0 )
# p2 <- c( max(classif_test_30$X), 0 )
# pl2 <- plot_crossection(classif_test_30, p1 = p1, p2 = p2, colour_by = factor(Classification))
# 
# p1 <- c( min(classif_test2_20$X), 0 )
# p2 <- c( max(classif_test2_20$X), 0 )
# pl3 <- plot_crossection(classif_test2_20, p1 = p1, p2 = p2, colour_by = factor(Classification))
# 
# p1 <- c( min(classif_test2_10$X), 0 )
# p2 <- c( max(classif_test2_10$X), 0 )
# pl4 <- plot_crossection(classif_test2_10, p1 = p1, p2 = p2, colour_by = factor(Classification))
# 
# ggarrange(pl1, pl2, pl3, pl4, 
#           labels = c("full PC", "30m", "20m", "10m"),
#           ncol = 2, nrow = 2)
# 
# clip_las1249_20 <- clip_circle(las1249, 0, 0, 20) 
# clip_las1249_10 <- clip_circle(las1249, 0, 0, 10) 
# clip_las1249_30 <- clip_circle(las1249, 0, 0, 30) 
#
# classif_test_full <- classify_ground(las1249, steep_settings)
# dtm_full <- rasterize_terrain(classif_test_full, algorithm = tin(), pkg ="terra")
# plot(dtm_full, xlim = c(-10, 10), ylim = c(-10, 10))
# 
# classif_test_30 <- classify_ground(clip_las1249_30, steep_settings)
# dtm_30 <- rasterize_terrain(classif_test_30, algorithm = tin(), pkg ="terra")
# plot(dtm_30, xlim = c(-10, 10), ylim = c(-10, 10))
# 
# classif_test2_20 <- classify_ground(clip_las1249_20, steep_settings)
# dtm_20 <- rasterize_terrain(classif_test2_20, algorithm = tin(), pkg ="terra")
# plot(dtm_20, xlim = c(-10, 10), ylim = c(-10, 10))
# 
# classif_test2_10 <- classify_ground(clip_las1249_10, steep_settings)
# dtm_10 <- rasterize_terrain(classif_test2_10, algorithm = tin(), pkg ="terra")
# plot(dtm_10)

############################
######2. DTM Creation#######
############################

#TIN - Triangular Irregular Network
?rasterize_terrain
dtm_tin <- rasterize_terrain(classif_las1249, res = 0.5, algorithm = tin())
plot_dtm3d(dtm_tin, bg = "white") 

#IDW - Invert distance weighting
dtm_idw <- rasterize_terrain(las, algorithm = knnidw(k = 10L, p = 2))
plot_dtm3d(dtm_idw, bg = "white") 

#Kriging
#i think this requires multi-threading and a filtered point cloud to be feasible
dtm_kriging <- rasterize_terrain(las, algorithm = kriging(k = 40))
plot_dtm3d(dtm_kriging, bg = "white") 


#Benchmark algorithms;
#make or break is kriging, it just takes forever
mbm <- microbenchmark("TIN" = {dtm_tin <- rasterize_terrain(las, res = 1, algorithm = tin())},
                      "IDW" = {dtm_idw <- rasterize_terrain(las, algorithm = knnidw(k = 10L, p = 2))},
                      "Kriging" = {dtm_krig <- rasterize_terrain(las, algorithm = kriging(k = 40))},
                      times = 1
)
#mbm


#testing las catalogs i send an email to eduardo maybe he can help 
opt_chunk_size(ctg) <- 10
ctg <- readLAScatalog("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/las_6")
plot(ctg, chunk = TRUE)

??rlas
