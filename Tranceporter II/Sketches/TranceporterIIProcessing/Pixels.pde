// Class to abstract out interfacing with the microcontroller (which in turn sends signals to the wall) and
// to the processing display.

import saito.objloader.*;
import java.awt.Rectangle;
import TotalControl.*;

int PACKET_SIZE = 100;
int LOC_BYTES = 1; // how many bytes to use to store the index at the beginning of each packet
int MAX_RGB = 255;

class Pixels {
  private color[] pixelData;
  private int rotation = 0;
  private OBJModel objModel;
  private PGraphics pg3D;

  private Rectangle box2d, box3d;
  
  TotalControl tc;
  
  Pixels(PApplet p, int baud) {
    box2d = new Rectangle(10, 10, ledWidth * screenPixelSize, ledHeight * screenPixelSize);
    box3d = new Rectangle(box2d.x * 2 + box2d.width,box2d.y,360,300);
    pixelData = new color[ledWidth * ledHeight];
    pg3D = createGraphics(box3d.width, box3d.height, P3D);
    
    objModel = new OBJModel(p, "tranceporter.obj");
    // turning on the debug output (it's all the stuff that spews out in the black box down the bottom)
    objModel.enableDebug();
    
    objModel.scale(3);
    
    //noStroke();
    println("drawModes POINTS=" + POINTS + " LINES=" + LINES + " TRIANGLES=" + TRIANGLES + " TRIANGLE_FAN=" + TRIANGLE_FAN
            + " TRIANGLE_STRIP=" + TRIANGLE_STRIP + " QUADS=" + QUADS + " QUAD_STRIP=" + QUAD_STRIP);
    
    setupTotalControl();
  }

  void setPixel(int x, int y, color c) {
    pixelData[c(x,y)] = c;
  }

  void setAll(color c) {
    for (int x=0; x<ledWidth; x++) {
      for (int y=0; y<ledHeight; y++) {
        setPixel(x, y, c);
      }
    }
  }
  
  void toggle3dRender() {
    render3d = !render3d;
  }
  
  PGraphics drawFlat2DVersion() {
    
    // render into offscreen buffer so that we can blur it, and then copy it
    // onto the display window
    int expandedWidth = box2d.width;
    int expandedHeight = box2d.height;

    PGraphics pg = createGraphics(expandedWidth, expandedHeight, JAVA2D);
    pg.beginDraw();
    pg.noStroke();
    for (int x=0; x<ledWidth; x++) {
      for (int y=0; y<ledHeight; y++) {
        color pixelColor = pixelData[c(x,y)];
        pg.fill(pixelColor);
        pg.rect(x*screenPixelSize,y*screenPixelSize, screenPixelSize, screenPixelSize);
      }
    }
    pg.filter(BLUR, 2.5);
    pg.endDraw();
    
    // copy onto the display window
    pg.loadPixels();
    loadPixels();
    for (int x = 0; x < expandedWidth; x++) {
      for (int y = 0; y < expandedHeight; y++) {
        pixels[(y + box2d.y)*screenWidth + x + box2d.x] = pg.pixels[y*expandedWidth + x];
      }
    }
    updatePixels();
    pg.updatePixels();
    return pg;
  }

