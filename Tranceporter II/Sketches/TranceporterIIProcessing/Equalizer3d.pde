/* OpenProcessing Tweak of *@*http://www.openprocessing.org/sketch/1820*@* */
/* !do not delete the line above, required for linking your tweak if you re-upload */
import ddf.minim.*;
import ddf.minim.analysis.*;

class Equalizer3d extends Drawer
{
  float rad=0;
  float f=radians(0.1);
  float kickSize1, kickSize2, kickSize3;
  int [][]randoms;
  int numCols = 8;
  int numRows = 4;
  
  Equalizer3d(Pixels p, Settings s) {
    super(p, s, P3D);
  }
 
  String getName()
  {
    return "3d Equalizer";
  }
  
  String getCustom1Label() { return "distinct colors";}


  void setup() {
    settings.setParam(settings.keyAudioSensitivity1,0.5);
    settings.setParam(settings.keyAudioSensitivity2,0.5);
    settings.setParam(settings.keyAudioSensitivity3,0.7);
    settings.setParam(settings.keyBeatLength,0.25);
  }
  
  float factor = 0.2;

  void draw() {
    colorMode(RGB,255);
    
    if (randoms == null) {
      randoms = new int[numCols][numRows];
      
      for (int i = 0; i < numCols; i++) {
        for (int j = 0; j < numRows; j++) {
          int loc = i*60 + j * 60 * numRows; // Pixel array location
          randoms[i][j] = (int)random(0xFFFF);
        }
      }
    }
    
    pg.fill(0,10);
    pg.rect(0,0,width,height);
    pg.rotateY(rad);
    pg.rotateX(rad);

    pg.loadPixels();

    int colorWidth = (int)((settings.getParam(settings.keyCustom1) * getNumColors()) / (numRows * numCols * 0.5));
    
    for (int i = 0; i < numCols; i++) {
      for (int j = 0; j < numRows; j++) {
        
        color c = getColor(((i + j * numRows) * colorWidth) % getNumColors());
        
        float kickSize = 2*factor;
        
        int whichBeat = (int)(randoms[i][j] >> 3) % 3;
        if (whichBeat == 0) {
          if (settings.isBeat(0)) {
            kickSize1 = 55*factor;
          }
          kickSize1 = constrain(kickSize1 * 0.98, 2*factor, 55*factor);
          kickSize = kickSize1;
          
        }
        else if (whichBeat == 1) {
          if (settings.isBeat(1)) {
            kickSize2 = 55*factor;
          }
          kickSize2 = constrain(kickSize2 * 0.98, 2*factor, 55*factor);
          kickSize = kickSize2;
          
        }
        else {
          if (settings.isBeat(2)) {
            kickSize3 = 55*factor;
          }
          kickSize3 = constrain(kickSize3 * 0.98, 2*factor, 55*factor);
          kickSize = kickSize3;
        }
          
        float x = (i * 60*factor) + 10;
        float y = (j * 60*factor) + 10;
        
        float baseZ = factor * (randoms[i][j] >> 4 & 0xFFF);
        float z = (kickSize/(512 * factor)) * baseZ + (randoms[i][j] & 0xF);
        // Translate to the location, set fill, and draw the box
        if(brightness(c)>30){
          pg.pushMatrix();
          pg.translate(x,y,-100*factor);
          pg.fill(c,100);
          pg.noStroke();
          pg.box(60*factor,60*factor,z);
          pg.popMatrix();
          pg.pushMatrix();
          pg.translate(x,(160 * factor),y-(320 * factor));
          pg.box(60*factor,z,60*factor);
          pg.popMatrix();
        }
      }
    }
    if(rad>PI/2 || rad<-PI/3)
      f=-f;
    rad+=f * settings.getParam(settings.keySpeed) * 16;
  }
}

