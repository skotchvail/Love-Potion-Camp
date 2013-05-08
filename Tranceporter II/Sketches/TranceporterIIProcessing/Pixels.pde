// Class to abstract out interfacing with the microcontroller (which in turn sends signals to the wall) and
// to the processing display.

import saito.objloader.*;
import java.awt.Rectangle;

int PACKET_SIZE = 100;
int LOC_BYTES = 1; // how many bytes to use to store the index at the beginning of each packet
int MAX_RGB = 255;

class Pixels {
  private color[] pixelData, maskPixels;
  private OBJModel objModel;
  private PGraphics pg3D;
  
  private Rectangle box2d, box3d;
  
  int maxPixelsPerStrand;
  final boolean kUseBitBang = true;
  private int[] strandMap;
  private int[] trainingStrandMap;
  final boolean runConcurrent = true;
  private float rotation = 0.8;
  
  Pixels(PApplet p) {
    objModel = new OBJModel(p, "tranceporter.obj");
    // turning on the debug output (it's all the stuff that spews out in the black box down the bottom)
    objModel.enableDebug();
    objModel.scale(3);
  }
  
  void setup() {
    int totalPixels = 0;
    maxPixelsPerStrand = 0;
    for (int i = 0; i < getNumStrands(); i++) {
      int strandSize = getStrandSize(i);
      if (strandSize > maxPixelsPerStrand) {
        maxPixelsPerStrand = strandSize;
      }
      totalPixels += strandSize;
    }
    
    int pixelDataSize = max(totalPixels, ledWidth * ledHeight);
    pixelData = new color[pixelDataSize];
    
    box2d = new Rectangle(10, 10, ledWidth * screenPixelSize, ledHeight * screenPixelSize);
    box3d = new Rectangle(box2d.x * 2 + box2d.width, box2d.y, 360, 180);
    pg3D = createGraphics(box3d.width, box3d.height, P3D);
    
    strandMap = new int[getNumStrands() * maxPixelsPerStrand];
    trainingStrandMap = new int[getNumStrands() * maxPixelsPerStrand];
    
    initTotalControl();
  }
  
  void copyPixels(int[] pixels, DrawType drawType) {
    final int halfWidth = ledWidth / 2;

    if (drawType == DrawType.MirrorSides) {
      // Image is mirrored
      for (int y = 0; y < ledHeight; y++) {
        final int baseY = y * halfWidth;
        final int baseYData = y * ledWidth;
        for (int x = 0; x < halfWidth; x++) {
          color pixel = pixels[baseY + x];
          pixelData[baseYData + x] = pixel;
          pixelData[baseYData + (ledWidth - x - 1)] = pixel;
        }
      }
    }
    else if (drawType == DrawType.RepeatingSides) {
      // Image is repeated
      for (int y = 0; y < ledHeight; y++) {
        final int baseY = y * halfWidth;
        final int baseYData = y * ledWidth;
        for (int x = 0; x < halfWidth; x++) {
          color pixel = pixels[baseY + x];
          pixelData[baseYData + x] = pixel;
          pixelData[baseYData + x + halfWidth] = pixel;
        }
      }
    }
    else if (drawType == DrawType.TwoSides) {
      arrayCopy(pixels, 0, pixelData, 0, pixels.length);
    }
    else {
      assert false : "unknown drawType = " + drawType;
    }
  }
  
  void forceUpdateMaskPixels() {
    maskPixels = null;
  }

  void updateMaskPixels() {
    color white = color(255);
    if (maskPixels == null) {
      // Mask out any pixels that are not mapped
      maskPixels = new color[ledWidth * ledHeight];
      
      for (int whichStrand = 0; whichStrand < getNumStrands(); whichStrand++) {
        final boolean portSide = isStrandPortSide(whichStrand);
        for (Point point: pointsForStrand(whichStrand)) {
          if (portSide) {
            maskPixels[point.y * ledWidth + point.x] = white;
          }
          else {
            maskPixels[point.y * ledWidth + (ledWidth - point.x - 1)] = white;
          }
        }
      }
    }
  }
    
