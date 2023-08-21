######################################################
#################### create Folder structure #########
######################################################
createFolders()
######################################################
###Passes a warning if input files are missing########
######################################################
checkFiles(path = here::here("data", "point_cloud_data", "las_files",  "las_local_coord"),
           pattern = "\\las$")
