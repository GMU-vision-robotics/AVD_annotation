Object Labeling Tool
Derek Hoiem
April 03, 2008


************************************************************************
License Information
This software can be used for any purpose, commercial or not, without any 
warranty or liability to the author in any way.  The software can be 
freely modified and distributed.  


************************************************************************
Acknowledgements
If this software is used to prepare data
that is used in a published paper or technical report, please include 
an acknowledgement, such as "We created the ground truth annotation using
the Object Labeling Tool from Hoiem."



************************************************************************
Instructions for Object Labeling Tool

In MATLAB, run
objects = objectLabelingTool(im);

You will see a list of the possible commands:
  q: quit (when done with image)
  n: new object; 
   1) type name of object (enter when done)  
   2) left-click polygon points, right click when done
  c: clear object (hold cursor over object region and press "c")
  a: add to object region (hold cursor over object region and press "a")
     1) left-click polygon points, right click when done
  r: remove part of object region (opposite of "a")
  b: move object backward (changes the depth ordering)
  f: move object forward (oppostie of "b")

Label the objects from front to back.  The program maintains a separate 
mask for each object and then flattens them to create the label image
using the ordering, with lower numbers being in front.  So if you want to
label a boat in the water, first create an object for the boat, then create 
one for the water.  When drawing the region for the water, the boat pixels
will be excluded.  "b" and "f" can be used to change the depth ordering. 

Note that the image window must be active and the cursor must be over the 
window for the keypress to be registered.  When selecting a region, you can
click outside of the image (but within the figure) to select points on the 
corner or on the side of the image.  Be sure to press "q" to quit if you want
to save the object labels.  If you press "Ctrl-C", there will be no output.
The right-click does not add a point.    

To edit existing object labels stored in "objects", run
objects = objectLabelingTool(im, objects);

Image Display (fig 1):
Initially the image will be full color.  When drawing a polygon, green '*' 
markers will show polygon points with dashed blue lines connecting them.  
When you right click, the labeled portions of the image will be grayscale, and
the boundaries will be shown with red lines.  

Object Display (fig 2):
Initially, the image will be gray.  After each object is added or modified, 
the display will be updated.  Pixel color indicates the object regions
(note that colors will change as more objects are added), with gray being 
unlabeled.  A text label in the format "<num>: <name>" appears at upper-left 
corner of the object's bounding box.  <num> indicates the current depth 
order.  <name> indicates the object name.    


Output:
  objects.
    imsize: [imh imw] size of image in pixels
    ordering(nobj): depth order of objects (lower is closer)
    rawmask{nobj}: the user-given mask for the objects
    labels(imsize): a map of the object pixels
    bnd(imsmize): a map of the object boundaries
    name{nobj}: the names of the objects
    num: the number of objects




************************************************************************
Instructions for objectLabelingScript

The script loads each image in the given directory, runs objectLabelingTool, 
and saves the objects in a corresponding filename.

Set paramters at the top of the script appropriately:

fix_mode: whether or not you want to edit object files that already exist
          if 0, will skip images with existing object files
	  if 1, will load those files for editing
imdir: the image directory
ext: the image extension (e.g., ".bmp" or ".jpg")
outdir: the output directory
outext: the ending part of the object filename
	for example, if outext='_objects.mat', 
            "image001.bmp"-->"image001_objects.mat"

If you do not want to save the current labels, press "Ctrl-C" to exit out 
of the object labeling program without saving.



************************************************************************
Comments

Please feel free to email me with suggestions or comments.  My current 
address is dhoiem@uiuc.edu.  If there is a bug, I most likely will fix it 
and upload the new version.  But please do not ask me to add new features 
or to customize the program for your needs.


Derek Hoiem 

