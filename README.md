# Love-Potion-Camp


**Tranceporter II Code related to the Burning Man camp called [Love Potion](http://www.lovepotioncamp.com/).**


Tranceporter II is an amazing art car with thousands of LED's that display
beautiful animations timed to music. 

## Processing

The display code runs in a Java-based programming environment called
"Processing". Each animation is called a "Sketch". To install Processing on your computer, get the latest
version [here](http://www.processing.org/download/). Note that you will need at least version 2.0b9. 

Test that you can run one of the sample Sketches that comes with Processing.

## Libraries

You will need to install some Java Libraries that the code depends on.
The libraries should go in your "sketchbook" folder. The path can be 
found in Processing preferences. My path looks like this: 

    /Volumes/Data/skotchvail/Documents/Processing/Libraries

Get the libraries [here](https://www.box.com/s/a351863d10c9046a2ac1) and move them
into your `Libraries` folder. Ask Skotch for box permission if needed. 

## Test and Run

That should be enough to get the simulation to run on your computer. You should be able to load and
run `TranceporterIIProcessing.pde`. You will see an image of the bottle and some animations. 

## Adding Sketches

See the document [ImportingSketches.md](./ImportingSketches.md) for info on how to add Sketches
to the system. 

## Setup to drive the LED's

Using the hardware depends on an interface library that in turn depends
on the D2XX library. If you are not going to be driving the hardware,
but just want to use the simulation, then you don't need to do this. 

Download the [D2XX library](http://www.ftdichip.com/Drivers/D2XX.htm)

Copy the i386 version of the library into `/usr/local/lib`.  Symlink the
base .dylib name to the versioned path.  Copy the *.h files into

    /usr/local/include


Checkout and apply the patch:
(from the parent dir of Love-Potion-Camp checkout)

    $ git clone git://github.com/PaintYourDragon/p9813.git
    $ cd p9813
    $ patch -p0 < ../Love-Potion-Camp/patch.txt
    $ make
    $ cd processing ; make && make install


## Code notes

Processing has a frame buffer.  We can read the pixels from that frame
buffer and then send them to the LED "Total Control" code.

