################################################################################
###########################VOXR adapted from Flynn et al.#######################
################################################################################
library(VoxR)
input <- paste0(here::here("data","point_cloud_data","las_files","las_local_coord"), "/OREF_1255_local.las")
las <- readLAS(input)

# the age old problem of finding minimum euclidian distance
# this should work but probably takes FOREVER due to exponential 
# library(spatstat.geom)
# points <- pp3(las@data$X, las@data$Y, las@data$Z,
#               box3(c(-20, 20)))
# nndi <- min(nndist(points))

################################################################################
vox = function(data,res,message){
  #- declare variables to pass CRAN check as suggested by data.table maintainers
  x=y=z=npts=.N=.=':='=NULL
  #- check for data consistency and convert to data.table
  check=VoxR::ck_conv_dat(data,message=message)
  # throw error messages if wrong resolution was provided 
  if(missing(res)){
    stop("No voxel resolution (res) provided")
  }
  else{
    #- res must be a vector
    if(!is.vector(res)) stop("res must be a vector of length 1")
    #- res must be numeric
    if(!is.numeric(res)) stop("res must be numeric")
    #- res must be numeric
    if(res<=0) stop("res must be positive")
    #- res must be of length 1
    if(length(res)>1){
      res=res[1]
      warning("res contains more than 1 element. Only the first was used")
    }
  }
  #- keep only the data part from the check list
  data=check$data
  #- round point coordinates with the user defined resolution
  data[,':='(x = Rfast::Round( x / res ) * res,
             y = Rfast::Round( y / res ) * res,
             z = Rfast::Round( z / res ) * res)]
  # add number of points at the rounded resolution (within the voxels?)
  data = unique(data[,npts:=.N,by=.(x,y,z)])
  # remove garbage for memory purposes
  gc()
  # if data was a dataframe, give it as a dataframe
  if(check$dfr) data = as.data.frame(data)
  return(data) #- output = coordinates + number of points associated with the coord
}

# downsampling resolution
res = 0.05
# input is a datatable with the coordinates i think
data <- las@data[,c(1:3)]
# convert into rounded coordinates + number of points within the voxel?
plot_vox <- vox(data, res = res)
# input is a datatable with the coordinates i think
remove(data)
# minimum height and maximum height per voxel
z_seq <- seq(min(plot_vox$z), max(plot_vox$z), res)
# raster extent from point cloud
?raster
ground <- raster(nrow = (40 / res),
                   ncol = (40 / res),
                   xmn = -20,
                   xmx = 20,
                   ymn = -20,
                   ymx = 20)
# 0 value to raster
values(ground) <- 0
# raster to point
ground_dt <- as.data.table(rasterToPoints(ground))

empty <- as.data.table(cbind(rep(ground_dt$x, length(z_seq)), 
                               rep(ground_dt$y, length(z_seq))))

data.table::setnames(empty, c("x", "y"))
empty$z <- rep(z_seq, each = nrow(distinct(empty, x, y)))
empty[, npts := 0]

plot_block = dplyr::bind_rows(plot_vox, empty)
plot_block = plot_block[, npts := sum(npts), keyby = .(x, y, z)]

gc()
remove(plot_vox)
gc()

# plot_voxels_full_grid(plot_block, res = 1)

## calculate z slices
z_slices <- seq(min(plot_block$z), max(plot_block$z), res)
#z_slices <- subset(z_slices, z_slices >= 1)

## calculate lai profiles 

lai_profiles <- as.data.frame(matrix(0, length(z_slices), 2))
names(lai_profiles) <- c("height", "pai")

print("calculating z slices... ", quote = F)
pb = txtProgressBar(min = 0, max = length(z_slices), initial = 0, style = 1) 

for(j in 1:length(z_slices)) {
  plot.slice <- plot_block[z %in% z_slices[j],]
  
  ni <- as.numeric(nrow(plot.slice[npts > 0,]))
  nt <- as.numeric(nrow(plot.slice))
  
  N <- ni / nt
  l <- 1.1 * N
  
  lai_profiles$height[j] <- z_slices[j]
  lai_profiles$pai[j] <- l
  
  gc()
  remove(plot.slice)
  gc()
  
  setTxtProgressBar(pb, j)
  
}

output <- data.frame(matrix(0, 1, 2))
names(output) <- c("plot", "pai")

plot.names <- path_file(input)
output$plot <- plot.names[1]
output$pai <- sum(lai_profiles$pai, na.rm = T)

output

print(paste0(plot.names[i], " PAI = ", output$pai))

out.file <- paste0(dir, "/", "combined_trees_hosoi.csv")

write.table(output, out.file, append = T, sep = ",", row.names = F, col.names = F, quote = F)

t2 = Sys.time()
print(paste0(plot.names[i], " complete... time elapsed ", round(t2 - t1, 2)), quote = FALSE)

gc()
remove(plot_vox)
remove(lai_profiles)
remove(output)
gc()
