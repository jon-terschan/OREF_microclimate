########################
#####DEPENDENCIES#######
########################
#install.packages("lidR")
#install.packages("microbenchmark")
library(lidR) #to handle Lidar datza
library(microbenchmark) # to benchmark

########################
#######IMPORT###########
########################
#LASfile <- system.file("extdata", "Topography.laz", package="lidR")
address <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/OREF_6_local.las"

# select parameters 
# xyz = xyz coordinates
# r = return number
# n = number of returns
# i = intensity 
# more parameters; https://search.r-project.org/CRAN/refmans/lidR/html/readLAS.html
las <- readLAS(address, select = "xyzrn")

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
#Runtime; 
#Drawbacks; 
las <- classify_ground(las, algorithm = csf())

#MCC - Multiscale Curvature Classification
#Source; Evans and Hudak 2016 https://ieeexplore.ieee.org/document/4137852
#Principle; Iterates over points assessing minimum curvature, gradually approxima
#ting surface area - pretty unintuitively
#Runtime; 
#Drawbacks; 
las <- classify_ground(las, mcc(1.5,0.3))