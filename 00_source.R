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
library(here) # for system agnostic working directory

######################################################
################ SOURCE SCRIPTS ######################
######################################################
source( here::here("functions.R") ) # 0 seconds
source( here::here("01_clip_classif.R") ) # 20 mins
source( here::here("02_dtm_normalize_height.R") ) # 40 mins
source( here::here("03_dtm_chm_dsm_generation.R") ) # 30 mins