  void drawModel(PImage texture) {
    try {
      PVector v = null, vt = null, vn = null;

      PVector lowest = new PVector(10000000,10000000,10000000);
      PVector highest = new PVector(-10000000,-10000000,-10000000);
      Segment tmpModelSegment;
      Face tmpModelElement;
      
      // render all triangles
      for (int s = 0; s < objModel.getSegmentCount(); s++) {
        tmpModelSegment = objModel.getSegment(s);
        for (int f = 0; f < tmpModelSegment.getFaceCount(); f++) {
          tmpModelElement = (tmpModelSegment.getFace(f));
          if (tmpModelElement.getVertIndexCount() > 0) {
            pg3D.textureMode(NORMALIZED);
            //println("face=" + f + " drawMode = " + objModel.getDrawMode());
            pg3D.beginShape(objModel.getDrawMode()); // specify render mode
            boolean useTexture = false;
            pg3D.texture(texture);
            
            boolean mirrorImage = true;
            for (int fp = 0;  fp < tmpModelElement.getVertIndexCount(); fp++) {
              v = objModel.getVertex(tmpModelElement.getVertexIndex(fp));
              // println("a"); //This is the line that gets execute
              if (v != null) {
                  float textureX = map(v.x,-224,-24,0,1);
                  float textureY;
                  if (mirrorImage) {
                    textureY = map(v.y,-1124,99,0,1);
                  } else {
                    textureY = map(v.y,-1124,99,0,0.5);
                  }
                    
                  float textureZ = map(v.z,47,844,1,0);
                  
                  pg3D.vertex(v.x, v.y, v.z, textureY, textureZ);
                  if (v.x < lowest.x)
                    lowest.x = v.x;
                  if (v.y < lowest.y)
                    lowest.y = v.y;
                  if (v.z < lowest.z)
                    lowest.z = v.z;
                  
                  if (v.x > highest.x)
                    highest.x = v.x;
                  if (v.y > highest.y)
                    highest.y = v.y;
                  if (v.z > highest.z)
                    highest.z = v.z;
              }
            }
            pg3D.endShape();
            
            //mirror image to have a 2 sided piece
            pg3D.beginShape(objModel.getDrawMode()); // specify render mode
            pg3D.texture(texture);
            
            for (int fp = 0;  fp < tmpModelElement.getVertIndexCount(); fp++) {
              v = objModel.getVertex(tmpModelElement.getVertexIndex(fp));
              // println("a"); //This is the line that gets execute
              if (v != null) {
                float textureX = map(v.x,-224,-24,0,1);
                float textureY;
                if (mirrorImage) {
                  textureY = map(v.y,-1124,99,0,1);
                } else {
                  textureY = map(v.y,-1124,99,0.5,1.0);
                }
                
                float textureZ = map(v.z,47,844,1,0);
                float x = v.x;
                float y = v.y;
                float z = v.z;
                
                x *= -1;
                x -= 51; 

                pg3D.vertex(x, y, z, textureY, textureZ);
              }
            }
            pg3D.endShape();
          }
        }
      }
     // println("lowest=" + lowest + " highest=" + highest);

    } catch (Exception e) {
      e.printStackTrace();
    }
  }


    
  void drawMappedOntoBottle(PGraphics pg) {
    
    // create image version of the 2d map
    PImage img = createImage(pg.width, pg.height, RGB);
    img.loadPixels();
    pg.loadPixels();
    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = pg.pixels[i];
    }
    img.updatePixels();
    pg.updatePixels();

    pg3D.beginDraw();
    pg3D.noStroke();
    colorMode(RGB,255);
    pg3D.background(color(6,25,41)); //dark blue color
    pg3D.lights();
        
    pg3D.pushMatrix();
    
//    float rX = map(mouseY, 0, height, -PI, PI);
//    float rY = map(mouseX, 0, width, -PI, PI);
    //println("rX = " + rX + " rY = " + rY);
    
    int fullRevolution = 30*5; //X seconds
    rotation = (rotation  + 1) % fullRevolution;
    float rX = PI/2;
    float rY = map(rotation, 0, fullRevolution, -PI, PI);
    
    pg3D.translate(pg3D.height * 0.5, pg3D.height * 2.2, pg3D.height * -4.2);
    
    pg3D.rotateY(rY);
    pg3D.rotateX(rX);
    
    pg3D.translate(pg3D.height * 0,pg3D.height * 1, pg3D.height * 0);
    
    drawModel(img);
    pg3D.popMatrix();
    pg3D.endDraw();
    
    // copy onto the display window
    pg3D.loadPixels();
    loadPixels();
    for (int x = 0; x < pg3D.width; x++) {
      for (int y = 0; y < pg3D.height; y++) {
        pixels[(y + box2d.y) * screenWidth + x + box3d.x] = pg3D.pixels[y * pg3D.width + x];
      }
    }
    updatePixels();
    pg3D.updatePixels(); // is it necessary to call updatePixels when nothing changed?
  }
  
  void drawToScreen() {
    colorMode(RGB,255);
    background(color(12,49,81)); //dark blue color
    PGraphics pg = drawFlat2DVersion();
    if (render3d) {
      drawMappedOntoBottle(pg);
    }
  }
  
