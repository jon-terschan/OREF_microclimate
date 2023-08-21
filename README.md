# FAQ
## WHY HERE() INSTEAD OF RELATIVE FILEPATHS?
here() is more robust than relative filepaths because it calls on the operating systems filepath logic to create a path string. This means filepaths don't have to be changed to work in UNIX based systems
Moreover, its easier to find and exchange folders because they are function arguments instead of words within a huge string.

## WHERE DO RUNTIME ESTIMATES COME FROM?
I used the microbenchmark package to estimate the runtime of  scripts and functions at least once.

## WHAT ARE THE EXAMINER FOLDERS?
Output folders for single outputs. If you want to look at the results of one specific function, just change the input to a single file and the output to an examiner folder. 

## WHY ARE SO MANY LAS FILES EXPORTE DOUBLE
The ground classification must be saved and I dont want to overwrite the original files for obvious reasons. I think theres no way around it, at the very least ground classified and clipped point clouds and normalized point clouds must be saved so they can be used later on. Thats why I put classification and clip into one operation. 

## I WANT TO ADAPT THE PIPELINE FOR MY OWN FILES, WHAT DO I HAVE TO LOOK AFTER
I think the main cause of trouble will be the filenames. Scripts use gsub to remove file endings and unnecessary string paths from the filepath list strings and since its based on our OREF files, they might remove too much or too little. Fortunately that should be really easy to adapt, just change how many characters gsub removes from the string: 
```
filenames <- path_file(input.filepaths)
filenames <- gsub('.{0,10}$', '', filenames)
```

## I WANT A DIFFERENT BUFFER
For semantic reasons, I didnt find an easy way to move the bufffer settings into the scripts, so they remain in the function definitions. LidR has multiple buffer options, I used a square of 40m side length, but you can use
whatever by swapping out the code in the functions definition. See LidR documentation for buffer options. 

## WHAT IS THE RECTANGLE COORDINATE LOGIC IN THE BUFFER
The rectangle buffer is drawn from a bottom left and a top right point. Origin depends on your coordinate system. Since LocalCSes origin is centered on the scanner, negative coordinates are either in front or left of the sensor, positive coordinates are right or behind. Thus, my lowest point was -20, -20 and the highest point 20, 20.
