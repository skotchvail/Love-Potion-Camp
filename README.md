Love-Potion-Camp
================

Code related to the Burning Man camp called "Love Potion"


==== HOWTO ====

The display code runs in a Java-based programming environment called
'processing'. It depends on an interface library that in turn depends
on the D2XX library.  Briefly:

Download the D2XX library:
http://www.ftdichip.com/Drivers/D2XX.htm

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