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

Download the latest [D2XX library](http://www.ftdichip.com/Drivers/D2XX.htm) drivers.

Use the following steps to install on your OS X (these assume you have copied the D2XX directory to your desktop):

1. Open a Terminal window (Finder->Go->Utilities->Terminal).
2. If the `/usr/local/lib` directory does not exist, create it <br/>
   `sudo mkdir /usr/local/lib`
3. if the `/usr/local/include` directory does not exist, create it <br/>
    `sudo mkdir /usr/local/include`
4. Copy the dylib file to `/usr/local/lib` <br/>
    `sudo cp ~/Desktop/D2XX/bin/10.5-10.7/libftd2xx.1.2.2.dylib /usr/local/lib/`
5. Make a symbolic link <br/>
    `sudo ln -sf /usr/local/lib/libftd2xx.1.2.2.dylib /usr/local/lib/libftd2xx.dylib`
6. Copy the D2XX include file <br/>
    `sudo cp ~/Desktop/D2XX/Samples/ftd2xx.h /usr/local/include/`
7. Copy the WinTypes include file <br/>
    `sudo cp ~/Desktop/D2XX/Samples/WinTypes.h /usr/local/include/`
8. You have now successfully installed the D2XX library.



Make the PaintYourDragon stuff: 

    $ git clone git://github.com/PaintYourDragon/p9813.git
    
On Skotch's Mac, he had to modify the two Makefile's (`p9813/Makefile` and `p9813/Processing/Makefile`) to use
`CC         = llvm-gcc-4.2`
but only try this if you are getting compile or link errors. 

If that doesn't fix things, you might want to try the older instructions tried to use a patch found in the parent dir of Love-Potion-Camp checkout: `$ patch -p0 < ../Love-Potion-Camp/patch.txt`

In any event, you need to run both Makefiles from the command line. 

    $ cd p9813
    $ sudo cp p9813.h /usr/local/include/
    $ make clean && make
    $ cd processing ; make clean && make && make install

An unfortunate artifact of the Mac and Linux versions of the FTDI driver
is that the "Virtual COM Port" kernel extension must be disabled before
the p9813 library can be used.  Applications such as
Arduino depend on the serial port for programming and communication, so
these cannot be used at the same time.  

Be sure to run

    $ make unload

in the p9813 directory before running our app if you have the FTDIUSBSerialDriver installed. When you are done, don't forget to run `make load` or
your other other serial communication such as Arduino
programming will not work.


## Test and Run

That should be enough to get the simulation to run on your computer. You should be able to load and
run `TranceporterIIProcessing.pde`. You will see an image of the bottle and some animations. 

If you get a `UnsatisfiedLinkError`, try running processing in 32 bit mode to see if it works.

## Adding Sketches

See the document [ImportingSketches.md](./ImportingSketches.md) for info on how to add Sketches
to the system. 


## Code notes

Processing has a frame buffer.  We can read the pixels from that frame
buffer and then send them to the LED "Total Control" code.

