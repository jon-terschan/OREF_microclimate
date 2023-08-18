######################################################
################### CLIP_CLASSIF  ########ca. 20 mins#
######################################################
# Purpose: clips point cloud and classifies ground 
#          returns, exports results as new las files
# Settings: buffer.size, csf.settings, input filepaths,
#           output filepaths, filenames
clip_classif <- function(input, filename) {
  las <- readLAS(input, select = "xyzrn")
  clip_las <- clip_rectangle(las, -buffer.size, -buffer.size, buffer.size, buffer.size)
  #clip_las <- clip_circle(las, 0, 0, buffer.size) # comment out whichever
  message("Clipping complete. Classifying...")
  classif_las <- classify_ground(clip_las, csf.settings)
  message("Ground classification complete. Exporting...")
  writeLAS(classif_las,
              paste0(output.filepath, filename,  "_", buffer.size, "m_class",  ".las"))
  message("Export complete.")
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
             paste0(output.filepath, filename,  "_normalized_", method, ".las"))
  }
  if(method == "dtm") {
    nlas <- las - dtm_tin
    message("Normalization complete. Exporting...")
    writeLAS(nlas,
             paste0(output.filepath, filename,  "_normalized_", method, ".las"))
  }
  if(method == "tin") {
    nlas <- normalize_height(las, tin.settings)
    message("Normalization complete. Exporting...")
    writeLAS(nlas,
             paste0(output.filepath, filename,  "_normalized_", method, ".las"))
    print(paste0(" Bing Bong! ", output, " is done!"))
  }
  if(method == "knnidw") {
    nlas <- normalize_height(las, knnidw.settings)
    message("Normalization complete. Exporting...")
    writeLAS(nlas,
             paste0(output.filepath, filename,  "_normalized_", method, ".las"))
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
                paste0(dtm.filepath, filename,  "_DTM_", model.res,"m", ".tif"),
                overwrite = T)
  }
  if(grepl("dsm", modOutputs, fixed=TRUE) == TRUE) {
    writeRaster(dsm,
                paste0(dsm.filepath, filename,  "_DSM_", model.res,"m", ".tif"),
                overwrite = T)
  }
  if(grepl("chm", modOutputs, fixed=TRUE) == TRUE) {
    chm <- dsm - dtm
    writeRaster(chm,
                paste0(chm.filepath, filename,  "_CHM_", model.res,"m", ".tif"),
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