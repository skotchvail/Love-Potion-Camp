# Love-Potion-Camp


**Tranceporter II Code related to the Burning Man camp called [Love Potion](http://www.lovepotioncamp.com/).**


Tranceporter II is an amazing art car with thousands of LED's that display
beautiful animations timed to music. 

## Processing

The display code runs in a Java-based programming environment called
"Processing". Each animation is called a "Sketch". To install Processing on your computer, get the latest
version [here](http://www.processing.org/download/). Note that you will need at least version 2.0. 

Test that you can run one of the sample Sketches that comes with Processing.

## Libraries

You will need to install some Java Libraries that the code depends on.
The libraries should go in your "sketchbook" folder. The path can be 
found in Processing preferences. My path looks like this: 

    /Volumes/Data/skotchvail/Documents/Processing/Libraries

Get the libraries [here](https://www.box.com/s/oh7azkw7puogdaeprcga) and move them
into your `Libraries` folder. Ask Skotch for box permission if needed. 

## If you are not going to drive the LED's

If you are going to drive the LED's, then skip this section. 

Life is easier if you don't have to install the TotalControl drivers.
If that is your case, you will need to modify some code to get
everything to run. 
Go to `TotalControlConsumer.PDE` and comment out the import line like this:

     // import TotalControl.*;
     
Next rename the class `TotalControlFake` so that it looks like this:

     static class TotalControl
     
That should be enough to bypass the driver. Be sure that you do not checkin 
these changes. They are only to allow your system to run with a partial install.

Skip the next section and go to "Test and Run"

## Setup to drive the LED's

Using the hardware depends on an interface library that in turn depends
on the D2XX library. If you are not going to be driving the hardware,
but just want to use the simulation, then you don't need to do this. 

Download the [D2XX library](http://www.ftdichip.com/Drivers/D2XX.htm) Virtual COM Port (VCP) drivers.

1. Copy the i386 version of the library into `/usr/local/lib`.  
2. Symlink the base .dylib name to the versioned path. 
   e.g.  `ln -s /usr/local/lib/libftd2xx.1.2.2.dylib /usr/local/lib/libftd2xx.dylib`  
3. Copy the *.h files into `/usr/local/include`


Make the PaintYourDragon stuff: 

    $ git clone git://github.com/PaintYourDragon/p9813.git
    
On Skotch's Mac, he had to modify the two Makefile's (`p9813/Makefile` and `p9813/Processing/Makefile`) to use
`CC         = llvm-gcc-4.2`
but only try this if you are getting compile or link errors. 

If that doesn't fix things, you might want to try the older instructions tried to use a patch found in the parent dir of Love-Potion-Camp checkout: `$ patch -p0 < ../Love-Potion-Camp/patch.txt`

In any event, you need to run both Makefiles from the command line. 

    $ cd p9813
    $ make
    $ cd processing ; make && make install

## Test and Run

That should be enough to get the simulation to run on your computer. You should be able to load and
run `TranceporterIIProcessing.pde`. You will see an image of the bottle and some animations. 

## Adding Sketches

See the document [ImportingSketches.md](./ImportingSketches.md) for info on how to add Sketches
to the system. 


## Code notes

Processing has a frame buffer.  We can read the pixels from that frame
buffer and then send them to the LED "Total Control" code.

