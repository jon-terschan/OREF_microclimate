######################################################
##### SCRIPT 1: CREATE DIRECTORIES AND CHECK FILES ###
######################################################

######################################################
################### createFolders  ########ca. 0 mins#
######################################################
# Purpose: creates directory substructure inside of root
#          (the R project) if it does not exist
# Settings: NONE
createFolders <- function() {
  # checks if directory exists and creates it if it does not exist
  if (file.exists(here::here("data")) == FALSE ) {
    dir.create(file.path(here::here("data")), showWarnings = FALSE)
  } 
  if (file.exists(here::here("data", "raster")) == FALSE ) {
    dir.create(file.path(here::here("data", "raster")), showWarnings = FALSE)
  } 
  if (file.exists(here::here("data", "raster", "CHM")) == FALSE ) {
    dir.create(file.path(here::here("data", "raster", "CHM")), showWarnings = FALSE)
  } 
  if (file.exists(here::here("data", "raster", "DSM")) == FALSE ) {
    dir.create(file.path(here::here("data", "raster", "DSM")), showWarnings = FALSE)
  } 
  if (file.exists(here::here("data", "raster", "DTM")) == FALSE ) {
    dir.create(file.path(here::here("data", "raster", "DTM")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "raster", "Examiner")) == FALSE ) {
    dir.create(file.path(here::here("data", "raster", "Examiner")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "point_cloud_data")) == FALSE ) {
    dir.create(file.path(here::here("data", "point_cloud_data")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "point_cloud_data", "las_files")) == FALSE ) {
    dir.create(file.path(here::here("data", "point_cloud_data", "las_files")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "point_cloud_data", "las_files", "Examiner")) == FALSE ) {
    dir.create(file.path(here::here("data", "point_cloud_data", "las_files", "Examiner")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "point_cloud_data", "las_files",  "las_local_coord")) == FALSE ) {
    dir.create(file.path(here::here("data", "point_cloud_data", "las_files", "las_local_coord")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "point_cloud_data", "las_files", "las_local_coord", "clipped_classif")) == FALSE ) {
    dir.create(file.path(here::here("data", "point_cloud_data", "las_files", "las_local_coord", "clipped_classif")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "point_cloud_data", "las_files", "las_local_coord", "normalized")) == FALSE ) {
    dir.create(file.path(here::here("data", "point_cloud_data", "las_files", "las_local_coord", "normalized")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "point_cloud_data", "las_files", "Examiner")) == FALSE ) {
    dir.create(file.path(here::here("data", "point_cloud_data", "las_files", "Examiner")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "temperature")) == FALSE ) {
    dir.create(file.path(here::here("data", "temperature")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "output", "whole_stand_pai")) == FALSE ) {
    dir.create(file.path(here::here("data", "output", "whole_stand_pai")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "output", "point_cloud_distances")) == FALSE ) {
    dir.create(file.path(here::here("data", "output", "point_cloud_distances")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "output", "forest_inventory")) == FALSE ) {
    dir.create(file.path(here::here("data", "output", "forest_inventory")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "output", "forest_inventory", "metrics")) == FALSE ) {
    dir.create(file.path(here::here("data", "output", "forest_inventory", "metrics")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "output", "forest_inventory", "normalized")) == FALSE ) {
    dir.create(file.path(here::here("data", "output", "forest_inventory", "normalized")), showWarnings = FALSE)
  }
  if (file.exists(here::here("data", "output", "forest_inventory", "treedetec")) == FALSE ) {
    dir.create(file.path(here::here("data", "output", "forest_inventory", "treedetec")), showWarnings = FALSE)
  }
}

######################################################
################### checkFiles  ########ca. 0 mins#
######################################################
# Purpose: checks if .as files exist in the very first input folder
#          and aborts the pipeline with a warning message if not.
# Settings: path (string): where to look for files 
#           pattern (string): check only for files with this extension
checkFiles <- function(path, pattern) {
  if ((length(list.files(path = path,
                         pattern = pattern)) > 0) == FALSE) 
  {
    stop(paste0("No valid files of format ", pattern, 
                " found in input folder. Terminating script! Please make sure your point cloud files are in the correct folder before running the pipeline."))
  }
}

######################################################
##### SCRIPT 2: CLIPPING/GROUND CLASSIFICATION #######
######################################################

