These are instructions for importing a 3rd party sketch into our system. 

===== Get Processing Running our App =====

Open this file into Processing app: 

"Tranceporter II/Sketches/TranceporterIIProcessing.pde"

Click the run button. If it works great, skip to the next section. 

If you did not get the TotalControl driver installed you will get Java lib
errors. In this case, you can comment some code out to get running. 

To do that, go to Pixels.pde and comment out:

	import TotalControl.*;

Also comment out anything that has the variable "tc" in it. 
For example, 

	TotalControl tc; 
	tc.printError(status); 

don't mess with variables that have tc in their name like 
TC_ERR_OPEN. Those should be left alone. You should be able to run
fine now without the driver. 

===== Adding Your Sketch =====

1) From processing, select the arrow on the right, and pick "new Tab". 
This will create a new file. Name the new file the same as the class 
name of your new sketch. 

Alternatively, you can close Processing, drag all of the files into 
the same directory as our app, put the data files into data, and then 
reopen Processing. It will have then added the new files to Processing. 

2) Paste the existing sketch into this file. 
If you have data files, copy them into the TranceporterIIProcessing/data 
folder, make sure that your filenames don't already exist, or you will 
break another sketch. 

3) Wrap your code in a class and give it a constructor, like this: 

    class MyNewClass extends Drawer {

    MyNewClass(Pixels p, Settings s) {
      super(p, s, JAVA2D);
    }

4) Under the constructor and before setup(), add this method with the 
display name for your class. This will display on the pad  GUI. 

  String getName() { return "MyNewClass"; }

5) In your setup() method, delete the line the has the size(100, 100) in it.
That is normally the first line. You are stuck using the size of the 
LED's that we have installed on the art car. 

6) Any graphic calls need to be prefixed with pg.  For example,       
	
	background(color(0, 0, 0));

should be changed to: 

	pg.background(color(0, 0, 0));

Anything that draws to the screen must draw to pg instead. This is
very important, things won't work unless you find all of these places
and convert them. 

7) Go to TranceporterIIProcessing and add your sketch to the list of 
modes. Find the section like this and add your new class: 

    modes = new Drawer[] {

You probably want to make your class the first in the array, to make 
it easier to debug. 

8) Run the sketch and see how it looks. You can click on the 
left side 2D square to rotate through the different sketches, 
but to control the different settings you need the Pad app. 

===== After the Initial Run =====

1) There are 2 sliders that you can change to mean anything you want 
for your particular sketch. To get the value from the slider (0.0-1.0) 
use:
 	
 	settings.getParam(settings.keyCustom1)
 	settings.getParam(settings.keyCustom2)


If you are going to use the custom controls, then you should set 
their display names with these methods, so that people using the 
iPad controller know what the custom control does in your sketch: 

	String getCustom1Label() { return "More Awesome";}
 	String getCustom2Label() { return "Zestier";}
 	
 
2) If you want to detect beats, use these booleans: 

	settings.isBeat(0);
	settings.isBeat(1);
	settings.isBeat(2);

This are one when there is a beat on the treble, mid range, or bass. 
Use these in your draw routine.

3) If you want to use colors that change to the beat, use: 

	getNumColors();
	getColor(index);

see the other sketches for how this is used. 

4) You can use the variables "width" and "height" to get the size 
of the drawing area in pixels. 



