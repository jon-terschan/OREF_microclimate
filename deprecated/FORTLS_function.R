######################################################
################ FUNCTION SETTINGS ###################
######################################################
dir_path <- here::here("data","point_cloud_data","las_files","las_local_coord", "normalized", "/")
treedetec_path <- here::here("data", "output", "forest_inventory","treedetec", "/")
forestry_path <- here::here("data","output","forest_inventory","metrics", "/")
filename <- paste0(dir_path, "OREF_1245_normalized_hybrid.las")
filename = path_file(filename)
filenames <- gsub('.{0,22}$', '', filename)
# optional: only necessary to save normalized txt files if desired
# normal_path <- here::here("data","output", "forest_inventory","normalized", "/")

######################################################
################ FUNCTION SETTINGS #####BATCH#########
######################################################
import.buffer = 15
buffer.size = 7
dsSampling = FALSE
res = 0.5
######################################################
#################### FORTLS ##########################
######################################################
# FORTLS has a solid function documentation and I do recommend checking it out, the function
# is just an implementation of the recommended workflow 
# ?FORTLS
# ?estimation.plot.size
# ?tree.detection.multi.scan
# ?distance.sampling
# ?metrics.variables

dendroFixedarea <- function(filenames, 
                            bufer.size, 
                            dir_path, 
                            treedetec_path,
                            forestry_path,
                            dsSampling){
pcd <- normalize(las = filenames, 
                 scan.approach = "multi", 
                 normalized = TRUE,
                 x.center = 0,
                 y.center = 0,
                 x.side = import.buffer,
                 y.side = import.buffer,
                 min.height = 0,
                 dir.data = dir_path,
                 #max.dist = 10,
                 res.dtm = res,
                 id = filenames,
                 dir.result = normal_path)
tree.tls <- tree.detection.multi.scan(pcd[pcd$prob.selec == 1, ],
                                      dir.result = treedetec_path)
if (dsSampling == TRUE) {
  ds <- distance.sampling(tree.tls)
  met.var.TLS <- metrics.variables(tree.tls = tree.tls,
                                   tree.ds = ds,
                                   plot.design = "fixed.area",
                                   plot.parameters = data.frame(radius = buffer.size),
                                   scan.approach = "multi",
                                   #dir.data = here::here("data","output","forest_inventory","normalized", "/"), 
                                   dir.result = forestry_path)
}
met.var.TLS <- metrics.variables(tree.tls = tree.tls,
                                 plot.design = "fixed.area",
                                 plot.parameters = data.frame(radius = buffer.size),
                                 scan.approach = "multi",
                                 #dir.data = here::here("data","output","forest_inventory","normalized", "/"), 
                                 dir.result = forestry_path)
}
######################################################
#################### EXECUTE FUNCTION ####ca. 30 mins#
######################################################