######################################################
################### CLIP_CLASSIF  ########ca. 20 mins#
######################################################
# Purpose: clips point cloud and classifies ground 
#          returns, exports results as new las files
# Settings: buffer.size (numeric): buffer radius in point cloud distance units (m)
#           csf.settings (function): setting for cloth simulation function
#           input filepaths (list of strings): list of file paths for input files
#           output filepaths (string): output directory 
#           filenames (list of strings): list of all file names without extensions
clip_classif <- function(input, filename, buffer.size, buffer.method) {
  las <- readLAS(input, select = "xyzrn")
  if(missing(buffer.size)) stop("No buffer size specified!")
  if(missing(buffer.method)) stop("No buffer method specified!")
  if(buffer.method == "rectangle") {
    clip_las <- clip_rectangle(las, -buffer.size, -buffer.size, buffer.size, buffer.size)
    message("Clipping complete. Classifying...")
  }
  if(buffer.method == "circle") {
    clip_las <- clip_circle(las, 0, 0, buffer.size)
    message("Clipping complete. Classifying...")
  }
  classif_las <- classify_ground(clip_las, csf.settings)
  message("Ground classification complete. Exporting...")
  writeLAS(classif_las,
              paste0(output.filepath,"/", filename,  "_", buffer.size, "m_class",  ".las"))
  message(paste0(filename," completed! Moving to next file..."))
  gc()
}

######################################################
########### SCRIPT 3: HEIGHT NORMALIZATION ###########
######################################################

######################################################
#################### NORMALIZE LAS  ######ca. 30 mins#
######################################################
# Purpose: normalize point cloud height using one of 
#          various methods descriped in the LidR docu.
#          exports results as new las files
# Settings: model.res (numeric): DTM resolution in point cloud distance units (m) 
#           dtm.algorithm (function): algorithm with which the DTM is estimated 
#           method (string): normalization method, see LidR docu (tin, knnidw, hybrid)
#           tin.settings.hybrid (function): algorithm settings for normalization hybrid method
#           tin.settings (function): algorithm settings for normalization tin method
#           knnidw.settings (function): algorithm settings for normalization knnidw method
#           and the usual input/output paths
normalizeLAS <- function(input, filename, method) {
  las <- readLAS(input, select = "xyzrnc")
  dtm_tin <- rasterize_terrain(las, res = model.res, algorithm = dtm.algorithm)
  if(method == "hybrid") {
    message("Normalization complete. Exporting...")
    nlas <- normalize_height(las, tin.settings.hybrid, dtm = dtm_tin)
    writeLAS(nlas,
             paste0(output.filepath, "/", filename,  "_normalized_", method, ".las"))
  }
  if(method == "dtm") {
    nlas <- las - dtm_tin
    message("Normalization complete. Exporting...")
    writeLAS(nlas,
             paste0(output.filepath,"/", filename,  "_normalized_", method, ".las"))
  }
  if(method == "tin") {
    nlas <- normalize_height(las, tin.settings)
    message("Normalization complete. Exporting...")
    writeLAS(nlas,
             paste0(output.filepath, "/", filename,  "_normalized_", method, ".las"))
    print(paste0(" Bing Bong! ", output, " is done!"))
  }
  if(method == "knnidw") {
    nlas <- normalize_height(las, knnidw.settings)
    message("Normalization complete. Exporting...")
    writeLAS(nlas,
             paste0(output.filepath, "/", filename,  "_normalized_", method, ".las"))
  }
  message(paste0(filename, " completed! Moving to next file..."))
}

######################################################
########## SCRIPT 4: DTM/DSM/CHM GENERATION ##########
######################################################

######################################################
#################### getModels########################
######################################################
# Purpose: generates DTMs, DSMs, and CSMs, the function
#          generates DTM and DSM using tin and pitfall
#          and CSM by subtracting DTM from DSM,
#          results are exported as rasters
# Settings: model.res (numeric): model resolution in point cloud distance units, should be same as in normalization
#           dtm.algorithm (function): DTM generation algorithm, see lidR docu
#           dsm.algorithm (function): DSM generation algorithm, see lidR docu
#           and the usual input/output paths
getModels <- function(input, filename, modOutputs) {
  las <- readLAS(input, select = "xyzrnc")
  dtm <- rasterize_terrain(las, res = model.res, algorithm = dtm.algorithm)
  dsm <- rasterize_canopy(las, res = model.res, dsm.algorithm)
  if(grepl("dtm", modOutputs, fixed=TRUE) == TRUE) {
    writeRaster(dtm,
                paste0(dtm.filepath, "/", filename,  "_DTM_", model.res,"m", ".tif"),
                overwrite = T)
  }
  if(grepl("dsm", modOutputs, fixed=TRUE) == TRUE) {
    writeRaster(dsm,
                paste0(dsm.filepath, "/", filename,  "_DSM_", model.res,"m", ".tif"),
                overwrite = T)
  }
  if(grepl("chm", modOutputs, fixed=TRUE) == TRUE) {
    chm <- dsm - dtm
    writeRaster(chm,
                paste0(chm.filepath, "/", filename,  "_CHM_", model.res,"m", ".tif"),
                overwrite = T)
  }
  message(paste0(filename, " completed! Moving to next file..."))
}

