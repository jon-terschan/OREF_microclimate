######################################################
######################## FILEPATHS ###################
######################################################
# list with las files
input <- dir_ls(here::here("data","point_cloud_data","las_files","las_local_coord", "normalized"), glob = '*.las')
# folder path with las files
dir_path <- here::here("data","point_cloud_data","las_files","las_local_coord", "normalized", "/")
# output folder for point cloud dataframes
normal_path <- here::here("data","output", "forest_inventory","normalized", "/")

######################################################
################ FUNCTION SETTINGS #####BATCH#########
######################################################
buffer.size = 10 # circular buffer based on max. dist threshold to plot center (is applied before tree detection)
plot.radius = 7 # radius for which dendrometrics will be estimated 
dsSampling = FALSE # apply distance sampling to correct occlusion, only works if AOI contains trees that occlude each other
res = 0.5 # res of the DTM in the normalize function, might be used in resampling idk
cutoff = 0  # ground threshold over which points will not be considered for the whole operation

######################################################
#################### FORTLS BATCH LOOP ###############
######################################################
# FORTLS has a solid function documentation and I do recommend checking it out. 
# is just an implementation of the recommended workflow. check out readme and:
# ?FORTLS
# ?estimation.plot.size
# ?tree.detection.multi.scan
# ?distance.sampling
# ?metrics.variables
for (i in 1:length(input)) {
pcd <- normalize(las = path_file(input[i]), 
                 scan.approach = "multi", 
                 normalized = TRUE,
                 x.center = 0,
                 y.center = 0,
               # x.side = import.buffer,
               # y.side = import.buffer,
                 min.height = cutoff,
                 dir.data = dir_path,
                 max.dist = buffer.size,
                 res.dtm = res,
                 id = gsub('.{0,22}$', '', path_file(input[i])),
                 save.result = TRUE,
                 dir.result = normal_path
                )
message(paste0(path_file(input[i]), " converted to dataframe."))
dir.create(file.path(here::here("data", "output", "forest_inventory", "treedetec", gsub('.{0,22}$', '', path_file(input[i])))), showWarnings = FALSE)
treedetec_path <- file.path(here::here("data", "output", "forest_inventory", "treedetec", gsub('.{0,22}$', '', path_file(input[i]))))

tree.tls <- tree.detection.multi.scan(pcd[pcd$prob.selec == 1, ],
                                      dir.result = treedetec_path)
message(paste0(path_file(input[i]), " tree detection finished."))

dir.create(file.path(here::here("data","output","forest_inventory","metrics", gsub('.{0,22}$', '', path_file(input[i])))), showWarnings = FALSE)
metrics_path <- file.path(here::here("data","output","forest_inventory","metrics", gsub('.{0,22}$', '', path_file(input[i]))))

if (dsSampling == TRUE) {
  message(paste0("Calculating dendrometrics with distance sampling."))
  ds <- distance.sampling(tree.tls)
  met.var.TLS <- metrics.variables(tree.tls = tree.tls,
                                   tree.ds = ds,
                                   plot.design = "fixed.area",
                                   plot.parameters = data.frame(radius = plot.radius),
                                   scan.approach = "multi",
                                   dir.data = normal_path, 
                                   dir.result = metrics_path)
} else {
  message(paste0("Calculating dendrometrics without distance sampling."))
  met.var.TLS <- metrics.variables(tree.tls = tree.tls,
                                   plot.design = "fixed.area",
                                   plot.parameters = data.frame(radius = plot.radius),
                                   scan.approach = "multi",
                                   dir.data = normal_path, 
                                   dir.result = metrics_path) }
gc()
message(paste0(path_file(input[i]), " finished. Moving to next file."))
}