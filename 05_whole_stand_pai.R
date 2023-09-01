######################################################
################ FILEPATHS #####BATCH#################
######################################################
# simply change input.filepaths to a single file path
# and output to Examiner folder to run for single file
# input.filepaths <- dir_ls(here::here("data","point_cloud_data","las_files","las_local_coord", "normalized"), glob = '*.las')
# filenames <- path_file(input.filepaths)
# filenames <- gsub('.{0,22}$', '', filenames)

input <- paste0(here::here("data","point_cloud_data","las_files","las_local_coord", "normalized"), "/OREF_1255_normalized_hybrid.las")
filenames <- path_file(input)
filenames <- gsub('.{0,22}$', '', filenames)
output.filepath <- here::here("data","output","whole_stand_pai")
output.distances <- here::here("data","output","point_cloud_distances")
######################################################
################ FUNCTION SETTINGS #####BATCH#########
######################################################
res = 0.04 # downsampling resolution and voxel size
buffer.size = 7 # applies buffer for further reduction
buffer.method = "rectangle" # OPTIONAL: rectangle or circle, defaults to rectangle
correction.factor = 1.1 # apply correction factor to the PAI estimation, see Li et al 2017
cutoff = 0.2 # OPTIONAL: removes Z values under this threshold, lowers runtime
keepGround = FALSE # OPTIONAL: removes all points classified as ground, lowers runtime
thin.voxsize = 0.02 # OPTIONAL: thins PC by sampling random point from vox of given size, lowers runtime
calc.nn.k = 5 # OPTIONAL: K value to initiate k nearest neighbor search and create a dist file, 
              # increases runtime by a fair bit, see function docu

estimatePAI <- function(input, filename, res, buffer.size, correction.factor, calc.nn.k){
# system time marker
t1 = Sys.time()
# read input point cloud
las <- readLAS(input) 
# custom function to modify and reduce the point cloud, see function docu
las <- modifyPC(las, #input point cloud
                buffer.size = buffer.size, #applies buffer for further reduction
                buffer.method = buffer.method,
                cutoff = cutoff, #removes Z values under this threshold
                keepGround = keepGround, #removes all points classified as ground
                thin.voxsize = thin.voxsize)  #thins PC by sampling random point from vox of given size
# Initiate k nearest neighbor search with nested function if optional argument is provided
if (missing(calc.nn.k) == FALSE) {
  message("K value for nearest neighbor search provided. Calculating point cloud distances.")
  las_distances <- calcDistances(las, k = calc.nn.k)
  dist.file <- paste0(output.distances, "/", filename, "_distances.csv")
  write.table(las_distances, dist.file, sep = ",", row.names = F, col.names = T, quote = F)
}
# extract XYZ coordinates from the point cloud
data <- las@data[,c(1:3)]
# round XYZ coordinates + number of points associated with the rounded coord, see function docu
plot_vox <- vox(data, res = res)
# determine minimum and maximum heights of voxel slices
z_seq <- seq(min(plot_vox$z), max(plot_vox$z), res)
# create a raster with the same extent as the point cloud
ground <- raster(nrow = ((2*buffer.size) / res),
                   ncol = ((2*buffer.size) / res),
                   xmn = -buffer.size,
                   xmx = buffer.size,
                   ymn = -buffer.size,
                   ymx = buffer.size)
# assign 0 values to raster
values(ground) <- 0
# convert the raster to points
ground_dt <- as.data.table(rasterToPoints(ground))
# copy paste the empty raster on top of each other to create voxels
empty <- as.data.table(cbind(rep(ground_dt$x, length(z_seq)), 
                               rep(ground_dt$y, length(z_seq))))
# set X and Y coordinate names in the voxel space
data.table::setnames(empty, c("x", "y"))
# assign the Z coordinate based on the z slices to the voxel space
empty$z <- rep(z_seq, each = nrow(distinct(empty, x, y)))
# check what this does, i think it assigns 0 to all number of points
empty[, npts := 0]
# combine empty voxel space and rounded point cloud
plot_block = dplyr::bind_rows(plot_vox, empty)
plot_block = plot_block[, npts := sum(npts), keyby = .(x, y, z)]
# garbage collection
gc()
# plot_voxels_full_grid(plot_block, res = 1)
# calculate z slices
z_slices <- seq(min(plot_block$z), max(plot_block$z), res)
# z_slices <- subset(z_slices, z_slices >= 1)
# calculate lai profiles based on z slices
lai_profiles <- as.data.frame(matrix(0, length(z_slices), 2))
names(lai_profiles) <- c("height", "pai")
# throw a status update
print("calculating z slices... ", quote = F)
# set progress bar
pb = txtProgressBar(min = 0, max = length(z_slices), initial = 0, style = 1) 
# loop through slices and estimate percentage of filled voxels to total voxels 
# here is also where the correction factor is applied
for(j in 1:length(z_slices)) {
  plot.slice <- plot_block[z %in% z_slices[j],]
  
  ni <- as.numeric(nrow(plot.slice[npts > 0,]))
  nt <- as.numeric(nrow(plot.slice))
  
  N <- ni / nt
  l <- correction.factor * N
  
  lai_profiles$height[j] <- z_slices[j]
  lai_profiles$pai[j] <- l
  
  gc()
  remove(plot.slice)
  gc()
  
  setTxtProgressBar(pb, j)
  
}
# create output data frame and name columns
output <- data.frame(matrix(0, 1, 2))
names(output) <- c("plot", "pai")
# assign values to the output data frame
output$plot <- filename
output$pai <- sum(lai_profiles$pai, na.rm = T)
output$h_dom <- max(z_slices)
output$res <- res
# print output message 
print(paste0(filename, " PAI = ", output$pai))
# define output filepath and export results
out.file <- paste0(output.filepath, "/", filename, "_whole_stand_pai.csv")
write.table(output, out.file, sep = ",", row.names = F, col.names = T, quote = F)
# throw system time elapsed message
t2 = Sys.time()
print(paste0(filename, " complete... time elapsed ", round(t2 - t1, 2)), quote = FALSE)
# garbage collection and environ clearing
gc()
remove(lai_profiles)
remove(output)
gc() 
}

######################################################
#################### EXECUTE FUNCTION ####ca. 30 mins#
######################################################
walk2(input, 
      filenames, 
      res = res, 
      buffer.size = buffer.size,
      correction.factor = correction.factor,
      #calc.nn.k = calc.nn.k, #OPTIONAL, calculate distance of k nearest neighbors
      estimatePAI)
# # calculate distances of k nearest neighbors, see function docu
# las_distances <- calcDistances(las, k=5)