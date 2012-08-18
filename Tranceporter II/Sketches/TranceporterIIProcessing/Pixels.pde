// Class to abstract out interfacing with the microcontroller (which in turn sends signals to the wall) and
// to the processing display.

import saito.objloader.*;
import java.awt.Rectangle;

int PACKET_SIZE = 100;
int LOC_BYTES = 1; // how many bytes to use to store the index at the beginning of each packet
int MAX_RGB = 255;

class Pixels {
  private color[] pixelData;
  private int rotation = 0;
  private OBJModel objModel;
  private PGraphics pg3D;

  private Rectangle box2d, box3d;
  
  
  Pixels(PApplet p) {
    box2d = new Rectangle(10, 10, ledWidth * screenPixelSize, ledHeight * screenPixelSize);
    box3d = new Rectangle(box2d.x * 2 + box2d.width,box2d.y,360,300);
    pixelData = new color[ledWidth * ledHeight];
    pg3D = createGraphics(box3d.width, box3d.height, P3D);
    
    objModel = new OBJModel(p, "tranceporter.obj");
    // turning on the debug output (it's all the stuff that spews out in the black box down the bottom)
    objModel.enableDebug();
    
    objModel.scale(3);
    
    //noStroke();
//    println("drawModes POINTS=" + POINTS + " LINES=" + LINES + " TRIANGLES=" + TRIANGLES + " TRIANGLE_FAN=" + TRIANGLE_FAN
//            + " TRIANGLE_STRIP=" + TRIANGLE_STRIP + " QUADS=" + QUADS + " QUAD_STRIP=" + QUAD_STRIP);
    
    initTotalControl();
  }

  void setPixel(int x, int y, color c) {
    pixelData[c2i(x,y)] = c;
  }

  void setAll(color c) {
    for (int x=0; x<ledWidth; x++) {
      for (int y=0; y<ledHeight; y++) {
        setPixel(x, y, c);
      }
    }
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
        color pixelColor = pixelData[c2i(x,y)];
        pg.fill(pixelColor);
        pg.rect(x*screenPixelSize,y*screenPixelSize, screenPixelSize, screenPixelSize);
      }
    }
    pg.filter(BLUR, 2.5);
    pg.endDraw();
    
    if (!draw2dGrid)
      return pg;
    
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
    
    int fullRevolution = FRAME_RATE * 60; //X seconds
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

  boolean wasDrawing2D = true;
  boolean wasDrawing3D = true;
  
  void drawToScreen() {
    colorMode(RGB,255);
    
    if (wasDrawing2D || wasDrawing3D || draw2dGrid || draw3dSimulation) {
      background(color(12,49,81)); //dark blue color
    }
    
    wasDrawing2D = draw2dGrid;
    wasDrawing3D = draw3dSimulation;
    
    if (!draw2dGrid && !draw3dSimulation) {
      return;
    }
    
    PGraphics pg = drawFlat2DVersion();
    if (draw3dSimulation) {
      drawMappedOntoBottle(pg);
    }
  }
  
  Rectangle getBox2D() {return box2d;}
  Rectangle getBox3D() {return box3d;}
  

