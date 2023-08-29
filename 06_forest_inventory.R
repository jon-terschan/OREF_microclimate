dir_path <- here::here("data","point_cloud_data","las_files","las_local_coord", "normalized", "/")
output_path <- here::here("data","forest_inventory","treedetec", "/")
filename <- paste0(dir_path, "OREF_1255_normalized_hybrid.las")
filename = path_file(filename)
las <- readLAS(paste0(dir_path, filename))

######################################################
#################### FORTLS ##########################
######################################################
?FORTLS
buffer.size = 9  #buffer size in m
normal_path <- here::here("data","forest_inventory","normalized", "/")
pcd <- normalize(las = filename, 
                 scan.approach = "multi", 
                 normalized = TRUE,
                 dir.data = dir_path,
                 # max.dist = 8,
                 res.dtm = 1,
                 save.result = TRUE,
                 dir.result = normal_path)
##tree detection, takes a long time
tree.tls <- tree.detection.multi.scan(pcd[pcd$prob.selec == 1, ],
                                      dir.result = output_path)
ds <- distance.sampling(tree.tls)
# test <- tree.tls[,c(3:15)]
# estimate of trees per unit 
?estimation.plot.size
estimation.plot.size(tree.tls,
                     plot.parameters = data.frame(radius.max = 25,
                                                  k.max = 50,
                                                  BAF.max = 4),
                     dbh.min = 4,
                     average = FALSE, all.plot.designs = FALSE)
# forest inventory metrics calculation (around 400s)
?metrics.variables
met.var.TLS <- metrics.variables(tree.tls = tree.tls,
                                 tree.ds = ds,
                                 # plot.parameters = data.frame(radius = 10, 
                                 #                              k = 2, 
                                 #                              BAF = 4),
                                 scan.approach = "multi",
                                 dir.data = here::here("data","forest_inventory","normalized", "/"), 
                                 dir.result = here::here("data","forest_inventory","metrics", "/"))

# data("Rioja.data")
# tree.tls <- Rioja.data$tree.tls
# tree.tls <- tree.tls[tree.tls$id == "1", ]
# 
# # Download example of TXT file corresponding to plot 1 from Rioja data set
# download.file(url = "https://www.dropbox.com/s/w4fgcyezr2olj9m/Rioja_1.txt?dl=1",
#               destfile = file.path(dir.data, "1.txt"), mode = "wb")

######################################################
#################### TREELS ##########################
######################################################
dir_path <- here::here("data","point_cloud_data","las_files","las_local_coord", "clipped_classif", "/")
output_path <- here::here("data","forest_inventory","treedetec", "/")
filename <- paste0(dir_path, "OREF_1255_20m_class.las")
filename = path_file(filename)

# read in and normalize
tls <- readTLS(paste0(dir_path, filename)) %>% tlsNormalize()
x = plot(tls)
# thin point cloud by deleting random entries in small voxels
thin = tlsSample(tls, smp.voxelize(0.02))
# tree identification, this important and needs to be tuned so all trees are
# identified
map = treeMap(thin, map.hough(min_density = 0.1, h_step = 1, max_h = 5), 0)
add_treeMap(x, map, color='yellow', size=2)
# this assigns TreeIDs to the point cloud based on tree region proximity
# trp.voronoi needs much much longer to compute than trp.crop.
tls = treePoints(tls, map, trp.crop())
# stem points classification, takes some time 
tls = stemPoints(tls, stm.hough())

# add two plot to examine  
add_treePoints(x, tls, size=4)
add_treeIDs(x, tls, cex = 2, col='yellow')
add_stemPoints(x, tls, color='red', size=8)

# calculate stem radius (DBH) and other metrics, the calculation height and
# algorithm can be adapted, together with some other details of the metric
dmt <- shapeFit(shape='circle', algorithm = 'ransac')
inv = tlsInventory(tls, d_method = dmt)
# add inventory to plot 
add_tlsInventory(x, inv)

# extract stem measures
seg = stemSegmentation(tls, sgt.ransac.circle(n = 20))
add_stemSegments(x, seg, color='white', fast=T)

# plot everything once
tlsPlot(tls, map, inv, seg, fast=T)
# check out a single try by ID 
unique(map@data$TreeID)
tlsPlot(tls, inv, seg, tree_id = 59)
