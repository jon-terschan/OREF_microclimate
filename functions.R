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