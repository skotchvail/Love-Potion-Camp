Love-Potion-Camp
================

Code related to the Burning Man camp called "Love Potion"


==== HOWTO ====

The display code runs in a Java-based programming environment called
'processing'. It depends on an interface library that in turn depends
on the D2XX library. If you are not going to be driving the hardware,
but just want to use the simulation, then you don't need to do this. 
However, you will have to modify the code to remove the TotalProcessing
stuff (see ImportingSketches.md). 

 Briefly:

Download the D2XX library: http://www.ftdichip.com/Drivers/D2XX.htm

Copy the i386 version of the library into /usr/local/lib.  Symlink the
base .dylib name to the versioned path.  Copy the *.h files into

    /usr/local/include.


Checkout and apply the patch:
(from the parent dir of Love-Potion-Camp checkout)

    $ git clone git://github.com/PaintYourDragon/p9813.git
    $ cd p9813
    $ patch -p0 < ../Love-Potion-Camp/patch.txt
    $ make
    $ cd processing ; make && make install
    

Now the libraries are installed in ~/sketchbook. 

Download processing, load the sketches, run.


==== Code notes ====

Processing has a frame buffer.  We can read the pixels from that frame
buffer and then send them to the LED "Total Control" code.

===== Libraries =====

The libraries should go in your "sketchbook" folder. The path can be 
found in Processing preferences. My path looks like this: 

    /Volumes/Data/skotchvail/Documents/Processing

Get the libraries from https://www.box.com/s/a351863d10c9046a2ac1. 
Ask Skotch for permission if needed. 

===== Adding Sketches =====

See the document ImportingSketches.md for info on how to add Sketches
to the system. 
