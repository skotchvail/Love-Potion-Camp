

import TotalControl.*;
import processing.video.*;

Capture myCapture;
 TotalControl tc;

int gridnum = 0;
int ledRows = 12;    //Height of LED's in pixels
int ledColumns = 14; //width of LED's in pixels
int pixelSize = 30;  // Pixel scaling for onscreen display
int camHeight = 30;  // Height of row (uncropped) camera input in pixels
int mappedColumnNum = 0;
int row  = 0;
int[] mapnum = new int[175];

int          nStrands        = 1;
int          pixelsPerStrand = 175;

void setup() 
{
   size(300,300);
   
 int status = tc.open(nStrands,pixelsPerStrand);
   
   if(status != 0) {
    tc.printError(status);
    exit();
  }
 
{
  for (gridnum=0;gridnum<ledColumns*ledRows;gridnum++)
  {
    row= int(gridnum/ledColumns);
    if (row > 0 && row % 2 != 0)  
    {  
      mappedColumnNum = ledColumns - ( gridnum - (row*ledColumns ) );
      mapnum[gridnum] = (row*ledColumns) + mappedColumnNum +1;
    }

    else 
    {
      mapnum[gridnum]=gridnum;
    }
  }
}

  //myCapture = new Capture(this,width, height, 30);
 myCapture = new Capture(this,ledColumns,ledRows, 30); 
 myCapture.crop(0,(camHeight-ledRows)/2,ledColumns,ledRows);
}

void draw()  
{
  
  image(myCapture,0,0,300,300);
//  myCapture = new Capture(this, 300, 300, 30);
  image(myCapture,0,0);
}


void captureEvent(Capture myCapture) {
 myCapture.read(); 
 tc.refresh(myCapture.pixels,mapnum);
 tc.printStats();
}


