

import TotalControl.*;

TotalControl tc;



int height         = 6;  // Height of LED's in pixels
int width          = 14; // width of LED's in pixels

int c(int x, int y) {
  return (y*width) + x;
}

// Maps the PHYSICAL string location to the pixel buffer location, which is precomputed with the width, eg: see the
// "c" function just above.  Therefore, the total-control code doesnt need to know the width * height of the image.
int[] mapnum        = new int[] {
  c(12, 5), c(11, 5), c(10, 5), c(9, 5), c(8, 5), c(7, 5), c(6, 5), c(5, 5), c(4, 5), c(3, 5), c(2, 5), c(1, 5), 
  c(1, 4), c(2, 4), c(3, 4), c(4, 4), c(5, 4), c(6, 4), c(7, 4), c(8, 4), c(10, 4), c(11, 4), c(12, 4), c(13, 4), 
  c(12, 3), c(11, 3), c(10, 3), c(9, 3), c(8, 3), c(7, 3), c(6, 3), c(5, 3), c(4, 3), c(3, 3), c(2, 1), c(1, 3), 
  c(1, 2), c(2, 2), c(3, 2), c(4, 2), c(5, 2), c(6, 2), c(8, 2), c(9, 2), c(10, 2), c(11, 2), c(13, 2), 
  c(12, 1), c(11, 1), c(10, 1), c(8, 1), c(7, 1), c(6, 1), c(4, 1), c(3, 1), c(2, 1), c(1, 1), c(0, 1), 
  c(1, 0), c(2, 0), c(3, 0), c(4, 0), c(5, 0), c(7, 0), c(9, 0), c(10, 0), c(12, 0)
  };


  int          nStrands        = 1;
int          pixelsPerStrand = mapnum.length;


int whichColumn = 0;



void setup() 
{
  size(width, height);
  frameRate(1);


  int status = tc.open(nStrands, pixelsPerStrand);

     if(status != 0) {
      tc.printError(status);
      exit();
    }

  // print out the mapping for "debugging"
  for (int i =0; i< mapnum.length; i++) {
    println(mapnum[i]);
  }
}

// This function loads the screen-buffer and sends it to the TotalControl
void toleds() {
  loadPixels();
  // print pixels for "debugging"
  //  println(pixels.length);
  // for (int i = 0; i< pixels.length; i++) {
  //    	println(pixels[i]);
  //  }
  tc.refresh(pixels, mapnum);
  tc.printStats();
}

void draw()  
{
    whichColumn = (whichColumn + 1) % width;


  background(0);
  stroke(-1);
  line(whichColumn, 0, whichColumn, height-1);


  toleds();
}

