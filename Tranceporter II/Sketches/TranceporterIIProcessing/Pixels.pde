/*
 Draws the pixels to the computer screen
 */

import saito.objloader.*;
import java.awt.Rectangle;

class Pixels {
  private color[] maskPixels;
  private OBJModel objModel;
  private PGraphics pg3D;
  
  private Rectangle box2d, box3d, boxLEDs, boxEqualizer;
  
  float mappedBottleRotation = 0.8;
  final int ledSide = 15;
  final int ledBetween = 2;
  
  // Simulation for figuring out to program LEDs, not useful in the real world
  final int[][] ledStrand = {
  { 0,  7,  8,  9, 10, 11, 12}, //13
  { 1,  6, 25, 24, 17, 16, 15}, //14
  { 2,  5, 26, 23, 18, 39, 40},
  { 3,  4, 27, 22, 19, 38, 41},
  {30, 29, 28, 21, 20, 37, 42}, //43
  {31, 32, 33, 34, 35, 36, 44}, //45-50
  {56, 55, 54, -1, 53, 52, 51},
  {57, 58, 59, -1, 60, 61, 62},
  };
  
  final int ledRows = ledStrand.length;
  final int ledCols = ledStrand[0].length;
  
  Pixels(PApplet p) {
    objModel = new OBJModel(p, "tranceporter.obj");
    // turning on the debug output (it's all the stuff that spews out in the black box down the bottom)
    objModel.enableDebug(); // TODO: still need this?
    objModel.scale(3); // TODO: still need this?
  }
  
  void setup() {
    box2d = new Rectangle(10, 10, ledWidth * screenPixelSize, ledHeight * screenPixelSize);
    box3d = new Rectangle(box2d.x * 2 + box2d.width, box2d.y, 360, 180);
    boxLEDs = new Rectangle(box3d.x,
                            box3d.y * 2 + box3d.height,
                            ledCols * ledSide + (ledCols + 1) * ledBetween,
                            ledRows * ledSide + (ledRows + 1) * ledBetween);
    boxEqualizer = new Rectangle(boxLEDs.x + boxLEDs.width + box2d.x, boxLEDs.y, boxLEDs.width, boxLEDs.height);
    pg3D = createGraphics(box3d.width, box3d.height, P3D);
  }
  
  void forceUpdateMaskPixels() {
    maskPixels = null;
  }

  void updateMaskPixels() {
    color white = color(255);
    if (maskPixels == null) {
      // Mask out any pixels that are not mapped
      maskPixels = new color[ledWidth * ledHeight];
      
      int numStrands = main.ledMap.getNumStrands();
      for (int whichStrand = 0; whichStrand < numStrands; whichStrand++) {
        for (Point point: main.ledMap.pointsForStrand(whichStrand)) {
            maskPixels[point.y * ledWidth + point.x] = white;
        }
      }
    }
  }
    
  PGraphics drawFlat2DVersion() {
    boolean trainingMode = main.currentMode().isTrainingMode();
    updateMaskPixels();
    
    PImage image = createImage(ledWidth, ledHeight, RGB);
    arrayCopy(main.ledMap.pixelData, image.pixels, image.pixels.length);
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
    
    mappedBottleRotation = (mappedBottleRotation + rotationSpeed) % 1.0;
    float rX = PI/2;
    float rY = map(mappedBottleRotation, 0, 1.0, -PI, PI);
    
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
      drawInstructions();
    }
    
    boolean programStrandSimulation = true;
    if (programStrandSimulation) {
      color[] pixelData = main.ledMap.pixelData;
      
      noStroke();
      fill(27, 114, 188);
      rect(boxLEDs.x, boxLEDs.y, boxLEDs.width, boxLEDs.height);
      
      fill(255);
      int whichStrand = main.hardwareTestEffect.cursorStrand;

      final int ledInterval = ledSide + ledBetween;
      for (int x = 0; x < ledCols; x++) {
        for (int y = 0; y < ledRows; y++) {
          int whichOridinal = ledStrand[y][x];
          int ledColor = color(0);
          if (whichOridinal >= 0) {
            Point coordinate = main.ledMap.ledGet(whichStrand, whichOridinal);
            if (coordinate.x >= 0) {
              int index = coordinate.y * ledWidth + coordinate.x;
              assert (index < pixelData.length) : "index " + index + " exceeds pixelData.length:" + pixelData.length;
              ledColor = pixelData[index];
            }
          }
          fill(ledColor);
          rect(boxLEDs.x + (x * ledInterval) + ledBetween, boxLEDs.y + (y * ledInterval) + ledBetween, ledSide, ledSide);
        }
      }
      fill(255);
    }
    
    if (true) {
//      rect(boxEqualizer.x, boxEqualizer.y, boxEqualizer.width, boxEqualizer.height);
      

      int gap = 3;
      int width = (boxEqualizer.width - gap * (main.NUM_BANDS - 1)) / main.NUM_BANDS;
      int height = (boxEqualizer.height - gap) / 2;
      for (int band = 0; band < main.NUM_BANDS; band++) {
        fill(255, 255, 0);
        float pos1 = main.bd.beatPos("spectralFlux", band) * height;
        rect(boxEqualizer.x + band * (width + gap), boxEqualizer.y + height - pos1, width, pos1);

        if (false) {
          fill(0, 255, 0);
          float pos2 = (float)(main.bd.getMetricMean("spectrum", band, 0) * height);
          rect(boxEqualizer.x + band * (width + gap), boxEqualizer.y + (2 * height + gap) - pos2, width, pos2);
        }
//        if (isBeat(i)) {
//          speed += beatPos(i)*(Float)getParam(getKeyAudioSpeedChange(i));
//        }
      }

      fill(255);
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
    drawInstructions();
    
    fill(255);
  }
  
  void drawInstructions() {
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
  }
  
  Rectangle getBox2D() {return box2d;}
  Rectangle getBox3D() {return box3d;}
}