######################################################
#################### getModels LOOP  #################
# ca 20 seconds slower than walk2 ####################
######################################################
# DEPRECATED: CLIPPING AND CLOTH SIMULATION FUNCTION ARE 
# A DIFFERENT FUNCTION NOW. THIS ILLUSTRATES THE INTERNAL
# LOGIC OF THE VECTORIZED FUNCTIONS, AS THEY ESSENTIALLY
# SERVE AS LOOP-WRAPPERS
# input.filepath <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/clipped_classif/"
# for(f in 1:length(filenames)) {
#   inputs  = paste0(input.filepath, filenames[f], ".las")
#   outputs = paste0(output.filepath, filenames[f], "_DTM_", dtm.res, "_",
#                    buffer.size, ".tif")
#   las <- readLAS(inputs, select = "xyzrn")
#   clip_las <- clip_rectangle(las, -buffer.size, -buffer.size, buffer.size, buffer.size)
#   #clip_las <- clip_circle(las, 0, 0, buffer.size) # comment out whichever
#   classif_las <- classify_ground(clip_las, csf.settings)
#   dtm_tin <- rasterize_terrain(classif_las, res = dtm.res, algorithm = tin())
#   writeRaster(dtm_tin, outputs, overwrite = T)
#   print(paste0(" Bing Bong! ", filenames[f], " is done!"))
# }

######################################################
#################### exportPlots######################
######################################################
# Purpose: generate rudimentary plots of DTMs, DSMs,
#          and CSMs for visual assessment as .png files
# Settings: input
exportPlots <- function(input){
  names <- path_file(input)
  names <- gsub('.{0,4}$', '', names)
  for (i in seq_along(input)) {
    # Read the TIF file as a raster
    raster_data <- raster(input[i])
    # Convert raster to a data frame
    raster_df <- as.data.frame(raster_data, xy = TRUE)
    # Create a plot using ggplot2
    plot <- ggplot(raster_df, aes(x = x, y = y, fill = Z)) +
      geom_raster() +
      scale_fill_viridis_c(option = "D")  # You can choose a different color scale if you prefer
      theme_classic() +
      labs(title = path_file(input)[i])
    # Save the plot as a PNG or other desired format
    ggsave(filename = paste0(names[i], ".png"), plot = plot, width = 5, height = 5,
           path = path_dir(input))
    # Print a message indicating progress
    cat(path_file(input)[i], "exported.\n")
  }
}
######################################################
##################SCRIPT 5: WHOLE STAND PAI ##########
######################################################

