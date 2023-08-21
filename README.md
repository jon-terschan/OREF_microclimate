# FAQ
## Why did you use ```here()``` instead of relative filepaths? 
If you cloned this repo using Git and opened the R project, it will automatically be set as the working directory and relative filepaths should work just fine. However, ```here()``` from the [here](https://here.r-lib.org/) package is superior to relative filepaths, because it calls on your operating systems filepath logic to reference a filepath. This means filepaths referenced using here do not have to be changed to be readable by UNIX-based systems. Moreover, it is easier to find and exchange directories within the filepath because directories are function arguments instead of parts of a huuuuge string. 

## Where did your ominuous runtime estimates come from?
I used the [microbenchmark](https://github.com/joshuaulrich/microbenchmark/) package to estimate the runtime of all scripts and functions at least once. I did not export the results, but they're probably system dependent as well. 

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

## I want to use a different buffer?
For semantic reasons, I didn't find an easy way to move the buffer options into the scripts, so they remain in the function definitions for now. LidR has multiple buffer options, I used a square of 40 m side length, but you can use whatever by swapping out the code in the functions script. Check the LidR documentation for buffer options. 

## What is the logic behind the coordinates given to the rectangle buffer?
The rectangle buffer is drawn from a bottom left and a top right point. The coordinate origin depends on your coordinate system which makes a strong argument for setting a coordinate system origin in the center of your plot. Since our coordinate systems is centered on the temperature logger, negative coordinates or either in front or left of the sensor, positive coordinates are right or behind it. With a 40 m square buffer, my bottom left point was -20, -20 and the top right point 20, 20.
