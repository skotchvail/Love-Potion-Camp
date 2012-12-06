
import TotalControl.*;
import processing.video.*;

Capture myCapture;
TotalControl tc;
int   pixelWidth = 7,  //Width of LED array
      pixelHeight=15,  //Length of LED array
      camHeight=24,    //Height of webcam
      pixelSize=20;   // widtyh of webcam

int[] remap    =new int[pixelWidth*pixelHeight]; //define an array to hold LED locations





void setup ()
{
  int  status,x,y,r;
  short[] pin = { 0x40,0x20,0x80,0x08,0x02,0x04,0x10,0x01 };
  
  size(pixelWidth*pixelSize,pixelHeight*pixelSize,JAVA2D);
  
  for (x=0;x<pin.length;x++) tc.setStrandPin(x,pin[x]);
  status = tc.open(8,72);
  println(status);
  
  r = 0;
  for (x=0;x<pixelWidth;x++) {
    if ((x & 1) == 1) {
      for (y=pixelHeight-1;y>=0;y--)
      remap[r++] = y * pixelWidth + x;
    } else {
      for(y=0;y<pixelHeight;y++)
      remap[r++] = y * pixelWidth +x;
    }
  }
  
  myCapture = new Capture(this,pixelWidth,camHeight,30);
  myCapture.crop(0,(camHeight-pixelHeight)/2,pixelWidth,pixelHeight);
}

void captureEvent(Capture myCapture) {
  myCapture.read();
  tc.refresh(myCapture.pixels,remap);
  tc.printStats();
}

  
