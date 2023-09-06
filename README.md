# Folder Structure
```
FILEPATH/OREF_microclimate
├── 00_source.R                            
├── 01_create_dirs.R
├── 02_clip_classif.R
├── 03_dtm_normalize_height.R
├── 04_dtm_chm_dsm_generation.R
├── 05_whole_stand_pai.R
├── 06_forest_inventory.R
├── data
│      └── point_cloud_data
│      │          └── las_files
│      │                     ├── ...
│      │                     ├── Examiner
│      │                     └── las_local_coord
│      │                               ├── ...las
│      │                               ├── clipped_classif
│      │                                            └── ...las
│      │                               └── normalized
│      │                                            └── ...las
│      └── raster
│      │       ├── CHM
│      │       ├── DSM
│      │       ├── DTM
│      │       └── Examiner
│      │
│      │
│      │
│      └── output
│              ├── forest_inventory
│              ├── point_cloud_distances
│              └── whole_stand_pai
├── deprecated
├── functions.R
├── OREF_microclimate.Rproj
└── README.md
```
# Scripts
## 00_source
Loads all required libraries/packages and runs the pipeline. All dependencies should be specified in the source script.   
## functions
Loads all custom functions used in the pipeline into the environment. Also serves as function documentation. 
## 01_create_dirs
Creates ```data/``` and its folder substructure. Also runs a function to validate that you stored your .las files into the right folder. If you cloned the pipeline using git, this script effectively completes the pipeline's folder structure (as ```data``` and its subdirectories contain large files and are thus listed in ```.gitignore```). 
## 02_clip_classif
Clips your point clouds using a rectangular and circular buffer centered around the coordinate system origin. Also classifies ground points using a CSF - Cloth Simulation Function (see LidR docu or various papers). Note that the CSF parameters must be adjusted to your point clouds to produce good results. Adapting the function to work with LidR's other ground classification options should be relatively straightforward if you so desire. Saves the clipped and classified point clouds in a different folder. 
## 03_dtm_normalize_height
Normalizes point cloud heights using either of three methods implemented in LidR. Saves the normalized point clouds in a different folder.
## 04_dtm_chm_dsm_generation
Generates digital terrain models, canopy height models and digital surface models of your point clouds as rasters and creates very basic overview figures to visually assess the results. The accuracy of the generated models mostly depends on the ground classification accuracy. We used Lidr's implementation of the pitfree algorithm to avoid pits in the output raster. Rasters are then exported into the correct folder. 
## 05_whole_stand_pai
Estimates PAI for vertical slices of a given thickness following an approach laid out by [Flynn et al. 2023](https://bg.copernicus.org/articles/20/2769/2023/) and [Li et al. 2016](https://www.tandfonline.com/doi/abs/10.1080/07038992.2016.1220829?journalCode=ujrs20). Utilizes code from the Flynn et al. paper. For each slice, PAI is calculated as $`(C * (N_{i}÷N_{t}))`$, where $`C`$ is a correction factor (see referenced papers), $`N_{i}`$ is the number of voxels containing returns within a slice, and $`N_{t}`$ is the total number of voxals within the slice. For this to work, voxels need to be quite small. The appropriate voxel size is to be determined by the user. Larger voxels lead to larger stand-level PAI estimates due to the relatively large proportion of voxels that will be filled with returns. A large voxel size will also reduce the amount of slices with PAI = 0 (likely caused by occlusion effects) and reduce computational effort, while the opposite is true for smaller voxel sizes.

The custom ```estimatePAI()``` function also wraps a ```modifyPC()``` function which can be used to modify the point cloud density and extent. I have not tested all possible combinations of settings that can be potentially passed to said function, and ```modifyPC()``` is likely to throw errors if certain function arguments are missing. As output, this script returns two .csv tables. One with the estimated PAI of each slice and one whole stand summary displaying the resolution of calculation, stand-level PAI, the Z height of the highest voxel (dominant height).   
## 06_forest_inventory

# FAQ
## Why did you iterate over .las files using ```walk2``` instead of using ```loops``` or a ```lascatalog``` ? 
The way the pipeline is structured, all functions are collected in the functions script and each executable script contains only function options, input options and the walk2 command which iteratively executes the function for all files within the given directory. This has some advantages, e.g, that function settings can be easily adjusted before rerunning the pipeline and drawbacks, e.g, function definitions being "disembodied" from their settings which makes it more confusing to alter functions. 

A ```lascatalog``` would enable us to conduct operations involving all .las files with less code, but from a purely functional perspective, I did not find huge differences between the two approaches. Under the hood, ```lascatalog``` also iterates through the .las files and its not necessarily faster. Its largest drawback is that the ```lascatalog``` engine is exclusive to LidR and other Lidar-focused packages calling on lastools, whereas the currently implemented approach to batch-processing is Lidar-agnostic and exactly the same for the whole pipeline. 

I decided to limit the amount of loops within the pipeline for two reasons:
1. Loops in R do not work 100% the same way they work in other popular programming languages and I did not want to introduce unnecessary barriers. 
2. I find the assignment-based logic of looping hinders clarity when it comes to larger and more complex operations and that the requirement to "think in a loop" can make it more difficult to troubleshoot loops than custom functions.

## Why did you use ```here()``` instead of relative filepaths? 
If you cloned this repo using Git and opened the R project, it will automatically be set as the working directory and relative filepaths should work just fine. However, ```here()``` from the [here](https://here.r-lib.org/) package is superior to relative filepaths, because it calls on your operating systems filepath logic to reference a filepath. This means filepaths referenced using here do not have to be changed to be readable by UNIX-based systems. Moreover, it is easier to find and exchange directories within the filepath because directories are function arguments instead of parts of a huuuuge string. 

## Where do the ominuous runtime estimates come from?
I used the [microbenchmark](https://github.com/joshuaulrich/microbenchmark/) package to estimate the runtime of all scripts and functions at least once. I did not export the results since they likely depend on your system but I generally commented on arguments that influence the runtimes of certain functions to a substantial degree. 

## What are the Examiner folders?
Examiner folders are output folders for singular outputs. The pipeline is written to process a bunch of files in batch, but if you want to examine the results of one specific function, you can change the output filepath to an Examiner folder.

## Why does the pipeline export so many .las files?
I think there's no way around it. The ground classification must be saved in order to be useable for other operations - I tried processing in batch without intermediate saves, but I would recently run into memory shortages - it's just too much stuff to have in the environment. There is probably a super smart way around this, either by optimizing the function logic or by parallel processing, but I have not looked to much into it. Ultimately, I just put the ground classification and clipping into one operation at the very start of the pipeline.

## I want to adapt the pipeline to use for my own files, what do I have to look after? 
I have not tried adapting the pipeline for different files, but I put some effort into keeping it clean and interchangeable and it should not be hard to adapt it. I think the main cause of trouble will be your filename naming convention. All scripts use ```gsub()``` to remove file endings and unnecessary string parts from the filepath list strings. Since the arguments are based on our file naming convention,
```gsub()``` will probably remove either too much or too little. Just adapt how many characters are removed from the strings:
```
filenames <- path_file(input.filepaths)
filenames <- gsub('.{0,10}$', '', filenames)
```
Another source of trouble might be the buffer coordinates. The coordinate system we used is centered on a temperature logger in the center of the plots, which makes buffering super straightforward and simple to implement. The clip and classify tool also assumes your point clouds coordinate system origin is always so same - make sure it is.

## I want to use a different buffer to clip?
The clip function is written in a way that it accepts rectangular and spherical buffers passed to it by the ```buffer.method``` argument. If you want something else, you will have to go adjust the function logic accordingly, which should not be too hard to do. Check the LidR documentation for buffer options. Also the buffer's primary purpose at this point is to reduce point cloud size and later scripts such as ```whole_stand_pai.R``` offer to buffer again.

## What is the logic behind the coordinates given to the rectangle buffer?
The rectangle buffer is drawn from a bottom left and a top right point. The coordinate origin depends on your coordinate system which makes a strong argument for setting a coordinate system origin in the center of your plot. Since our coordinate systems is centered on the temperature logger, negative coordinates or either in front or left of the sensor, positive coordinates are right or behind it. With a 40 m square buffer, my bottom left point was -20, -20 and the top right point 20, 20.
