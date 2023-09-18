######################################################
################ FUNCTION SETTINGS ###################
######################################################
dir_path <- here::here("data","point_cloud_data","las_files","las_local_coord", "normalized", "/")
output_path <- here::here("data", "output", "forest_inventory","treedetec", "/")
filename <- paste0(dir_path, "OREF_1245_normalized_hybrid.las")
filename = path_file(filename)
filenames <- gsub('.{0,22}$', '', filename)
normal_path <- here::here("data","output", "forest_inventory","normalized", "/")
# las <- readLAS(paste0(dir_path, filename), select = "xyzrnc")
# buffer.size = 10
# clip_las <- clip_circle(las, 0, 0, buffer.size)
# writeLAS(clip_las,
#         paste0(dir_path, "test.las"))
# plot(clip_las)
# dir_path <- here::here("data","point_cloud_data","las_files","las_local_coord", "normalized", "/")
# output_path <- here::here("data", "output", "forest_inventory","treedetec", "/")
# filename <- paste0(dir_path, "test.las")
# filename = path_file(filename)
# filenames <- gsub('.{0,4}$', '', filename)
# normal_path <- here::here("data","output", "forest_inventory","normalized", "/")
######################################################
################ FUNCTION SETTINGS #####BATCH#########
######################################################
buffer.size = 15

######################################################
#################### FORTLS ##########################
######################################################
?normalize
pcd <- normalize(las = filename, 
                 scan.approach = "multi", 
                 normalized = TRUE,
                 x.center = 0,
                 y.center = 0,
                 #x.side = buffer.size,
                 #y.side = buffer.size,
                 min.height = 0,
                 dir.data = dir_path,
                 max.dist = 7,
                 res.dtm = 0.5,
                 id = filenames,
                 save.result = T,
                 dir.result = normal_path)
##tree detection, takes a long time
tree.tls <- tree.detection.multi.scan(pcd[pcd$prob.selec == 1, ],
                                      dir.result = output_path)
ds <- distance.sampling(tree.tls)
# test <- tree.tls[,c(3:15)]
# estimate of trees per unit 
estimation.plot.size(tree.tls,
                     plot.parameters = data.frame(radius.max = 12,
                                                  k.max = 50,
                                                  BAF.max = 4),
                     dbh.min = 4,
                     average = T, all.plot.designs = FALSE)
# forest inventory metrics calculation (around 400s)
?metrics.variables
met.var.TLS <- metrics.variables(tree.tls = tree.tls,
                                 #tree.ds = ds,
                                 plot.design = "fixed.area",
                                 plot.parameters = data.frame(radius = 7),
                                 scan.approach = "multi",
                                 dir.data = here::here("data","output","forest_inventory","normalized", "/"), 
                                 dir.result = here::here("data","output","forest_inventory","metrics", "/"))