  PGraphics drawFlat2DVersion() {
    boolean trainingMode = main.currentMode().isTrainingMode();
    updateMaskPixels();
    
    PImage image = createImage(ledWidth, ledHeight, RGB);
    arrayCopy(pixelData, image.pixels, image.pixels.length);
    image.updatePixels();
    if (!trainingMode) {
      image.mask(maskPixels);
    }
    
    // Render into offscreen buffer so that we can blur it, and then copy it
    // onto the display window
    PGraphics result = createGraphics(box2d.width, box2d.height, JAVA2D);
    result.beginDraw();
    {
      result.image(image, 0, 0, result.width, result.height);
      if (!trainingMode) {
        result.filter(BLUR, 2.5);
      }
    }
    result.endDraw();
    
    if (!draw2dGrid)
      return result;
    
    // Copy onto the display window
    image(result, box2d.x, box2d.y);
    return result;
  }
  
  void drawModel(PImage texture) {
    try {
      PVector v = null, vt = null, vn = null;
      boolean calcLowest = false;
      // Lowest and highest values were discovered empirically using calcLowest
      final float lowestY = -1123.7638, highestY = 98.722984;
      final float lowestZ = 47.52061, highestZ = 843.26636;
      final float diffY = highestY - lowestY;
      final float diffZ = highestZ - lowestZ;
      
      PVector lowest = new PVector(Float.MAX_VALUE, Float.MAX_VALUE, Float.MAX_VALUE);
      PVector highest = new PVector(-Float.MAX_VALUE, -Float.MAX_VALUE, -Float.MAX_VALUE);
      
      pg3D.textureMode(NORMAL);
      pg3D.fillColor = color(100, 0, 0);
      
      // render all triangles
      for (int s = 0; s < objModel.getSegmentCount(); s++) {
        Segment tmpModelSegment = objModel.getSegment(s);
        for (int f = 0; f < tmpModelSegment.getFaceCount(); f++) {
          Face tmpModelElement = (tmpModelSegment.getFace(f));
          if (tmpModelElement.getVertIndexCount() > 0) {
            
            for (int side = 0; side < 2; side++) {
              final boolean portSide = (side == 0);
              pg3D.beginShape(objModel.getDrawMode()); // specify render mode
              boolean hasTexture = false;
              
              for (int fp = 0;  fp < tmpModelElement.getVertIndexCount(); fp++) {
                v = objModel.getVertex(tmpModelElement.getVertexIndex(fp));
                if (v != null) {
                  
                  float textureU;
                  if (portSide) {
                    textureU = map(v.y, lowestY + diffY * factorLowU, highestY - diffY * factorHighU, 0.0, 0.5);
                  }
                  else {
                    textureU = map(v.y, lowestY + diffY * factorLowU, highestY - diffY * factorHighU, 1.0, 0.5);
                  }
                  float textureV = map(v.z, lowestZ + diffZ * factorLowV, highestZ - diffZ * factorHighV, 1.0, 0.0);
                  
                  if ((fp == 0 && textureU >= 0.0 && textureU <= 1.0)) {
                    pg3D.texture(texture);
                    hasTexture = true;
                  }
                  float x = v.x;
                  if (!portSide) {
                    x *= -1;
                    x -= 51;
                  }
                  if (hasTexture) {
                    pg3D.vertex(x, v.y, v.z, textureU, textureV);
                  }
                  else {
                    pg3D.vertex(x, v.y, v.z);
                  }
                  
                  if (calcLowest) {
                    if (portSide) {
                      lowest.x = min(v.x, lowest.x);
                      lowest.y = min(v.y, lowest.y);
                      lowest.z = min(v.z, lowest.z);
                      
                      highest.x = max(v.x, highest.x);
                      highest.y = max(v.y, highest.y);
                      highest.z = max(v.z, highest.z);
                    }
                  }
                  else {
                    assert(v.y >= lowestY);
                    assert(v.y <= highestY);
                    assert(v.z >= lowestZ);
                    assert(v.z <= highestZ);
                  }
                }
              }
              pg3D.endShape();
            }
          }
        }
      }
      if (calcLowest) {
        println("lowest=" + lowest + " highest=" + highest);
      }
      
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
  
  void drawMappedOntoBottle(PGraphics flatImage) {
    pg3D.beginDraw();
    pg3D.noStroke();
    colorMode(RGB, 255);
    pg3D.background(color(6, 25, 41)); //dark blue color
    pg3D.lights();
    
    float magicNum = 300; // Not sure how this affects the drawing, but it can be adjusted to make the field of view seem closer or further
    float maxZ = 10000;
    float fov = PI/3.9;
    float cameraZ = (box3d.height/2.0) / tan(fov/2.0);
    pg3D.perspective(fov, float(box3d.width)/float(box3d.height),
                     cameraZ/maxZ, cameraZ*maxZ);
    
    pg3D.pushMatrix();
    
    rotation = (rotation + rotationSpeed) % 1.0;
    float rX = PI/2;
    float rY = map(rotation, 0, 1.0, -PI, PI);
    
    pg3D.translate(magicNum * 0.5, magicNum * 2.2, magicNum * -4.2);
    
    pg3D.rotateY(rY);
    pg3D.rotateX(rX);
    
    pg3D.translate(magicNum * 0, magicNum * 1, magicNum * 0);
    
    drawModel(flatImage);
    pg3D.popMatrix();
    pg3D.endDraw();
    
    // copy onto the display window
    image(pg3D, box3d.x, box2d.y);
  }
  
  boolean wasDrawing2D = true;
  boolean wasDrawing3D = true;
  
  void drawToScreen() {
    colorMode(RGB, 255);
    
    if (wasDrawing2D || wasDrawing3D || draw2dGrid || draw3dSimulation) {
      background(color(12, 49, 81)); // Dark blue color
    }
    
    wasDrawing2D = draw2dGrid;
    wasDrawing3D = draw3dSimulation;
    
    if (!draw2dGrid && !draw3dSimulation) {
      return;
    }
    
    PGraphics pg = drawFlat2DVersion();
    if (draw3dSimulation && pg3D != null) {
      drawMappedOntoBottle(pg);
    }
    
    // Print led coordinate state to screen
    int lineHeight = box2d.y * 2 + box2d.height + 10;
    String[] textLines = main.currentMode().getTextLines();
    if (textLines != null) {
      for (String line: textLines) {
        text(line, box2d.x, lineHeight);
        lineHeight += 20;
      }
    }
    
    // Print keymapping info to screen
    lineHeight = box2d.y * 2 + box2d.height + 10;
    ArrayList<String> keyMapLines = main.currentMode().getKeymapLines();
    if (keyMapLines != null) {
      for(int i=0; i<keyMapLines.size(); i++) {
        String[] parts = split(keyMapLines.get(i), '\t');
        assert parts.length == 2 : "expected 2 parts, but got " + parts.length;
        textAlign(RIGHT);
        text(parts[0], box2d.x + 220, lineHeight);
        textAlign(LEFT);
        text(parts[1], box2d.x + 230, lineHeight);
        lineHeight += 20;
      }
    }
    
    fill(255);
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
  
  void ledSetRawValue(int whichStrand, int ordinal, int value) {
    assert(whichStrand < getNumStrands()) : "not this many strands";
    assert(ordinal < getStrandSize(whichStrand)) : "whichStrand exceeds number of leds per strand";
    int index = (whichStrand * maxPixelsPerStrand) + ordinal;
    strandMap[index] = value;
    
  }
  
  void ledRawSet(int whichStrand, int ordinal, int x, int y) {
    int value = c2i(x, y);
    ledSetRawValue(whichStrand, ordinal, value);
  }
  
  void ledSetValue(int whichStrand, int ordinal, int value) {
    assert(whichStrand < getNumStrands()) : "not this many strands";
    assert(ordinal < getStrandSize(whichStrand)) : "" + ordinal + " exceeds number of leds per strand " + getStrandSize(whichStrand) + " on strand " + whichStrand;
    assert(ordinal < getStrandSize(whichStrand)) : "Cannot set LED " + ordinal + " on strand " + whichStrand +
    " because it is of length " + getStrandSize(whichStrand);
    int index = (whichStrand * maxPixelsPerStrand) + ordinal;
    assert(strandMap[index] == TC_PIXEL_UNDEFINED) : "led " + ordinal + " on strand " + whichStrand + " is already defined: " + strandMap[index];
    strandMap[index] = value;
  }
  
  void ledMissing(int whichStrand, int ordinal) {
    ledSetValue(whichStrand, ordinal, TC_PIXEL_UNUSED);
  }
  
  int xOffsetter;
  int yOffsetter;
  int ordinalOffsetter;
  
  int lowestX = Integer.MAX_VALUE;
  int lowestY = Integer.MAX_VALUE;
  int biggestX = Integer.MIN_VALUE;
  int biggestY = Integer.MIN_VALUE;
  
  void ledSet(int whichStrand, int ordinal, int x, int y) {
    //    ledSetValue(whichStrand, ordinal, c2i(x, y+20));
    int newX = x + xOffsetter;
    int newY = y + yOffsetter;
    
    lowestX = min(newX, lowestX);
    lowestY = min(newY, lowestY);
    biggestX = max(newX, biggestX);
    biggestY = max(newY, biggestY);
    ledSetValue(whichStrand, ordinal + ordinalOffsetter, c2i(newX, newY));
  }
  
  int ledGetRawValue(int whichStrand, int ordinal, boolean useTrainingMode) {
    assert whichStrand < getNumStrands() : "not this many strands";
    assert ordinal < getStrandSize(whichStrand) : "ordinal exceeds number of leds per strand";
    int[] map = useTrainingMode?trainingStrandMap:strandMap;
    int index = (whichStrand * maxPixelsPerStrand) + ordinal;
    assert index < map.length : "strand: " + whichStrand + " ordinal: " + ordinal + " goes beyond end of map (" + index + " >= " + map.length + ")";
    int value = map[index];
    return value;
  }
  
  Point ledGet(int whichStrand, int ordinal, boolean useTrainingMode) {
    int value = ledGetRawValue(whichStrand, ordinal, useTrainingMode);
    if (value < 0) {
      return new Point(-1, -1);
    }
    return i2c(value);
  }
  
  Point ledGet(int whichStrand, int ordinal) {
    return ledGet(whichStrand, ordinal, main.currentMode().isTrainingMode());
  }
  
  void ledInterpolate() {
    int available = 0;
    
    for (int strand = 0; strand < getNumStrands(); strand++) {
      int start = strand * maxPixelsPerStrand;
      int lastIndexWithCoord = -1;
      available = 0;
      int strandSize = getStrandSize(strand);
      for (int i = start; i < start + strandSize; i++) {
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
                    strandMap[j] = c2i(x, y);
                    
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
  
  void ledMapDump(int minStrand, int maxStrand) {
    if (maxStrand < minStrand) {
      return;
    }

    assert(minStrand < getNumStrands());
    assert(maxStrand <= getNumStrands());
    
    for (int whichStrand = minStrand; whichStrand <= maxStrand; whichStrand++) {
      int minX = 10000;
      int minY = 10000;
      int maxX = -10000;
      int maxY = -10000;
      
      println ("strand " + whichStrand);
      int strandSize = getStrandSize(whichStrand);
      StringBuilder s = new StringBuilder(200);
      
      int start = whichStrand  * maxPixelsPerStrand;
      for (int ordinal = 0; ordinal < strandSize; ordinal++) {
        int index = ordinal + start;
        if ((ordinal % 10) == 0)
        {
          println(s);
          s = new StringBuilder(200);
        }
        s.append(String.format(" %04d:", ordinal));
        int value = strandMap[index];
        if (value == TC_PIXEL_DISCONNECTED) {
          s.append(" DISC  ");
        } else if (value == TC_PIXEL_UNUSED) {
          s.append("UNUSED ");
        } else if (value == TC_PIXEL_UNDEFINED) {
          s.append("(??,??)");
        }
        else {
          assert (value >= 0) : "can't print unrecognized value " + value;
          Point p = i2c(value);
          s.append(String.format("(%02d,%02d) ", p.x, p.y));
          minX = min(minX, p.x);
          minY = min(minY, p.y);
          maxX = max(maxX, p.x);
          maxY = max(maxY, p.y);
        }
      }
      s.append("\n");
      println(s);
      println("min (" + minX + ", " + minY + ") max ("  + maxX + ", " + maxY + ")");
    }
  }
  
  int getNumStrands() {
    return -1;
    //overridden by LedMap
  }
  
  int getStrandSize(int whichStrand) {
    return 0;
    //overridden by LedMap
  }
  
  boolean isStrandPortSide(int whichStrand) {
    return whichStrand < getNumStrands() / 2;
  }
  
  void mapAllLeds() {
    //overridden by LedMap
  }
  
  Point[] pointsForStrand(int whichStrand) {
    assert whichStrand < getNumStrands();
    int strandSize = getStrandSize(whichStrand);
    ArrayList<Point> points = new ArrayList<Point>();
    int start = whichStrand * maxPixelsPerStrand;
    for (int ordinal = 0; ordinal < strandSize; ordinal++) {
      int index = ordinal + start;
      int value = strandMap[index];
      if (value >= 0) {
        Point p = i2c(value);
        points.add(p);
      }
    }
    return (Point[]) points.toArray(new Point[0]);
  }

  TotalControlConcurrent totalControlConcurrent;
  boolean hardwareAlreadySetup = false;
  
  void initTotalControl() {
    int stealPixel = 0;
    int boundary = 0;
    //create the trainingStrandMap
    for (int whichStrand = 0; whichStrand < getNumStrands(); whichStrand++) {
      int numPixels = getStrandSize(whichStrand);
      int start = 0;
      if (true) {
        start = whichStrand * maxPixelsPerStrand;
        boundary = start + numPixels;
      }
      else {
        start = boundary;
        boundary = start + numPixels;
      }
      int j;
      for (j = start; j < boundary; j++) {
        strandMap[j] = TC_PIXEL_UNDEFINED;
        trainingStrandMap[j] = stealPixel++;
        Point tester = i2c(trainingStrandMap[j]);
        assert(tester.x < ledWidth && trainingStrandMap[j] < pixelData.length) : "Strands have more LEDs than we have pixels to assign them\n" + " x:" + tester.x + " y:" + tester.y + " strand: " + whichStrand + " ordinal:" + (j-start) + " rawValue:" + trainingStrandMap[j];
        
      }
      if (true) {
        int end = start + maxPixelsPerStrand;
        for (; j < end; j++) {
          strandMap[j] = TC_PIXEL_DISCONNECTED;
          trainingStrandMap[j] = TC_PIXEL_DISCONNECTED;
        }
      }
    }
    
    mapAllLeds();
    
    ledInterpolate();
//    ledMapDump(0, 2); //set which strands you want to dump

    println("" + lowestX + " <= x <= " + biggestX + ", " + lowestY + " <= y <= " + biggestY);
    assert(lowestX == 0): "lowest LED should be X == 0";
    assert(lowestY == 0): "lowest LED should be Y == 0";
    assert((biggestX + 1) * 2 == ledWidth): "biggest LED should be X == " + ledWidth;
    assert(biggestY + 1 == ledHeight): "biggest LED should be Y == " + ledHeight;
    
    if (!useTotalControlHardware) {
      return;
    }
    
    hardwareAlreadySetup = true;
    
    if (runConcurrent) {
      totalControlConcurrent = new TotalControlConcurrent(getNumStrands(), maxPixelsPerStrand, kUseBitBang);
    }
    else {
      int status = setupTotalControl(getNumStrands(), maxPixelsPerStrand, kUseBitBang);
      if (status != 0) {
        //useTotalControlHardware = false;
        //println("turning off Total Control because of error during initialization");
      }
    }
  }
  
  // This function loads the screen-buffer and sends it to the TotalControl p9813 driver
  void drawToLeds() {
    if (!useTotalControlHardware) {
      return;
    }
    
    if (!hardwareAlreadySetup) {
      initTotalControl();
    }
    
    int[] theStrandMap = main.currentMode().isTrainingMode()?trainingStrandMap:strandMap;
    color[] thePixelData = pixelData;
    //println("sending pixelData: " + pixelData.length + " strandMap: " + theStrandMap.length);
    if (runConcurrent) {
      totalControlConcurrent.put(thePixelData, theStrandMap);
    }
    else {
      int status = writeOneFrame(thePixelData, theStrandMap);
    }
  }
  
}

