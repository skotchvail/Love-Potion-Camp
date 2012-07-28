// Class to abstract out interfacing with the microcontroller (which in turn sends signals to the wall) and
// to the processing display.

int PACKET_SIZE = 100;
int LOC_BYTES = 1; // how many bytes to use to store the index at the beginning of each packet
int MAX_RGB = 255;

class Pixels {
  int ledWidth, ledHeight, pixelSize;
  color[][] px;
  SerialPacketWriter spw;
  byte txData[];
  
  Pixels(PApplet p, int wi, int he, int pSize, int baud) {
    ledWidth = wi; 
    ledHeight = he;
    pixelSize = pSize;
    px = new color[ledWidth][ledHeight];
    
    if (baud > 0) {
      int npkts = ceil(ledWidth*ledHeight*3.0/(PACKET_SIZE-LOC_BYTES));
      txData = new byte[npkts*PACKET_SIZE];
      
      spw = new SerialPacketWriter();
      spw.init(p, baud, PACKET_SIZE);
    }
  }

  void setPixel(int x, int y, color c) {
    px[x][y] = c;
  }

  void setAll(color c) {
    for (int x=0; x<ledWidth; x++) {
      for (int y=0; y<ledHeight; y++) {
        setPixel(x, y, c);
      }
    }
  }
  
void drawToScreen() {
  
    int xOffset = 10;
    int yOffset = 10;

    noStroke();
    background(color(12,49,81));
    for (int x=0; x<ledWidth; x++) {
      for (int y=0; y<ledHeight; y++) {
        color pixelColor = px[x][y];
        fill(pixelColor);
        rect(xOffset + x*pixelSize, yOffset + y*pixelSize, pixelSize, pixelSize);
      }
    }    
  }
  
  void drawToLedWall() {
    // r, g, b for 1,1 then 1,2; etc.
    
    //TODO: WE NEED TO PUT IN OUR ALGORITHM FOR DRAWING HERE

    int ti=0;
     for (int y=ledHeight-1; y>=0; y--) {
      int dx, x;
      if (y%2 == 0) {
        dx = -1;
        x = ledWidth-1;
      } else {
        dx = 1;
        x = 0;
      }
      
      while (x >= 0 && x < ledWidth) {
        byte[] rgb = new byte[3];
        rgb[2] = (byte) constrain(px[x][y] & 0xFF, 0, MAX_RGB);
        rgb[1] = (byte) constrain((px[x][y] >> 8) & 0xFF, 0, MAX_RGB);
        rgb[0] = (byte) constrain((px[x][y] >> 16) & 0xFF, 0, MAX_RGB);
        
        for (int c=0; c<3; c++) {
          if (ti%PACKET_SIZE == 0) {
            int pktNum = floor(float(ti)/PACKET_SIZE);
            txData[ti++] = byte(pktNum);
          }
          
          txData[ti++] = rgb[c];
        }

        x += dx;
      }
    }        
    
    spw.send(txData);
  }
  
  int getHeight() { return ledHeight; }
  int getWidth() { return ledWidth; }
  int getPixelSize() { return pixelSize; }
}