######################################################
##################MODIFY PC ##########################
######################################################
# Purpose: Wraps of a couple operations preparing the
#          point cloud for whole stand PAI estimation
#          such as clipping, thinning, cutting below 
#          a certain height, removing ground points from
#          ground point classification etc.
# Settings: input.cloud (las file): las file to perform the operations on
#           buffer.method (string): rectangle or circle, optional (defaults to rectangle)
#           buffer.size (numeric): radius/sidelength of the buffer applied
#           keepGround (boolean): TRUE/FALSE, remove ground classified points
#           cutoff (numeric): Z value height threshold, points below will be removed
#           thin.voxsize (numeric): voxel size for thinning, samples 1 random point from voxel
modifyPC <- function(input.cloud, buffer.size, buffer.method, keepGround, cutoff, thin.voxsize, calcDistances) {
  if(extent(input.cloud)[c(2)] > buffer.size){
    message("Point cloud extent seems to be larger than buffer size. Clipping.")
      if(missing(buffer.method)) {
      warning("No buffer method specified. Default to buffer.method = rectangle.")
        las <- clip_rectangle(input.cloud, -buffer.size, -buffer.size, buffer.size, buffer.size)
      message("Rectangle clip complete.")
      }
      if(buffer.method == "rectangle") {
        las <- clip_rectangle(input.cloud, -buffer.size, -buffer.size, buffer.size, buffer.size)
      message("Rectangle clip complete.")
      }
      if(buffer.method == "circle") {
        las <- clip_circle(input.cloud, 0, 0, buffer.size)
      message("Circle clip complete.")
      }
  }
  if(missing(buffer.size)){
    message("No buffer specified. Proceeding with unaltered input point cloud extent.")
  }
  if(missing(keepGround) == FALSE){
    if(keepGround == FALSE){
      message("Removing ground points from earlier classification.")
      las <-las[las@data$Classification == 1]
    }
    if(keepGround == TRUE){
      message("Keeping ground points from earlier classification.")
    }
  }
  if(missing(thin.voxsize) == FALSE){
    message("Thinning point cloud according to given voxel size. ")
    las <- tlsSample(las, smp.voxelize(thin.voxsize)) 
  }
  if(missing(cutoff) == FALSE){
    message("Removing points below given Z value.")
    las <-las[las@data$Z >= cutoff]
  }
  return(las)
}
######################################################
##################calcDistances ######################
######################################################
# Purpose: calculate distances for each point to k nearest neighbor points
#          and summarizes the results into a summary data frame.
#          gives out maximum, min, med and mean distances as well
#          as 1%, 5% and 25% quantiles ( DOES NOT CONSIDER DISTANCES OF 0).
#          column prop in the resulting df gives the percentual proportion of points 
#          with distances greater than 0.
#          increasing k and running on a larger point cloud will 
#          create the runtime by a large margin
# Settings: input (las cloud): input point cloud
#           k (numeric): amount of k neighbors to consider
calcDistances <- function(input, k) {
  if(missing(k)){
    message("Amount k of nearest neighbors unspecified, default to k = 3")
    k = 3
  }
  lastab <- input@data[, 1:3]
  kdt <- KDTree$new(lastab)
  res <- kdt$query(lastab, k = k)
  nearestneighbor <- data.frame(mean = mean(res$nn.dists[res$nn.dists > 0]),
                                med = median(res$nn.dists[res$nn.dists > 0]),
                                max = max(res$nn.dists[res$nn.dists > 0]),
                                min = min(res$nn.dists[res$nn.dists > 0]),
                                q1 = quantile(res$nn.dists[res$nn.dists > 0], probs = .01),
                                q5 = quantile(res$nn.dists[res$nn.dists > 0], probs = .05),
                                q25 = quantile(res$nn.dists[res$nn.dists > 0], probs = .25),
                                prop = (length(res$nn.dists[res$nn.dists > 0]) / length(res$nn.dists)) * 100
  )
}

######################################################
#################### vox adapted from Flynn et al#####   
######################################################
# Purpose: convert las file to voxR data.table 
# Settings: data (input point cloud),
#           res (numeric): downsampling resolution (voxel size), see flynn paper 
vox <- function(data, res, message){
  #- declare variables to pass CRAN check as suggested by data.table maintainers
  x=y=z=npts=.N=.=':='=NULL
  #- check for data consistency and convert to data.table
  check=VoxR::ck_conv_dat(data, message=message)
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

######################################################
#################### estimate PAI from Flynn et al#####   
######################################################
# Purpose: estimate PAI per height slice and on stand level based on voxel slices
#          notice that the function wraps the modifyPC function and you may 
#          need to comment or uncomment certain parts of it if you want to 
#          modify the point cloud
# Settings: input: input point cloud  
#           filename: name of input point cloud
#           res: see vox function
#           buffer.size: see modifyPC function
#           correction.factor: a correction factor based on zenith angle, see referenced papers
#           calc.nn.k: optional k value to calculate nearest neighbor distances (see calcDistance function)
estimatePAI <- function(input, filename, res, buffer.size, correction.factor, calc.nn.k){
  # system time marker
  t1 = Sys.time()
  # read input point cloud
  las <- readLAS(input) 
  # WRAPPER FOR A DIFFERENT CUSTOM FUNCTION, SEE MODIFYPC
  las <- modifyPC(las, #input point cloud
                  buffer.size = buffer.size, #applies buffer for further reduction
                  buffer.method = buffer.method,
                  cutoff = cutoff, #removes Z values under this threshold
                  keepGround = keepGround #removes all points classified as ground
                  #thin.voxsize = thin.voxsize  #thins PC by sampling random point from vox of given size
  ) 
  # Initiate k nearest neighbor search with nested function if optional argument is provided
  # WRAPPER FOR A DIFFERENT CUSTOM FUNCTION, SEE CALCDISTANCES
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
  out.file1 <- paste0(output.filepath, "/", filename, "_pai_slice.csv")
  write.table(lai_profiles, out.file1, sep = ",", row.names = F, col.names = T, quote = F)
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
  remove(output)
  gc() 
}