////////////////////////////////////////////////////////////////////
//Total Control
  
  /*
   spreadsheet
   
   for each led:
   which strand, offset x, y, which shape
   
   strand1:
   1: 3, 10, shapeA
   2: 16, 10, shapeA
   3: 55, 9, shapeB
   4: unused
   3: 59, 49, shapeB
   
   strand2:
   1: 77, 14, shapeA
   2: 46, 98, shapeA
   3: 3, 12, shapeB
   
   */

  
  /*
   ..    00      01      02      03      04      05      06      07      08      09      10
   00    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   01    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   02    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   03    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   04    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   05    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   
   ..   00      01      02      03      04      05      06      07      08      09      10      11      12      13      14
   sA: (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00)
   sB  (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00)
   sC  (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00)
   
   
   */

  

  
  final boolean kUseBitBang = true;
  final int kNumStrands = 8;
  final int kPixelsPerStrand = 50; //1300; //897;
  private int[] strandMap = new int[kNumStrands * kPixelsPerStrand];
  private int[] trainingStrandMap = new int[kNumStrands * kPixelsPerStrand];
  final boolean runConcurrent = true;
  boolean useTotalControl = true;

  
  boolean useTrainingMode = true;
     
  //convert coordinates into index into pixel array index
  private int c2i(int x, int y) {
    return (y*ledWidth) + x;
  }
  
  private Point i2c(int index) {
    Point p = new Point();
    p.y = index / ledWidth;
    p.x = index % ledWidth;
    return p;
  }
  
  void initStrand(int whichStrand, int numPixels) {
    int start = whichStrand * kPixelsPerStrand;
    int boundary = start + numPixels;
    int j;
    for (j = start; j < boundary; j++) {
      strandMap[j] = TC_PIXEL_UNDEFINED;
      trainingStrandMap[j] = j;
      
    }
    int end = start + kPixelsPerStrand;
    for (; j < end; j++) {
      strandMap[j] = TC_PIXEL_DISCONNECTED;
      trainingStrandMap[j] = TC_PIXEL_DISCONNECTED;
    }
  }

  void ledSetValue(int whichStrand, int ordinal, int value) {
    assert(whichStrand < kNumStrands) : "not this many strands";
    assert(ordinal < kPixelsPerStrand) : "whichStrand exceeds number of leds per strand";
    int index = (whichStrand * kPixelsPerStrand) + ordinal;
    assert(strandMap[index] == TC_PIXEL_UNDEFINED) : "led " + ordinal + " on strand " + whichStrand + " is already defined: " + strandMap[index];
    strandMap[index] = value;
  }
  
  void ledMissing(int whichStrand, int ordinal) {
    ledSetValue(whichStrand, ordinal, TC_PIXEL_UNUSED);
  }
  
  void ledSet(int whichStrand, int ordinal, int x, int y) {
//    ledSetValue(whichStrand, ordinal, c2i(x,y+20));
      ledSetValue(whichStrand, ordinal, c2i(x,y));
  }
  
  Point ledGet(int whichStrand, int ordinal) {
    int[] map = useTrainingMode?trainingStrandMap:strandMap;
    
    int index = (whichStrand * kPixelsPerStrand) + ordinal;
    int value = map[index];
    if (value < 0) {
      return new Point(-1,-1);
    }
    return i2c(value);
  }
  
  void ledInterpolate() {
    
    int available = 0;
    
    for (int strand = 0; strand < kNumStrands; strand++) {
      int start = strand * kPixelsPerStrand;
      int lastIndexWithCoord = -1;
      available = 0;
      for (int i = start; i < start + kPixelsPerStrand; i++) {
        int value = strandMap[i];
        if (value == TC_PIXEL_UNDEFINED) {
          available++;
        }
        else if (value >= 0) {
          
          if (lastIndexWithCoord < 0) {
            
          }
          else {
            Point a = i2c(strandMap[lastIndexWithCoord]);
            Point b = i2c(value);
            int writable = abs(b.y - a.y) + abs(b.x - a.x) - 1;
            //println ("writable(" + writable + ") = abs(" + b.y + " - " + a.y + ") + abs(" + b.x + " - " + a.x + ")");
            
//            for (int k = lastIndexWithCoord + 1; k < i; k++) {
//              if (strandMap[k] == TC_PIXEL_UNDEFINED)
//                strandMap[k] = c2i(11,writable);
//            }
            if (writable == available) {
              if (!(a.x != b.x && a.y != b.y)) {
                
                int xChange = 0;
                int yChange = 0;
                if (b.x > a.x)
                  xChange = 1;
                else if (b.x < a.x)
                  xChange = -1;
                if (b.y > a.y)
                  yChange = 1;
                else if (b.y < a.y)
                  yChange = -1;

                int inc = 0;
                for (int j = lastIndexWithCoord + 1; j < i; j++) {
                  int jVal = strandMap[j];
                  if (jVal == TC_PIXEL_UNDEFINED) {
                    inc++;
                    int x = a.x + inc * xChange;
                    int y = a.y + inc * yChange;
                    strandMap[j] = c2i(x,y);
                    
                  }
                }
              }
            }
          }
          lastIndexWithCoord = i;
          available = 0;
        }
      }
    }
  }
  
  /*
   
   
   
   
   ..   00      01      02      03      04      05      06      07      08      09      10      11      12      13      14
   s0: (??,??) (??,??) (02,05)  UNUSED (11,04) (11,04) (05,05) (05,04) (11,02) (01,04)  DISC    DISC    DISC    DISC    DISC
   s1: (02,02) (00,04) (00,02) (00,03) (11,03) (11,03) (03,03) (03,04) (??,??) (??,??) (??,??)  DISC    DISC    DISC    DISC
   s2: (00,01) (11,03) (11,03) (03,01) (03,02) (04,02) (04,03)  DISC    DISC    DISC    DISC    DISC    DISC    DISC    DISC
   
   
   writable(4) = abs(0 - 0) + abs(6 - 2)
   writable(1) = abs(0 - 0) + abs(7 - 6)
   writable(2) = abs(0 - 0) + abs(9 - 7)
   writable(1) = abs(0 - 0) + abs(16 - 15)
   writable(1) = abs(0 - 0) + abs(17 - 16)
   writable(1) = abs(0 - 0) + abs(18 - 17)
   writable(3) = abs(0 - 0) + abs(21 - 18)
   writable(1) = abs(0 - 0) + abs(22 - 21)
   writable(3) = abs(0 - 0) + abs(33 - 30)
   writable(1) = abs(0 - 0) + abs(34 - 33)
   writable(1) = abs(0 - 0) + abs(35 - 34)
   writable(1) = abs(0 - 0) + abs(36 - 35)
   
   
   

   */
  
  void ledMapDump(int minStrand, int maxStrand) {
    if (maxStrand < minStrand) {
      return;
    }
    assert(minStrand < kNumStrands);
    assert(maxStrand <= kNumStrands);

    
    for (int whichStrand = minStrand; whichStrand <= maxStrand; whichStrand++) {
      StringBuffer s = new StringBuffer(kPixelsPerStrand * 12);
      
      int start = whichStrand  * kPixelsPerStrand;
      for (int ordinal = 0; ordinal < kPixelsPerStrand; ordinal++) {
        int index = ordinal + start;
        if ((ordinal % 10) == 0)
          s.append("\n");
        s.append(String.format(" %03d:",ordinal));
        int value = strandMap[index];
        if (value == TC_PIXEL_DISCONNECTED) {
          s.append(" DISC   ");
        } else if (value == TC_PIXEL_UNUSED) {
          s.append(" UNUSED ");
        } else if (value == TC_PIXEL_UNDEFINED) {
          s.append("(??,??) ");
        }
        else {
          assert (value >= 0) : "can't print unrecognized value " + value;
          Point p = i2c(value);
          s.append(String.format("(%02d,%02d) ",p.x,p.y));
        }
        
      }
      
      s.append("\n");
      println(s);

    }
    
  }

  void mapAllLeds() {
    
  }

  
  TotalControlConcurrent totalControlConcurrent;

  void initTotalControl()
  {
    if (!useTotalControl) {
      return;
    }
    
    for (int i = 0; i < kNumStrands; i++) {
      initStrand(i,kPixelsPerStrand);
    }
    
    mapAllLeds();

     
    ledInterpolate();
//    ledMapDump(0,0); //set which strands you want to dump
    
    if (runConcurrent) {
      totalControlConcurrent = new TotalControlConcurrent(kNumStrands,kPixelsPerStrand, kUseBitBang);
    }
    else {
      int status = setupTotalControl(kNumStrands, kPixelsPerStrand, kUseBitBang);
      if (status != 0) {
        //useTotalControl = false;
        //println("turning off Total Control because of error during initialization");
      }
      
    }
  }
  
  // This function loads the screen-buffer and sends it to the TotalControl p9813 driver
  void drawToLeds() {
    if (!useTotalControl) {
      return;
    }
    int[] theStrandMap = useTrainingMode?trainingStrandMap:strandMap;

    //println("sending pixelData: " + pixelData.length + " strandMap: " + theStrandMap.length);
    if (runConcurrent) {
      totalControlConcurrent.put(pixelData, theStrandMap);
    }
    else {
      int status = writeOneFrame(pixelData, theStrandMap);
    }
  }
}

