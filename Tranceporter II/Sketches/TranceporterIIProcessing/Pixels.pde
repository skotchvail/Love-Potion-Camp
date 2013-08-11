/*
 Draws the pixels to the computer screen
 */

import java.awt.Rectangle;

import saito.objloader.Face;
import saito.objloader.OBJModel;
import saito.objloader.Segment;

class Pixels {
  private color[] maskPixels;
  private boolean[] bottleBounds; // For sketches that want to stay inside the bottle
  private OBJModel objModel;
  private PGraphics pg3D;

  private Rectangle box2d, box3d, boxEqualizer;
  private final color kWhite = color(255);
  private final color kBackgroundColor = color(12, 49, 81);
  
  float mappedBottleRotation = 0.8;

  Pixels(PApplet p) {
    objModel = new OBJModel(p, "tranceporter.obj");
    // turning on the debug output (it's all the stuff that spews out in the black box down the bottom)
    objModel.enableDebug(); // TODO: still need this?
    objModel.scale(3); // TODO: still need this?
  }

  void setup() {
    box2d = new Rectangle(10, 10, ledWidth * screenPixelSize, ledHeight * screenPixelSize);
    box3d = new Rectangle(box2d.x * 2 + box2d.width, box2d.y, 360, 180);
    boxEqualizer = new Rectangle(box3d.x, box3d.y * 2 + box3d.height, 100, 100);
    pg3D = createGraphics(box3d.width, box3d.height, P3D);
    updateMaskPixels();
  }

  void forceUpdateMaskPixels() {
    maskPixels = null;
  }

  /*
   In order to build up bottleBounds, we see which pixels are surrounded
   by unmapped LEDs
   */
  boolean isOutsideBottle(int x, int y, Boolean fromTop) {

    // Mask is white outside of the bottle
    for (int angle = 1; angle <= 3; angle++) {
      int testY = fromTop ? y - angle : y + angle;
      for (int testX = x - angle; testX < x + angle; testX++) {
        if (testX < 0 || testY < 0) {
          continue;
        }
        if (testX >= ledWidth - 1 || testY >= ledHeight - 1) {
          continue;
        }
        int offset = testY * ledWidth + testX;
        if (maskPixels[offset] == kWhite) {
          return false;
        }
      }
    }
    return maskPixels[y * ledWidth + x] != kWhite;
  }

  void updateMaskPixels() {
    if (maskPixels == null) {
      // Mask out any pixels that are not mapped
      maskPixels = new color[ledWidth * ledHeight];
      int length = maskPixels.length;
      int numStrands = main.ledMap.getNumStrands();
      for (int whichStrand = 0; whichStrand < numStrands; whichStrand++) {
        for (Point point: main.ledMap.pointsForStrand(whichStrand)) {
          int offset = point.y * ledWidth + point.x;
          if (offset < length) {
            maskPixels[offset] = kWhite;
          }
        }
      }

      // Define a new bottleBounds
      int maxY = ledHeight - 1;
      bottleBounds = new boolean[ledWidth * ledHeight];
      for (int y = 0; y <= maxY; y++) {
        bottleBounds[y * ledWidth + 0] = true;
        bottleBounds[y * ledWidth + ledWidth - 1] = true;
        bottleBounds[y * ledWidth + ledWidth / 2] = true;
      }
      
      for (int x = 0; x < ledWidth; x++) {
        bottleBounds[0 * ledWidth + x] = true;
        bottleBounds[maxY * ledWidth + x] = true;
        for (int y = 0; y < ledHeight / 2; y++) {
          int offset = y * ledWidth + x;
          bottleBounds[offset] = true;
          if (!isOutsideBottle(x, y, true)) {
            break;
          }
        }
        for (int y = maxY; y >= ledHeight / 2 ; y--) {
          int offset = y * ledWidth + x;
          bottleBounds[offset] = true;
          if (!isOutsideBottle(x, y, false)) {
            break;
          }
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
      background(kBackgroundColor); // Dark blue color
      drawInstructions();
    }

    boolean showEqualizer = true;
    if (showEqualizer) {
      noStroke();
      fill(kBackgroundColor);
      rect(boxEqualizer.x, boxEqualizer.y, boxEqualizer.width, boxEqualizer.height);

      int gap = 3;
      int width = (boxEqualizer.width - gap * (main.NUM_BANDS - 1)) / main.NUM_BANDS;
      int height = (boxEqualizer.height - gap) / 2;
      for (int band = 0; band < main.NUM_BANDS; band++) {
        if (main.settings.isBeat(band)) {
          fill(255, 255);
        }
        else {
          fill(255, 255, 0, 100);
        }
        float rawBand =  main.beatDetect.beatPos("spectralFlux", band);
        float pos1 = rawBand * height;
        rect(boxEqualizer.x + band * (width + gap), boxEqualizer.y + height - pos1, width, pos1);
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
