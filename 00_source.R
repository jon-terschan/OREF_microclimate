######################################################
#############EDYSAN TLS PROCESSING PIPELINE ##########
######################################################
# CHECK README.MD FOR FAQ AND OVERVIEW OVER THE PIPELINE
# Scripts can be executed independently if dependencies and custom functions 
# are loaded in.

######################################################
################ DEPENDENCIES ########################
######################################################
library(lidR) # to handle Lidar data
library(RCSF) # for CSF based ground classif
library(terra) # for rasterization operations
library(raster) # to EXPORT DTM
library(dplyr) # for walk2
library(purrr) # for walk2
library(fs) # for directory management functions
library(here) # for operating system agnostic working directory
library(ggplot2) # for plotting models
# library(remotes)
# remotes::install_github("Molina-Valero/FORTLS", dependencies = TRUE)
library(FORTLS) # for forest inventory  
# remotes::install_github('tiagodc/TreeLS')
library(TreeLS)# for forest inventory  
library(VoxR) # for voxelization
library(less) # for KDTree nearest neighbor implementation

######################################################
################ SOURCE SCRIPTS ######################
######################################################
# SOURCE THESE SEQUENTIALLY
source( here::here("functions.R") ) # 0 seconds
source( here::here("01_create_dirs.R") ) # 0 seconds
source( here::here("02_clip_classif.R") ) # 20 mins

# YOU CAN SOURCE THESE TOGETHER, THEY WILL RUN IN PARALLEL
source( here::here("03_dtm_normalize_height.R") ) # 40 mins
source( here::here("04_dtm_chm_dsm_generation.R") ) # 30 mins

# HAVE NOT TESTED WHETHER THIS CAN RUN IN PARALLEL YES
source( here::here("05_whole_stand_pai.R") ) # TBD
source( here::here("06_dendrometrics_FORTLS.R") ) # TBD
