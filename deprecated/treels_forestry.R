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

