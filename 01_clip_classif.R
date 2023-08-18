######################################################
################ DEPENDENCIES ########################
######################################################
library(lidR) #to handle Lidar data
library(RCSF) # for CSF based ground classif
library(terra) # for rasterization operations
library(raster)# to EXPORT DTM
library(dplyr)# for walk2
library(purrr)
library(fs) # for dir_ls, i think superior to list files

######################################################
################ FUNCTION SETTINGS ###################
######################################################
input.filepaths <- dir_ls("D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/", glob = '*.las')
filenames <- path_file(input.filepaths)
filenames <- gsub('.{0,10}$', '', filenames) # remove file ending from file names
output.filepath <- "D:/OREF_tls_microclimate_project/point_cloud_data/las_files/las_local_coord/clipped_classif/"

######################################################
################ FUNCTION SETTINGS #####BATCH#########
######################################################
csf.settings <- csf(sloop_smooth = TRUE, #cloth simulation parameters,
                    class_threshold = 0.1, #see ?csf for help
                    cloth_resolution = 0.3, 
                    rigidness = 1, 
                    time_step = 0.65)
buffer.size = 20  #buffer size in m

######################################################
#################### PURRR WALK2  ########ca. 20 mins#
######################################################
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

walk2(input.filepaths, filenames, clip_classif)