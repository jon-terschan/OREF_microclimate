dir_path <- here::here("data","point_cloud_data","las_files","las_local_coord", "normalized", "/")
output_path <- here::here("data","forest_inventory","treedetec", "/")
filename <- paste0(dir_path, "OREF_1255_normalized_hybrid.las")
filename = path_file(input)
las <- readLAS(paste0(dir_path, filename) , select = "xyzrn")
plot(las)

normal_path <- here::here("data","forest_inventory","normalized", "/")
pcd <- normalize(las = filename, 
                 scan.approach = "multi", 
                 normalized = TRUE,
                 dir.data = dir_path,
                 max.dist = 8,
                 res.dtm = 1,
                 save.result = TRUE,
                 dir.result = normal_path)

tree.tls <- tree.detection.multi.scan(pcd[pcd$prob.selec == 1, ],
                                      dir.result = output_path)
# ds <- distance.sampling(test)
# test <- tree.tls[,c(3:15)]
estimation.plot.size(tree.tls,
                     plot.parameters = data.frame(radius.max = 25,
                                                  k.max = 50,
                                                  BAF.max = 4),
                     dbh.min = 4,
                     average = FALSE, all.plot.designs = FALSE)



met.var.TLS <- metrics.variables(tree.tls = tree.tls,
                                 # tree.ds = ds,
                                 # plot.parameters = data.frame(radius = 10, 
                                 #                              k = 2, 
                                 #                              BAF = 4),
                                 scan.approach = "multi",
                                 dir.data = here::here("data","forest_inventory","normalized", "/"), 
                                 dir.result = here::here("data","forest_inventory","metrics", "/"))

?FORTLS


# data("Rioja.data")
# tree.tls <- Rioja.data$tree.tls
# tree.tls <- tree.tls[tree.tls$id == "1", ]
# 
# # Download example of TXT file corresponding to plot 1 from Rioja data set
# 
# download.file(url = "https://www.dropbox.com/s/w4fgcyezr2olj9m/Rioja_1.txt?dl=1",
#               destfile = file.path(dir.data, "1.txt"), mode = "wb")