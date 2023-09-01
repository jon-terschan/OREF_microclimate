######################################################
################### createFolders  ########ca. 0 mins#
######################################################
# Purpose: create folder structure inside of root
#          (the R project) if not already present
# Settings: NONE
createFolders <- function() {
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
  if (file.exists(here::here("data", "point_cloud_data", "las_files", "Examiner")) == FALSE ) {
    dir.create(file.path(here::here("data", "point_cloud_data", "las_files", "Examiner")), showWarnings = FALSE)
  }
}

######################################################
################### checkFiles  ########ca. 0 mins#
######################################################
# Purpose: check if las files exist in the first input folder
#          and pass a warning message if not.
# Settings: path in which it checks and filename pattern.
checkFiles <- function(path, pattern) {
  if ((length(list.files(path = path,
                         pattern = pattern)) > 0) == FALSE) 
  {
    stop(paste0("No valid files of format ", pattern, 
                " found in input folder. Terminating script! Please make sure your point cloud files are in the correct folder before running the pipeline."))
  }
}

######################################################
################### CLIP_CLASSIF  ########ca. 20 mins#
######################################################
# Purpose: clips point cloud and classifies ground 
#          returns, exports results as new las files
# Settings: buffer.size, csf.settings, input filepaths,
#           output filepaths, filenames
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
#################### NORMALIZE LAS  ######ca. 30 mins#
######################################################
# Purpose: normalize point cloud height using one of 
#          various methods descriped in the LidR docu.
#          exports results as new las files
# Settings: model.res, dtm.algorithm, tin.settings.hybrid,
#           tin.settings, knnidw.settings, method,
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
#################### getModels########################
######################################################
# Purpose: generate DTMs, DSMs, and CSMs, the function
#          generates DTM and DSM using tin and pitfall
#          and CSM by subtracting DTM from DSM,
#          results are exported as rasters
# Settings: model.res, dtm.algorithm, dsm.algorithm,
#          and the usual input/output paths
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
#          and CSMs for visual assessment as pngs
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
# Purpose: Bundle of a couple operations preparing the
#          point cloud for whole stand PAI estimation
#          such as clipping, thinning, cutting below 
#          a certain height, removing ground points from
#          ground point classification etc.
# Settings: input.cloud
            # buffer.size = to reduce the cloud even further if desired
            # keepGround = TRUE/FALSE, removes ground classified points from CSF
            # cutoff = Z value threshold under which points will be removed
            # thin.voxsize = voxel size for thinning, just samples 1 random point from voxel
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
    las <- clip_rectangle(input.cloud, -buffer.size, -buffer.size, buffer.size, buffer.size)
  }
  if(missing(thin.voxsize) == FALSE){
    message("Thinning point cloud according to given voxel size. ")
    las <- tlsSample(las, smp.voxelize(thin.voxsize)) 
  }
  if(keepGround == FALSE){
    message("Removing ground points from earlier classification.")
    las <-las[las@data$Classification == 1]
  }
  if(missing(cutoff) == FALSE){
    message("Removing points below given Z value.")
    las <-las[las@data$Z >= cutoff]
  }
}

######################################################
##################calcDistances ######################
######################################################
# Purpose: calculate distances for each point to its k nearest neighbors
#          and summarizes the results into a summary data frame.
#          gives out maximum, min, med and mean distances as well
#          as 1%, 5% and 25% quantiles (EXCLUDING DISTANCES OF 0).
#          column prop gives the percentage of points with distances > 0 
#          to their k nearest neighbors of all considered distances. 
#          increasing k and running on a larger point cloud will 
#          create the runtime by a large margin
# Settings: input (las cloud), k (numeric)
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
#################### vox adapted from Flymm et al#####   
######################################################
# Purpose: convert las file to voxR data.table 
# Settings: data, res 
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