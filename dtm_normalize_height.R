######################################################
################ DEPENDENCIES ########################
######################################################
library(lidR) #to handle Lidar data
library(RCSF) # for CSF based ground classif
library(terra) # for rasterization operations
library(dplyr)# for walk2
library(purrr)
library(fs) # for dir_ls, i think superior to list files

######################################################
################ FUNCTION SETTINGS ###################
######################################################
input.filepaths <- dir_ls("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/clipped_classif", glob = '*.las')
filenames <- path_file(input.filepaths)
filenames <- gsub('.{0,14}$', '', filenames)
output.filepath <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/normalized/"
dtm.res = 1 

######################################################
#################### NORMALIZE LAS  ######ca. 30 mins#
######################################################
normalizeLAS <- function(input, output, method) {
  las <- readLAS(input, select = "xyzrnc")
  dtm_tin <- rasterize_terrain(las, res = dtm.res, algorithm = tin())
  if(method == "hybrid") {
    message("Normalization complete. Exporting...")
    nlas <- normalize_height(las, tin(), dtm = dtm_tin)
    writeLAS(nlas, 
           paste0(output.filepath, output,  "_normalized_", method, ".las"))
    message("Export complete.")
  }
  if(method == "dtm") {
    nlas <- las - dtm_tin
    message("Normalization complete. Exporting...")
    writeLAS(nlas, 
             paste0(output.filepath, output,  "_normalized_", method, ".las"))
    message("Export complete.")
  }
  if(method == "tin") {
    nlas <- normalize_height(las, tin())
    message("Normalization complete. Exporting...")
    writeLAS(nlas, 
             paste0(output.filepath, output,  "_normalized_", method, ".las"))
    print(paste0(" Bing Bong! ", output, " is done!"))
    message("Export complete.")
  }
  if(method == "knnidw") {
    nlas <- normalize_height(las, knnidw())
    message("Normalization complete. Exporting...")
    writeLAS(nlas, 
             paste0(output.filepath, output,  "_normalized_", method, ".las"))
    message("Export complete.")
  }
}

######################################################
#################### EXECUTE FUNCTION ####ca. 30 mins#
######################################################
# Method must be defined as string. 
# Valid methods: dtm, tin, knnidw, hybrid 
# (see https://r-lidar.github.io/lidRbook/norm.html")
# note that execution time ramps up if there is no DTM involved
# hybrid and DTM take roughly 30 mins, the others should take
# MUCH longer, like maybe half a day?
walk2(input.filepaths, filenames, method = "hybrid", normalizeLAS)

######################################################
### FUNCTION SETTING FOR SINGLE FILES ####ca 2 mins###
######################################################
# simply change input.filepaths to a single file path
# and output to examiner folder

# input.filepaths <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/clipped_classif/OREF_6_20m_class.las"
# filenames <- path_file(input.filepaths)
# filenames <- gsub('.{0,14}$', '', filenames)
# output.filepath <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/normalized/Examiner/"
# dtm.res = 1 