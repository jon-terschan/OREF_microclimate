########################
#####DEPENDENCIES#######
########################
library(lidR) #to handle Lidar datza
library(microbenchmark) # for benchmarking
library(RCSF) # for CSF algorithm
library(RMCC) # needed for MCC algorithm
library(ggplot2) # for plotting
########################
#######IMPORT###########
########################
#LASfile <- system.file("extdata", "Topography.laz", package="lidR")
address <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/OREF_6_local.las"

# select parameters to load from the las file
# xyz = xyz coordinates
# r = return number
# n = number of returns
# i = intensity 
# more parameters; https://search.r-project.org/CRAN/refmans/lidR/html/readLAS.html
las <- readLAS(address, select = "xyzrni")

#BENCHMARK; import time doesnt increase if you import more parameters, only 
#object size. import time triples if you import laz and not las because it
#unwraps the files 
#lazaddress <- "D:/OREF_tls_microclimate_project/point_cloud_data/testcloud.laz"
#mbm <- microbenchmark("readLAS" = {las1 <- readLAS(address, select = "xyzrn")},
#                      "readLASi" = {lasi <- readLAS(address, select = "xyzrni")},
#                      "readLAZ" = {laz <- readLAS(lazaddress, select = "xyzrn")},
#                      times = 1
#)
#mbm

#point cloud summary
print(las)

# verify integrity of point cloud 
las_check(las)

# plot point cloud
plot(las, color = "Z", bg = "grey", axis = TRUE, legend = TRUE)

############################
##1. GROUND CLASSIFICATION##
############################

#PMF -  Progressive Morphological Filter
#Source; Zhang et al. 2003 https://ieeexplore.ieee.org/document/1202973
#Principle; Detects point with lowest elevation within a given window size, then
#points within a threshold above the lowest elevation are removed and the rest
#is assumed to be ground points. Accruacy depends on window size.
#Runtime; >1h
#Drawbacks; accuracy depends on window size and threshold, tuning required
las <- classify_ground(las, algorithm = pmf(ws = 5, th = 3))
# ws = window size
# th = threshold size


#CSF -  Cloth Simulation Function
#Source; Zhang et al. 2016 https://www.mdpi.com/2072-4292/8/6/501/htm
#Principle; Flips the point cloud, simulates a 3D cloth being thrown on it and
#then classifies the closest points as ground.
#Runtime; 10 secs or so, superfast
#Drawbacks; RCSF dependency
?csf
mycsf <- csf(sloop_smooth = F, 
             class_threshold = 0.3, 
             cloth_resolution = 3, 
             rigidness = 2, 
             time_step = 1)
las <- classify_ground(las, mycsf)

#MCC - MULTISCALE CURVATURE CLASSIFICATION
#Source; Evans and Hudak 2016 https://ieeexplore.ieee.org/document/4137852
#Principle; Iterates over points assessing minimum curvature, gradually approxima
#ting surface area - pretty unintuitively
#Runtime; 
#Drawbacks; 
las <- classify_ground(las, mcc(1.5,0.3))

############################
#####TRANSECT ASSESMENT#####
############################

# PLOT A TRANSCRIPT USING GGPLOT
# took me forever to figure out but these are coordinates for two points within
# the point cloud from which a rectangular AOI is formed
p1 <- c(-50, 40)
p2 <- c(50, 40)
#width is in y direction i think
las_tr <- clip_transect(las, p1, p2, width = 4, xz = TRUE)

ggplot(las_tr@data, aes(X,Z, color = Z)) + 
  geom_point(size = 0.5) + 
  coord_equal() + 
  theme_minimal() +
  scale_color_gradientn(colours = height.colors(50))

# custom function from lidr doc to do it all at once
plot_crossection <- function(las,
                             p1 = c(min(las@data$X), mean(las@data$Y)),
                             p2 = c(max(las@data$X), mean(las@data$Y)),
                             width = 5, colour_by = NULL) # width can be customized
{
  colour_by <- rlang::enquo(colour_by)
  data_clip <- clip_transect(las, p1, p2, width)
  p <- ggplot(data_clip@data, aes(X,Z)) + geom_point(size = 0.5) + coord_equal() + theme_minimal()
  
  if (!is.null(colour_by))
    p <- p + aes(color = !!colour_by) + labs(color = "")
  
  return(p)
}
# select area of inerest
p1 <- c(-50, 40)
p2 <- c(50, 40)
# create transcript showing classification
plot_crossection(las, p1 = p1, p2 = p2, colour_by = factor(Classification))
