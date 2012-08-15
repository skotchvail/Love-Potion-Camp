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
    
    setupTotalControl();
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
  
  void drawToScreen() {
    if (!draw2dGrid && !draw3dSimulation)
      return;
    colorMode(RGB,255);
    background(color(12,49,81)); //dark blue color
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

  
  final int TC_OK = 0;       /* Function completed successfully      */
  final int TC_ERR_VALUE = 1;     /* Parameter out of range               */
  final int TC_ERR_MALLOC = 2;    /* malloc() failure                     */
  final int TC_ERR_OPEN = 3;      /* Could not open FTDI device           */
  final int TC_ERR_WRITE = 4;     /* Error writing to FTDI device         */
  final int TC_ERR_MODE = 5;      /* Could not enable async bit bang mode */
  final int TC_ERR_DIVISOR = 6;   /* Could not set baud divisor           */
  final int TC_ERR_BAUDRATE = 7;   /* Could not set baud rate              */
  
  final int TC_PIXEL_UNUSED =       -1;     // Pixel is attached but not used
  final int TC_PIXEL_DISCONNECTED = -2;     // Pixel is not attached to strand
  final int TC_PIXEL_UNDEFINED =    -3;     // Pixel not yet assigned a value
  
  final int kNumStrands = 1;
  final int kPixelsPerStrand = 897;
  private int[] strandMap = new int[kNumStrands * kPixelsPerStrand];
  private int[] trainingStrandMap = new int[kNumStrands * kPixelsPerStrand];
  
  boolean useTotalControl = true;
  boolean useTrainingMode = false;
     
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
  
  String ledMapDump1() {
    StringBuffer s = new StringBuffer();

    s.append("\n..   ");
    
    for (int t = 0; t < kPixelsPerStrand; t++) {
      s.append(String.format("%02d      ",t));
    }
    for (int whichStrand = 0; whichStrand < kNumStrands; whichStrand++) {
      s.append(String.format("\ns%d: ",whichStrand));
      int start = whichStrand  * kPixelsPerStrand;
      for (int index = start; index < start + kPixelsPerStrand; index++) {
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
    }
    s.append("\n");
    return s.toString();
  }

  String ledMapDump() {
    StringBuffer s = new StringBuffer();
    
    for (int whichStrand = 0; whichStrand < kNumStrands; whichStrand++) {
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
    }
    s.append("\n");
    return s.toString();
  }

  TotalControlConcurrent totalControlConcurrent;

  void setupTotalControl()
  {
    
    /*
     
     layout from coordinate POV:
     
     ..    00      01      02      03      04      05      06      07      08      09      10
     00    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
     01    2:00    2:01    2:02    2:03    xx      xx      xx      xx      xx      xx      xx
     02    1:02    1:01    1:00    2:04    2:05    xx      xx      xx      xx      xx      xx
     03    1:03    1:04    1:05    1:06    2:06    xx      xx      xx      xx      xx      xx
     04    1:10    1:09    1:08    1:07    0:08    0:07    xx      xx      xx      xx      xx
     05    0:00    0:01    0:02    0:04    0:05    0:06    xx      xx      xx      xx      xx

     layout from strand POV:
     ..   00      01      02      03      04      05      06      07      08      09      10      11      12      13      14
     sA: (00,05) (01,05) (02,05)  UNUSED (03,05) (04,05) (05,05) (05,04) (04,04) DISC  DISC    DISC    DISC    DISC    DISC
     sB  (02,02) (01,02) (00,02) (00,03) (01,03) (02,03) (03,03) (03,04) (02,04) (01,04) (00,04)  DISC    DISC    DISC    DISC
     sC  (00,01) (01,01) (02,01) (03,01) (03,02) (04,02) (04,03)  DISC    DISC    DISC    DISC    DISC    DISC    DISC    DISC
 
     desired layout from strand before interpolation:
     
     ..   00      01      02      03      04      05      06      07      08      09      10      11      12      13      14
     sA: (??,??) (??,??) (02,05)  UNUSED (??,??) (??,??) (05,05) (05,04) (04,04)  DISC    DISC    DISC    DISC    DISC    DISC
     sB  (02,02) (00,04) (00,02) (00,03) (??,??) (??,??) (03,03) (03,04) (??,??) (??,??) (??,??)  DISC    DISC    DISC    DISC
     sC  (00,01) (??,??) (??,??) (03,01) (03,02) (04,02) (04,03)  DISC    DISC    DISC    DISC    DISC    DISC    DISC    DISC
     
     
     actual calculation:
     
     ..   00      01      02      03      04      05      06      07      08      09      10      11      12      13      14
     s0: (??,??) (??,??) (02,05)  UNUSED (03,05) (04,05) (05,05) (05,04) (04,04)  DISC    DISC    DISC    DISC    DISC    DISC
     s1: (02,02) (00,04) (00,02) (00,03) (01,03) (02,03) (03,03) (03,04) (02,04) (01,04) (00,04)  DISC    DISC    DISC    DISC
     s2: (00,01) (01,01) (02,01) (03,01) (03,02) (04,02) (04,03)  DISC    DISC    DISC    DISC    DISC    DISC    DISC    DISC
     
     
     
     000:(09,04)  001:(08,04)  002:(07,04)  003:(06,04)  004: UNUSED  005:(04,04)  006:(??,??)  007:(04,03)  008:(??,??)  009:(??,??)
     010:(??,??)  011:(??,??)  012:(??,??)  013:(??,??)  014:(??,??)  015:(11,03)  016:(??,??)  017:(11,02)  018:(10,02)  019:(09,02)
     020:(08,02)  021:(07,02)  022:(06,02)  023:(05,02)  024: UNUSED  025:(05,01)  026:(??,??)  027:(??,??)  028:(??,??)  029:(10,01)
     030: UNUSED  031:(09,00)  032:(08,00)  033:(07,00)  034:(06,00)  035:(05,00)  036:(04,00)  037:(03,00)  038:(02,00)  039:(01,00)
     040:(00,00)  041:(??,??)  042:(??,??)  043:(??,??)  044:(??,??)  045:(??,??)  046:(??,??)  047:(??,??)  048:(??,??)  049:(??,??)
     
     
     */

    final int sA = 0;
    final int sB = 1;
    final int sC = 2;
    final int sD = 3;
    
    initStrand(sA,897);
    
  ledMissing(sA, 0);
  ledSet(sA, 1, 0, 25);
  ledSet(sA, 10, 0, 16);
  ledSet(sA, 11, 1, 16);
  ledSet(sA, 20, 1, 25);
  ledSet(sA, 21, 2, 25);
  ledSet(sA, 33, 2, 13);
  ledSet(sA, 34, 3, 13);
  ledSet(sA, 46, 3, 25);
  ledSet(sA, 47, 4, 25);
  ledSet(sA, 65, 4, 7);
  ledSet(sA, 66, 5, 7);
  ledSet(sA, 84, 5, 25);
  ledSet(sA, 85, 6, 25);
  ledSet(sA, 102, 6, 8);
  ledSet(sA, 103, 7, 8);
  ledSet(sA, 120, 7, 25);
  ledSet(sA, 121, 8, 25);
  ledSet(sA, 129, 8, 17);
  ledSet(sA, 130, 9, 17);
  ledSet(sA, 138, 9, 25);
  ledSet(sA, 139, 10, 25);
  ledSet(sA, 148, 10, 16);
  ledSet(sA, 149, 11, 16);
  ledSet(sA, 158, 11, 25);
  ledSet(sA, 159, 12, 25);
  ledSet(sA, 169, 12, 15);
  ledSet(sA, 170, 13, 15);
  ledSet(sA, 180, 13, 25);
  ledSet(sA, 181, 14, 25);
  ledSet(sA, 193, 14, 13);
  ledSet(sA, 194, 15, 13);
  ledSet(sA, 198, 15, 17);
  ledMissing(sA, 199);
  ledSet(sA, 200, 15, 18);
  ledSet(sA, 206, 15, 24);
  ledSet(sA, 207, 16, 24);
  ledSet(sA, 219, 16, 12);
  ledSet(sA, 220, 17, 12);
  ledSet(sA, 232, 17, 24);
  ledSet(sA, 233, 18, 24);
  ledSet(sA, 247, 18, 10);
  ledSet(sA, 248, 19, 10);
  ledSet(sA, 262, 19, 24);
  ledSet(sA, 263, 20, 24);
  ledSet(sA, 277, 20, 10);
  ledSet(sA, 278, 21, 10);
  ledSet(sA, 292, 21, 24);
  ledSet(sA, 293, 22, 24);
  ledSet(sA, 307, 22, 10);
  ledSet(sA, 308, 23, 10);
  ledSet(sA, 321, 23, 23);
  ledSet(sA, 322, 24, 23);
  ledSet(sA, 335, 24, 10);
  ledSet(sA, 336, 25, 10);
  ledSet(sA, 349, 25, 23);
  ledSet(sA, 350, 26, 23);
  ledSet(sA, 363, 26, 10);
  ledSet(sA, 364, 27, 10);
  ledSet(sA, 377, 27, 23);
  ledSet(sA, 378, 28, 23);
  ledSet(sA, 389, 28, 12);
  ledSet(sA, 390, 29, 12);
  ledSet(sA, 400, 29, 22);
  ledSet(sA, 401, 30, 22);
  ledSet(sA, 410, 30, 13);
  ledSet(sA, 411, 31, 13);
  ledSet(sA, 420, 31, 22);
  ledSet(sA, 421, 32, 22);
  ledSet(sA, 432, 32, 11);
  ledSet(sA, 433, 33, 11);
  ledSet(sA, 444, 33, 22);
  ledSet(sA, 445, 34, 22);
  ledSet(sA, 457, 34, 10);
  ledSet(sA, 458, 35, 10);
  ledSet(sA, 470, 35, 22);
  ledSet(sA, 471, 36, 22);
  ledSet(sA, 483, 36, 10);
  ledSet(sA, 484, 37, 10);
  ledSet(sA, 496, 37, 22);
  ledSet(sA, 497, 38, 22);
  ledSet(sA, 509, 38, 10);
  ledSet(sA, 510, 39, 10);
  ledSet(sA, 522, 39, 22);
  ledSet(sA, 523, 40, 22);
  ledSet(sA, 532, 40, 13);
  ledSet(sA, 533, 41, 13);
  ledSet(sA, 542, 41, 22);
  ledSet(sA, 543, 42, 22);
  ledSet(sA, 552, 42, 13);
  ledSet(sA, 553, 43, 13);
  ledSet(sA, 562, 43, 22);
  ledSet(sA, 563, 44, 22);
  ledSet(sA, 571, 44, 14);
  ledSet(sA, 572, 45, 14);
  ledSet(sA, 580, 45, 22);
  ledSet(sA, 581, 46, 22);
  ledSet(sA, 589, 46, 14);
  ledSet(sA, 590, 47, 14);
  ledSet(sA, 598, 47, 22);
  ledSet(sA, 599, 48, 22);
  ledSet(sA, 608, 48, 13);
  ledSet(sA, 609, 49, 13);
  ledSet(sA, 620, 49, 24);
  ledSet(sA, 621, 50, 24);
  ledSet(sA, 645, 50, 0);
  ledSet(sA, 646, 51, 0);
  ledSet(sA, 669, 51, 23);
  ledSet(sA, 670, 52, 23);
  ledSet(sA, 692, 52, 1);
  ledSet(sA, 693, 53, 1);
  ledSet(sA, 714, 53, 22);
  ledSet(sA, 715, 54, 22);
  ledSet(sA, 734, 54, 3);
  ledSet(sA, 735, 55, 3);
  ledSet(sA, 746, 55, 14);
  ledMissing(sA, 747);
  ledSet(sA, 748, 55, 15);
  ledSet(sA, 754, 55, 21);
  ledSet(sA, 755, 56, 21);
  ledSet(sA, 772, 56, 4);
  ledSet(sA, 773, 57, 4);
  ledSet(sA, 791, 57, 22);
  ledSet(sA, 792, 58, 22);
  ledSet(sA, 809, 58, 5);
  ledSet(sA, 810, 59, 5);
  ledSet(sA, 829, 59, 24);
  ledSet(sA, 830, 60, 24);
  ledSet(sA, 848, 60, 6);
  ledSet(sA, 849, 61, 6);
  ledSet(sA, 866, 61, 23);
  ledSet(sA, 867, 62, 23);
  ledSet(sA, 882, 62, 8);
  ledSet(sA, 883, 63, 8);
  ledSet(sA, 896, 63, 21);


//    int extraY = 20;    
    
//    ledMissing(sA,149);
//    ledMissing(sA,148);
//
//    ledSet(sA,147,  0,0);
//    ledSet(sA,133,  0,14);
//
//    ledMissing(sA,132);
//
//    
//    ledSet(sA,131,  1,14);
//    ledSet(sA,117,  1,0);
//    ledSet(sA,103,  2,0);
//    ledSet(sA,89,   2,14);
//    ledMissing(sA, 88);
//    ledSet(sA,87,   3,14);
//    ledSet(sA,77,   3,4);
//    ledMissing(sA,76);
//    ledSet(sA,75,   4,4);
//    ledSet(sA,65,   4,14);
//    ledMissing(sA,64);
//    ledMissing(sA,53);
//    ledSet(sA,63,   5,14);
//    ledSet(sA,54,   5,5);
//    ledSet(sA,52,   6,6);
//    ledSet(sA,44,   6,14);
//    ledMissing(sA,43);
//
//    ledSet(sA,42,   7,14);
//    ledSet(sA,33,   7,5);
//    ledMissing(sA,32);
//    ledMissing(sA,31);
//    ledMissing(sA,30);
//    ledMissing(sA,29);
//    ledMissing(sA,28);
//    ledMissing(sA,27);
//    ledMissing(sA,26);
//    ledMissing(sA,25);
//    ledMissing(sA,24);
//    ledMissing(sA,23);
//    ledMissing(sA,22);
//    ledMissing(sA,21);
//    ledMissing(sA,20);
//    ledMissing(sA,19);
//    ledMissing(sA,18);
//    ledMissing(sA,17);
//    ledMissing(sA,16);
//    ledMissing(sA,15);
//    ledMissing(sA,14);
//    ledMissing(sA,13);
//    ledMissing(sA,12);
//    ledMissing(sA,11);
//
//    ledSet(sA,10,   8,4);
//    ledSet(sA,0,    8,14);
     
    ledInterpolate();
    println(ledMapDump());
    
    if (useTotalControl) {
      totalControlConcurrent = new TotalControlConcurrent(kNumStrands,kPixelsPerStrand);
      if (totalControlConcurrent.getLastError() != 0) {
       // useTotalControl = false;
        println("turning off Total Control because of error during initialization");
      }
    }
  }
  
  // This function loads the screen-buffer and sends it to the TotalControl p9813 driver
  void drawToLeds() {
    if (!useTotalControl) {
      return;
    }
    //totalControlConcurrent.put(pixelData, useTrainingMode?trainingStrandMap:strandMap);
    int status = TotalControl.refresh(pixelData, strandMap);
  }
}

