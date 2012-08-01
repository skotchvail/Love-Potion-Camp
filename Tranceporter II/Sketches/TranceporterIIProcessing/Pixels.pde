// Class to abstract out interfacing with the microcontroller (which in turn sends signals to the wall) and
// to the processing display.

import saito.objloader.*;

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
  int rotation = 0;

  OBJModel objModel;
  PGraphics pg3D;

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
    
    int width3d = 360;
    int height3d = 360;

    pg3D = createGraphics(width3d, height3d, P3D);
    
    objModel = new OBJModel(p, "tranceporter.obj");
    // turning on the debug output (it's all the stuff that spews out in the black box down the bottom)
    objModel.enableDebug();
    
    objModel.scale(3);
    
    //noStroke();
    println("drawModes POINTS=" + POINTS + " LINES=" + LINES + " TRIANGLES=" + TRIANGLES + " TRIANGLE_FAN=" + TRIANGLE_FAN
            + " TRIANGLE_STRIP=" + TRIANGLE_STRIP + " QUADS=" + QUADS + " QUAD_STRIP=" + QUAD_STRIP);
  
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

  void drawModel(PImage texture) {
    try {
      PVector v = null, vt = null, vn = null;

      PVector lowest = new PVector(10000000,10000000,10000000);
      PVector highest = new PVector(-10000000,-10000000,-10000000);
      
      //			Material tmpMaterial = null;
      
      Segment tmpModelSegment;
      Face tmpModelElement;
      
      // render all triangles
      for (int s = 0; s < objModel.getSegmentCount(); s++) {
        
        tmpModelSegment = objModel.getSegment(s);
        
        //				tmpMaterial = objModel.materials.get(tmpModelSegment.materialName);
        
        // if the material is not assigned for some
        // reason, it uses the default material setting
        //				if (tmpMaterial == null) {
        //					tmpMaterial = objModel.materials.get(defaultMaterialName);
        //
        //					debug.println("Material '" + tmpModelSegment.materialName + "' not defined");
        //				}
        
        //				if (useMaterial) {
        //					pg3D.ambient(255.0f * tmpMaterial.Ka[0], 255.0f * tmpMaterial.Ka[1], 255.0f * tmpMaterial.Ka[2]);
        //					pg3D.specular(255.0f * tmpMaterial.Ks[0], 255.0f * tmpMaterial.Ks[1], 255.0f * tmpMaterial.Ks[2]);
        //					pg3D.fill(255.0f * tmpMaterial.Kd[0], 255.0f * tmpMaterial.Kd[1], 255.0f * tmpMaterial.Kd[2], 255.0f * tmpMaterial.d);
        //				}
        
        for (int f = 0; f < tmpModelSegment.getFaceCount(); f++) {
          tmpModelElement = (tmpModelSegment.getFace(f));
          
          if (tmpModelElement.getVertIndexCount() > 0) {
            
            pg3D.textureMode(NORMALIZED);
            //println("face=" + f + " drawMode = " + objModel.getDrawMode());

            pg3D.beginShape(objModel.getDrawMode()); // specify render mode
            boolean useTexture = false;
            //						if (useTexture == false || tmpMaterial.map_Kd == null)
            //							useTexture = false;
            //
            //						if (useTexture) {
            //							if (texture != null)
            //								pg3D.texture(texture);
            //							else
            //								pg3D.texture(tmpMaterial.map_Kd);
            //						}
            pg3D.texture(texture);
            
            for (int fp = 0;  fp < tmpModelElement.getVertIndexCount(); fp++) {
              //v = vertices.get(tmpModelElement.getVertexIndex(fp));
              v = objModel.getVertex(tmpModelElement.getVertexIndex(fp));
              // println("a"); //This is the line that gets execute
              if (v != null) {
                try {
                  if (tmpModelElement.normalIndices.size() > 0) {
                    //println("b");
                    vn = objModel.getNormal(tmpModelElement.getNormalIndex(fp));
                    pg3D.normal(vn.x, vn.y, vn.z);
                  }
                  
                  if (useTexture) {
                    //println("c");
                    vt = objModel.getUV(tmpModelElement.getTextureIndex(fp));
                    pg3D.vertex(v.x, v.y, v.z, vt.x, vt.y);
                  } else {
                    //println("d");  //This is the line that gets execute
                    //pg3D.vertex(v.x, v.y, v.z);
                    
                    float textureX = map(v.x,-224,-24,0,1);
                    float textureY = map(v.y,-1124,99,0,1);
                    float textureZ = map(v.z,47,844,0,1);
                    
                    pg3D.vertex(v.x, v.y, v.z,textureY,textureZ);
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

                } catch (Exception e) {
                  e.printStackTrace();
                }
              } else
                // println("e");
                pg3D.vertex(v.x, v.y, v.z);
            }
            
            pg3D.endShape();
            
            //pg3D.textureMode(PConstants.IMAGE);
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
    pg3D.background(color(6,25,41));
    pg3D.lights();
        
    if (false) {
      pg3D.translate(pg3D.width / 2, pg3D.height / 2);
      
      int fullRevolution = 30*5; //5 seconds
      rotation = (rotation  + 1) % fullRevolution;
      pg3D.rotateY(map(rotation, 0, fullRevolution, -PI, PI));

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
    }
    else {
      pg3D.pushMatrix();

      float rX = map(mouseY, 0, height, -PI, PI);
      float rY = map(mouseX, 0, width, -PI, PI);
      //println("rX = " + rX + " rY = " + rY);
      rX = PI/2;
      
      int fullRevolution = 30*5; //5 seconds
      rotation = (rotation  + 1) % fullRevolution;
      rY = map(rotation, 0, fullRevolution, -PI, PI);

      //pg3D.translate(pg3D.width * 1., pg3D.height * -5.5, pg3D.height * -1.5);
      pg3D.translate(0,pg3D.height * 2, pg3D.height * -4);
      
      pg3D.rotateY(rY);
      pg3D.rotateX(rX);
     
      pg3D.translate(pg3D.height * 0,pg3D.height * 1, pg3D.height * 0);

      drawModel(img);
      pg3D.popMatrix();
      pg3D.endDraw();
    }
    
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

