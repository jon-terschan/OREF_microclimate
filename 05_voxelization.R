library(lidR) # to handle Lidar data
library(RCSF) # for CSF based ground classif
library(terra) # for rasterization operations
library(raster) # to EXPORT DTM
library(dplyr) # for walk2
library(purrr) # for walk2
library(fs) # for directory management functions
library(here) # for operating system agnostic working directory
library(ggplot2) # for plotting models
library(microbenchmark)
# install.packages("remotes")
library(remotes)
# remotes::install_github("Antguz/rTLS")
library(rTLS)

input <- paste0(here::here("data","point_cloud_data","las_files","las_local_coord"), "/OREF_1255_local.las")
las <- readLAS(input, select = "xyzrnt", filte)
min(las@data$NumberOfReturns)
unique(las@data$gpstime)
voxelspace <- voxels(las@data[,c(1:3)], edge_length = c(1, 1, 1), threads = 7, obj.voxel = TRUE)
save(file = voxelspace)

# install.packages("parallel")
# parallel::detectCores()
# mbm = microbenchmark(
#   thr1 = voxels(las@data[,c(1:3)], edge_length = c(1, 1, 1), threads = 1, obj.voxel = TRUE),
#   thr3 = voxels(las@data[,c(1:3)], edge_length = c(1, 1, 1), threads = 3, obj.voxel = TRUE),
#   thr5 = voxels(las@data[,c(1:3)], edge_length = c(1, 1, 1), threads = 5, obj.voxel = TRUE),
#   thr7 = voxels(las@data[,c(1:3)], edge_length = c(1, 1, 1), threads = 7, obj.voxel = TRUE),
#   times= 30
# )
# mbm

plot_voxels(voxelspace)
?plot_voxels
las@data[,c(1:3)]

install.packages("AMAPVox")
library(AMAPVox)

getVoxelSize(voxelspace)
writeVoxelSpace(voxelspace)
readVoxelSpace(voxelspace)
writeVoxelSpace(voxelspace)
readVoxelSpace(system.file("extdata", "tls_sample.vox", package = "AMAPVox"))

VoxelSpace
remotes::install_github("Molina-Valero/FORTLS", dependencies = TRUE)
