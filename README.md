# EDYSAN TLS PROCESSING PIPELINE FOR R
This pipeline was created as part of an ongoing microclimate investigation by the EDYSAN lab for the purpose of batch-processing registering multi-scan point clouds stored in .LAS format. Thus, the pipeline can be split into steps that are generally applicable to TLS (pre-)processing (clipping, normalization,...) and those that are somewhat exclusive to said microclimate project. These processing steps are included: 
- Creating a directory (sub)structure.
- Clipping the point clouds using a circular or rectangular buffer.
- Classifying ground points using a Cloth Simulation Function (CSF).
- Creating Digital Terrain Models (DTM), Canopy Height Models (CHM), and Digital Surface Models (DSM) based on the point clouds.
- Normalizing point cloud height based on the DTM, spatial interpolation, or a hybrid method.
- Estimating whole stand PAI following the approach laid out in [Flynn et al. 2023](https://bg.copernicus.org/articles/20/2769/2023/).
- Estimating stand-level dendrometrical measurements (basal area, DBH, stand volume, etc.) using [FORTLS](https://www.sciencedirect.com/science/article/pii/S1364815222000433).

The pipeline is structured into scripts, each of which entails one or multiple different processing steps. Scripts can be sourced seperately or consecutively using the ```00_source.R``` script. Package dependencies are defined within ```00_source.R``` script. Ensure that ```functions.R``` was sourced beforehand before attempting to source individual scripts, since it contains all custom functions utilized in individual scripts. Scripts closely resemble each other: They usually contain variables defining (custom) function arguments (i.e., function settings and input paths), and code to execute the custom function for multiple files. If you want to change what a script does, you must do to so inside the corresponding custom function within the ```functions.R```script. Said script also entails some simple documentation on each custom function. 
# Folder Structure
Filepath references within the code assume the following directory structure:
```
FILEPATH/OREF_microclimate
├── 00_source.R                            
├── 01_create_dirs.R
├── 02_clip_classif.R
├── 03_dtm_normalize_height.R
├── 04_dtm_chm_dsm_generation.R
├── 05_whole_stand_pai.R
├── 06_dendrometrics_FORTLS
├── functions.R
├── data
│      └── point_cloud_data
│      │          └── las_files
│      │                     ├── Examiner
│      │                    (├── las_georef)
│      │                     └── las_local_coord
│      │                               ├── ...las
│      │                               ├── clipped_classif
│      │                                            └── ...las
│      │                               └── normalized
│      │                                            └── ...las
│      ├── raster
│      │       ├── CHM 
│      │       ├── DSM
│      │       ├── DTM
│      │       └── Examiner
│      │
│      ├── temperature
│      │
│      └── output
│              ├── forest_inventory
│              │             ├──metrics
│              │             ├──normalized
│              │             └──treedetec
│              ├── point_cloud_distances
│              └── whole_stand_pai
├── deprecated
│            └── ...
├── OREF_microclimate.Rproj
└── README.md
```
You can ensure your working directory adhers to this structure by cloning (or downloading) this repository, opening the R project file (```OREF_microclimate.Rproj```) and sourcing the ```01_create_dirs.R``` script. Opening the project file first should set the working directory at the project file's location. Check out the corresponding [FAQ section](https://github.com/jon-terschan/OREF_microclimate/blob/main/README.md#i-want-to-adapt-the-pipeline-to-use-for-my-own-files-what-do-i-have-to-look-after) to find out what else you might need to look out for when adapting the pipeline to your files.
# Scripts

## 00_source
Loads all required packages and runs the pipeline. Dependencies must be specified here. If you intend to source a single script (e.g., as a background job), I recommend commenting out all other source commands and running this script. Alternatively, you can copy the dependencies into the script you want to run. 
## functions
Loads all custom functions I defined for this pipeline into the R environment. Functions are documented through comments. The overall logic of these functions is very similar; they basically wrap other functions into short workflows which can be run in batch. If you want to define further custom functions or manipulate what the individual scripts do, do it here.
## 01_create_dirs
Creates ```data/``` and its folder substructure. It also runs a quick and dirty function to check whether you have some .LAS files in the correct folder and aborts the pipeline if there are no files found there. If you cloned or downloaded this pipeline, the script completes the pipeline's "intended" folder structure. If you cloned this pipeline with git, this script completes the pipeline's intended folder structure. Note that ```data``` and its subdirectories potentialy contain very large files (e.g., point cloud data) and are thus listed in ```.gitignore```. 
## 02_clip_classif
Clips point clouds using a rectangular or circular buffer centered around their coordinate system origin. Also classifies ground points using a Cloth Simulation Function (CSF). The CSF turns the point clouds upside down and simulates a cloth being thrown over the inverted ground terrain. It then classifies or discards potential ground points based on a distance threshold. Further information on the CSF can be found in the [LidR package handbook](https://r-lidar.github.io/lidRbook/gnd.html#csf) and in [Zhang et al. 2016](https://www.mdpi.com/2072-4292/8/6/501/htm). Note that the CSF has parameters like hardness and cloth simulation which should be tuned to your point cloud topography to achieve good results. Adapting the script to work with LidR's other ground classification options should be relatively straightforward if you so desire. The script will also export all clipped and classified point clouds to different folders. 
## 03_dtm_normalize_height
Normalizes point heights using one of three methods implemented in LidR: DTM normalization, point cloud normalization (spatial interpolation) or a hybrid method (see [the LidR package handbook](https://r-lidar.github.io/lidRbook/norm.html)). Normalized point clouds are saved to a different folder. 
## 04_dtm_chm_dsm_generation
Estimates Digital Terrain Models (DTM), Canopy Height Models (CHM) and Digital Surface Models (DSM) based on your point clouds and creates very basic overview figures to visually assess the resulting rasters. Model accuracy greatly depends on ground classification accuracy. We used [Lidr's implementation of the pitfree algorithm](https://r-lidar.github.io/lidRbook/chm.html#pitfree) to avoid pits in the output rasters. Model rasters are exported into a corresponding folder.
## 05_whole_stand_pai
Estimates PAI for vertical slices of a given thickness following an approach laid out by [Flynn et al. 2023](https://bg.copernicus.org/articles/20/2769/2023/) and [Li et al. 2016](https://www.tandfonline.com/doi/abs/10.1080/07038992.2016.1220829?journalCode=ujrs20). The script refactors code from the referenced paper, so please note [the corresponding licensing agreement](https://github.com/will-flynn/tls_dhp_pai/blob/1.1/LICENSE). For each slice, PAI is calculated as $`(C * (N_{i}÷N_{t}))`$, where $`C`$ is a correction factor (see references), $`N_{i}`$ is the number of voxels containing returns within a slice, and $`N_{t}`$ is the total number of voxals within the slice. Voxels need to be quite small for this to work. The appropriate voxel size is to be determined by the user. Larger voxels lead to larger stand-level PAI estimates due to the relatively larger proportion of voxels that will be filled with returns. A large voxel size will also reduce the amount of slices with PAI = 0 (likely caused by occlusion effects) and reduce computational effort, while the opposite is true for smaller voxel sizes. The script returns two ```.csv``` tables. One with the estimated PAI of each slice and one whole stand summary displaying the resolution of calculation, stand-level PAI, the Z height of the highest voxel (dominant height).   

A fair warning: The custom ```estimatePAI()``` function also wraps a ```modifyPC()``` function which can be used to modify the point cloud density and extent. I did not test all possible combinations of arguments (settings) you could potentially pass to ```modifyPC()```, and it is thus likely to cause errors if certain function arguments are missing. 
## 06_dendrometrics_FORTLS
Detects trees from point clouds and estimates stand-level dendrometrical measurements (forest inventory) from the detected trees using a fixed area plot design. The script relies on the FORTLS package (see [FORTLS publication](https://www.sciencedirect.com/science/article/pii/S1364815222000433) or package documentation) and is the only script to deviate from the usual script scructure by using a for-loop. The script is functional but tree detection can take a very long time and even lead to memory allocation issues based on plot design. Make sure you've understood FORTLS's general workflow before attempting to troubleshoot. If memory allocation issues arise, it will probably be during tree detection and may be rectified by adapting the plot design through buffers/maximum distance thresholds. FORTLS gives priority to rectangular buffers and discards the maximum threshold arguments if both are passed to the ```normalize()``` function. The authors recommend to use a maximum distance threshold that is at least 2.5 m larger than the radius of calculation to avoid edge effects. 

The FORTLS authors also shared a lot of insights on buffer behavior and best practices with us:
- In relatively small plots (like circular fixed area plots of 7 m radius), the inclusion or exclusion of a few trees can cause large differeces in plot-level estimates (units per ha). You must note that one tree in that plot design represents 65 trees/ha when the expansion factor is used. Therefore, the function metrcis.variables works with units per ha and small plots can be very sensitive to no detected (or false detected) trees.
- It is also very important to define the argument stem.section of the tree.detection.multi.scan function as precise as possible. It must define the stems section free of understory and crown as good as possible (e.g. between 1 and 5 m -> stem.section = c(1, 5)), and try to keep it as wide as possible.
- If there is a lot of understory vegetation, low branches... and it is difficult to find a section free of this "noise"; there is an optional argument in the tree.detection.multi.scan function for that purpose. It is understory = TRUE (by default is FALSE).

Different buffers may cause some differences because of the algorithms implemented in FORTLS. Some of the reason behind that may be:
- Possibility of undetected trees near to plot borders due to omission of parts of the trees out of borders. In this sense, I recommend you to employ a larger buffer (max.dist) than plot radius in order to improve tree detection near to plot borders. Then, metrics.variables function will only include those trees within the plot radius defined.
- It is important to make sure plot center is being the same in all cases. For that purpose, you can use the arguments of the normalize function (e.g.  x.center = 0, y.center = 0). Otherwise, plot center will be defined as the mean point between the maximum and minimum X and Y coordinates of the point clouds. Therefore, plot ce
# FAQ
## What do I need to run this pipeline?
One or multiple registered point cloud files stored in ```data/point_cloud_data/las_local_coord/```. Point cloud files should be stored in .las file format. It might also be possible to run the pipeline on .laz files, but I do not recommend it as this format takes a long time to load whenever LidR's ```readLAS``` function is called (which happens frequently throughout the pipeline). 
Point clouds should also be in a local coordinate reference system where the origin is in the plots relative center, although this condition can be violated if the the buffer arguments within the custom functions are adjusted accordingly.

## Why did you iterate over .las files using ```walk2``` instead of using ```loops``` or a ```lascatalog``` ? 
The way the pipeline is structured, all functions are collected in the functions script and each executable script contains only function options, input options and the walk2 command which iteratively executes the function for all files within the given directory. This has some advantages, e.g, that function settings can be easily adjusted before rerunning the pipeline and drawbacks, e.g, function definitions being "disembodied" from their settings which makes it more confusing to alter functions. 

A ```lascatalog``` would enable us to conduct operations involving all .las files with less code, but from a purely functional perspective, I did not find huge differences between the two approaches. Under the hood, ```lascatalog``` also iterates through the .las files and its not necessarily faster. Its largest drawback is that the ```lascatalog``` engine is exclusive to LidR and other Lidar-focused packages calling on lastools, whereas the currently implemented approach to batch-processing is Lidar-agnostic and exactly the same for the whole pipeline. 

I decided to limit the amount of loops within the pipeline for two reasons:
1. Loops in R do not work 100% the same way they work in other popular programming languages and I did not want to introduce unnecessary barriers. 
2. I find the assignment-based logic of looping hinders clarity when it comes to larger and more complex operations and that the requirement to "think in a loop" can make it more difficult to troubleshoot loops than custom functions.

One noteable exception of this is the for-loop I used within the ```dendrometrics_FORTLS``` script. All other scripts work on .las files directly, but FORTLS's normalize function parses function input from a string containing the file name and a string containing the file directory. I'm sure its possible to transcribe this pipeline into a custom function, but I could not allocate further time to find a way around this peculiarity. 

## Why did you use ```here()``` instead of relative filepaths? 
If you cloned this repo using Git and opened the R project, it will automatically be set as the working directory and relative filepaths should work just fine. However, ```here()``` from the [here](https://here.r-lib.org/) package is superior to relative filepaths, because it calls on your operating systems filepath logic to reference a filepath. This means filepaths referenced using here do not have to be changed to be readable by UNIX-based systems. Moreover, it is easier to find and exchange directories within the filepath because directories are function arguments instead of parts of a huuuuge string. 

## Where do the ominuous runtime estimates come from?
I used the [microbenchmark](https://github.com/joshuaulrich/microbenchmark/) package to estimate the runtime of all scripts and functions at least once. I did not export the results since they likely depend on your system but I generally commented on arguments that influence the runtimes of certain functions to a substantial degree. 

## What are the Examiner folders?
Examiner folders are output folders for singular outputs. The pipeline is written to process a bunch of files in batch, but if you want to examine the results of one specific function, you can change the output filepath to an Examiner folder.

## Why does the pipeline export so many .las files?
I think there's no way around it. The ground classification must be saved in order to be useable for other operations - I tried processing in batch without intermediate saves, but I would recently run into memory shortages - it's just too much stuff to have in the environment. There is probably a super smart way around this, either by optimizing the function logic or by parallel processing, but I have not looked to much into it. Ultimately, I just put the ground classification and clipping into one operation at the very start of the pipeline.

## I want to adapt the pipeline to use for my own files, what do I have to look after? 
I have not tried running the pipeline on different files, but I put some effort into keeping it clean and interchangeable. All in all, it should not be too hard to adapt it to your own files. One major cause of trouble will arise from your filename naming convention. All scripts use ```gsub()``` to remove file endings and unnecessary string parts from the filepaths and filenames strings. Since I based ```gsub()```s arguments on our file naming convention,
```gsub()``` will remove either too much or too little and you will have to adapt how many characters are removed from the filename strings:
```
filenames <- path_file(input.filepaths)
filenames <- gsub('.{0,10}$', '', filenames)
```
Special attention should be paid to the for-loop in ```dendrometrics_FORTLS```, which uses gsub a lot in internal references, making it very vulnerable to breaking. 

Another source of trouble might be the coordinate systems and buffer coordinates. The coordinate system we used is locally centered on a temperature logger in the center of the plots, which makes buffering super straightforward and simple to implement and we recommend you do the same, because some packages such as ```FORTLS``` will assume your point cloud's coordinate system to behave this way. All clipping operations within the pipeline thus assume your point clouds coordinate system origin is static - make sure it is.

## I want to use a different buffer to clip?
The clip function is written in a way that it accepts rectangular and spherical buffers passed to it by the ```buffer.method``` argument. If you want something else, you will have to go adjust the function logic accordingly, which should not be too hard to do. Check the LidR documentation for buffer options. Also the buffer's primary purpose at this point is to reduce point cloud size and later scripts such as ```whole_stand_pai.R``` offer to buffer again.

## What is the logic behind the coordinates given to the rectangle buffer?
The rectangle buffer is drawn from a bottom left and a top right point. The coordinate origin depends on your coordinate system which makes a strong argument for setting a coordinate system origin in the center of your plot. Since our coordinate systems is centered on the temperature logger, negative coordinates or either in front or left of the sensor, positive coordinates are right or behind it. With a 40 m square buffer, my bottom left point was -20, -20 and the top right point 20, 20.