//  void drawToLedWall() {
//    // r, g, b for 1,1 then 1,2; etc.    
//    int ti=0;
//    for (int y=ledHeight-1; y>=0; y--) {
//      int dx, x;
//      if (y%2 == 0) {
//        dx = -1;
//        x = ledWidth-1;
//      } else {
//        dx = 1;
//        x = 0;
//      }
//      
//      while (x >= 0 && x < ledWidth) {
//        byte[] rgb = new byte[3];
//        rgb[2] = (byte) constrain(pixelData[c(x,y)] & 0xFF, 0, MAX_RGB);
//        rgb[1] = (byte) constrain((pixelData[c(x,y)] >> 8) & 0xFF, 0, MAX_RGB);
//        rgb[0] = (byte) constrain((pixelData[c(x,y)] >> 16) & 0xFF, 0, MAX_RGB);
//        
//        for (int c=0; c<3; c++) {
//          if (ti%PACKET_SIZE == 0) {
//            int pktNum = floor(float(ti)/PACKET_SIZE);
//            txData[ti++] = byte(pktNum);
//          }
//          
//          txData[ti++] = rgb[c];
//        }
//
//        x += dx;
//      }
//    }        
//    
//    spw.send(txData);
//  }
  Rectangle getBox2D() {return box2d;}
  Rectangle getBox3D() {return box3d;}
  

////////////////////////////////////////////////////////////////////
//Total Control
  
  int TC_OK = 0;       /* Function completed successfully      */
  int TC_ERR_VALUE = 1;     /* Parameter out of range               */
  int TC_ERR_MALLOC = 2;    /* malloc() failure                     */
  int TC_ERR_OPEN = 3;      /* Could not open FTDI device           */
  int TC_ERR_WRITE = 4;     /* Error writing to FTDI device         */
  int TC_ERR_MODE = 5;      /* Could not enable async bit bang mode */
  int TC_ERR_DIVISOR = 6;   /* Could not set baud divisor           */
  int TC_ERR_BAUDRATE = 7;   /* Could not set baud rate              */
  
  int TC_PIXEL_UNUSED =       -1;     // Pixel is attached but not used
  int TC_PIXEL_DISCONNECTED = -2;     // Pixel is not attached to strand
  
  
  //convert coordinates into index into pixel array
  private int c(int x, int y) {
    return (y*ledWidth) + x;
  }

  int nStrands = 1;
  int pixelsPerStrand;
  int[] mapnum;
  
  boolean useTotalControl = true;
  
  void setupTotalControl()
  {
    // Maps the PHYSICAL string location to the pixel buffer location, which is precomputed with the width, eg: see the
    // "c" function just above.  Therefore, the total-control code doesn't need to know the width * height of the image.
    if (mapnum == null) {
      mapnum = new int[] {
        c(12, 5), c(11, 5), c(10, 5), c(9, 5), c(8, 5), c(7, 5), c(6, 5), c(5, 5), c(4, 5), c(3, 5), c(2, 5), c(1, 5),
        c(1, 4), c(2, 4), c(3, 4), c(4, 4), c(5, 4), c(6, 4), c(7, 4), c(8, 4), c(10, 4), c(11, 4), c(12, 4), c(13, 4),
        c(12, 3), c(11, 3), c(10, 3), c(9, 3), c(8, 3), c(7, 3), c(6, 3), TC_PIXEL_UNUSED, c(5, 3), c(4, 3), c(3, 3), c(2, 1), c(1, 3),
        c(1, 2), c(2, 2), c(3, 2), c(4, 2), c(5, 2), c(6, 2), c(8, 2), c(9, 2), c(10, 2), c(11, 2), c(13, 2),
        c(12, 1), c(11, 1), c(10, 1), c(8, 1), c(7, 1), c(6, 1), c(4, 1), c(3, 1), c(2, 1), c(1, 1), TC_PIXEL_DISCONNECTED, c(0, 1),
        c(1, 0), c(2, 0), c(3, 0), c(4, 0), c(5, 0), c(7, 0), c(9, 0), c(10, 0), c(12, 0)
      };
      
    }
    
    pixelsPerStrand = mapnum.length;
    
    int status = tc.open(nStrands, pixelsPerStrand);
    if(status != 0) {
      tc.printError(status);
      useTotalControl = false;
    }
    
  }
  
  // This function loads the screen-buffer and sends it to the TotalControl
  void drawToLeds() {
    
    if (!useTotalControl) {
      return;
    }
    
//    for (int x=0; x<ledWidth; x++) {
//      for (int y=0; y<ledHeight; y++) {
//        color pixelColor = pixelData[c(x,y)];
//      }
//    }
    tc.refresh(pixelData, mapnum);
    tc.printStats();
  }
  
}

