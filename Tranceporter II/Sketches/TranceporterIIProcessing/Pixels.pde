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
  
  int xOffset = 10;
  int yOffset = 10;
  int rotationY = 0;


  // 3D version
  int tubeRes = 32;
  float[] tubeX = new float[tubeRes];
  float[] tubeY = new float[tubeRes];
  
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
    
    float angle = 270.0 / tubeRes;
    for (int i = 0; i < tubeRes; i++) {
      tubeX[i] = cos(radians(i * angle));
      tubeY[i] = sin(radians(i * angle));
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
  
  PGraphics drawFlat2DVersion() {
    int expandedWidth = ledWidth * pixelSize;
    int expandedHeight = ledHeight * pixelSize;
    
    // render into offscreen buffer so that we can blur it, and then copy it
    // onto the display window
    PGraphics pg = createGraphics(expandedWidth, expandedHeight, JAVA2D);
    pg.beginDraw();
    pg.noStroke();
    for (int x=0; x<ledWidth; x++) {
      for (int y=0; y<ledHeight; y++) {
        color pixelColor = px[x][y];
        pg.fill(pixelColor);
        pg.rect(x*pixelSize,y*pixelSize, pixelSize, pixelSize);
      }
    }
    pg.filter(BLUR, 2.5);
    pg.endDraw();
    
    // copy onto the display window
    pg.loadPixels();
    loadPixels();
    for (int x = 0; x < expandedWidth; x++) {
      for (int y = 0; y < expandedHeight; y++) {
        pixels[(y + yOffset)*width + x + xOffset] = pg.pixels[y*expandedWidth + x];
      }
    }
    updatePixels();
    pg.updatePixels();
    return pg; 
  }
  
  void drawMappedOntoBottle(PGraphics pg) {
    int width3d = 360;
    int height3d = 360;
    
    // create image version of the 2d map
    PImage img = createImage(pg.width, pg.height, RGB);
    img.loadPixels();
    pg.loadPixels();
    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = pg.pixels[i];
    }
    img.updatePixels();
    pg.updatePixels();

    PGraphics pg3D = createGraphics(width3d, height3d, P3D);
    pg3D.beginDraw();
    pg3D.noStroke();
    pg3D.background(color(6,25,41));
    pg3D.translate(pg3D.width / 2, pg3D.height / 2);
    
    int fullRevolution = 30*5; //5 seconds
    rotationY = (rotationY  + 1) % fullRevolution;
    pg3D.rotateY(map(rotationY, 0, fullRevolution, -PI, PI));
    
//    pg3D.rotateX(map(mouseY, 0, height, -PI, PI));
//    pg3D.rotateY(map(mouseX, 0, width, -PI, PI));
    pg3D.beginShape(QUAD_STRIP);
    pg3D.texture(img);
    for (int i = 0; i < tubeRes; i++) {
      float x = tubeX[i] * 100;
      float z = tubeY[i] * 100;
      float u = img.width / tubeRes * i;
      pg3D.vertex(x, -100, z, u, 0);
      pg3D.vertex(x, 100, z, u, img.height);
    }
    pg3D.endShape();
    pg3D.beginShape(QUADS);
    pg3D.texture(img);
    pg3D.vertex(0, -100, 0, 0, 0);
    pg3D.vertex(100, -100, 0, 100, 0);
    pg3D.vertex(100, 100, 0, 100, 100);
    pg3D.vertex(0, 100, 0, 0, 100);
    pg3D.endShape();
    pg3D.endDraw();
    
    // copy onto the display window
    pg3D.loadPixels();
    loadPixels();
    int xAdjust = (xOffset * 2 + pg.width);
    for (int x = 0; x < pg3D.width; x++) {
      for (int y = 0; y < pg3D.height; y++) {
        pixels[(y + yOffset) * width + x + xAdjust] = pg3D.pixels[y * pg3D.width + x];
      }
    }
    updatePixels();
    pg3D.updatePixels(); // is it necessary to call updatePixels when nothing changed?
  

    
  }
  
  void drawToScreen() {
    background(color(12,49,81));
    PGraphics pg = drawFlat2DVersion();
    drawMappedOntoBottle(pg);
  }
  
  void drawToLedWall() {
    // r, g, b for 1,1 then 1,2; etc.
    
    // TODO: WE NEED TO PUT IN OUR ALGORITHM FOR DRAWING HERE

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

