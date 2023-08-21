######################################################
################ DEPENDENCIES ########################
######################################################
library(lidR) # to handle Lidar data
library(RCSF) # for CSF based ground classif
library(terra) # for rasterization operations
library(raster) # to EXPORT DTM
library(dplyr) # for walk2
library(purrr) # for walk2
library(fs) # for walk2
library(here) # for operating system agnostic working directory

######################################################
################ SOURCE SCRIPTS ######################
######################################################
# SOURCE THESE ONE AT A TIME
source( here::here("functions.R") ) # 0 seconds
source( here::here("01_create_dirs.R") ) # 0 seconds
source( here::here("02_clip_classif.R") ) # 20 mins

# YOU CAN SOURCE THESE TOGETHER, THEY WILL RUN IN PARALLEL
source( here::here("03_dtm_normalize_height.R") ) # 40 mins
source( here::here("04_dtm_chm_dsm_generation.R") ) # 30 mins

# SEE README.MD FOR FAQ