// Base class for drawing programs to be displayed on the LED wall. Subclasses must inherit
// draw(), setup(), getName(), reset() and a constructor. They then get access to height, width, mousePressed
// configured for the LEDwall dimensions and can use any PGraphics method like loadPixels, set, beginShape etc.

class Drawer {
  Pixels p; //flat 2D version
  boolean pressed;
  int pressX, pressY;
  PGraphics pg; //flat 2D version
  boolean mousePressed;
  int width, height;
  int mouseX, mouseY;
  int touchX, touchY;
  int lastMouseX = -1, lastMouseY = -1;
  Gradient g;
  float[] xTouches, yTouches;
  int MAX_TOUCHES = 5;
  long[] lastTouchTimes;
  short[][] rgbGamma; 
  Settings settings;
  private Object settingsBackup;
  int MIN_SATURATION = 245;
  int MAX_AUDIO_COLOR_OFFSET = 300;
  
  Drawer(Pixels px, Settings s, String renderer) {
    p = px;
    pressed = false;
    width = ledWidth;
    height = ledHeight;
    pg = createGraphics(width, height, renderer);
    xTouches = new float[MAX_TOUCHES];
    yTouches = new float[MAX_TOUCHES];
    lastTouchTimes = new long[MAX_TOUCHES];
    rgbGamma = new short[256][3];
    setGamma(main.DEFAULT_GAMMA);
    settings = s;
  }
  
  String getName() { return "None"; }
  String getCustom1Label() { return "Disabled";}
  String getCustom2Label() { return "Disabled";}
    
  void setup() {}
  void draw() {}
  void reset() {}
  
  boolean onsetOn1 = false;
  boolean onsetOn2 = false;
  boolean onsetOn3 = false;
  boolean onsetOn4 = false;
  
  boolean manualFlash = false;
  
  void update() {

    pg.beginDraw();
    int band = 0;
    
    boolean flash1 = main.bd.isOnset("spectrum",band,0);
    boolean flash2 = main.bd.isOnset("spectrum",band,1);
    boolean flash3 = main.bd.isOnset("spectralFlux",band,0);
    boolean flash4 = main.bd.isOnset("spectralFlux",band,1);
    
    boolean flash = (flash1 && !onsetOn1) || (flash2 && !onsetOn2) || (flash3 && !onsetOn3) || (flash4 && !onsetOn4);
    
    if (manualFlash || (flash && settings.getParam(settings.keyFlash) == 1.0)) {
      manualFlash = false;
      colorMode(RGB);
      pg.background(255);
    }
    else {
      draw();
    }
    pg.endDraw();
     
    onsetOn1 = flash1;
    onsetOn2 = flash2;
    onsetOn3 = flash3;
    onsetOn4 = flash4;
    
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        p.setPixel(x, y, pg.get(x, y));
      }
    }
  }
  
  boolean isTrainingMode() {
    return false;
  }
  
  int getWidth() {
    return ledWidth;
  }
  
  int getHeight() {
    return ledHeight;
  }

  void setMousePressed(boolean mp) {
    mousePressed = mp; 
  }
  
  void setMouseCoords(int mx, int my) {
    mouseX = mx/screenPixelSize;
    mouseY = my/screenPixelSize;
    lastMouseX = mx; 
    lastMouseY = my;
  }
  
  void keyPressed() {
  }
  
  String[] getTextLines() {
    return null;
  }
  
  int getLastMouseX() { return lastMouseX; }
  int getLastMouseY() { return lastMouseY; }
  
  void setTouch(int touchNum, float x, float y) {
    lastTouchTimes[touchNum] = millis();
    if (touchNum == 1) {
      touchX = mouseX = round(x * width);
      touchY = mouseY = round(y * height);
    }
    
    xTouches[touchNum] = x;
    yTouches[touchNum] = y;    
  }
  
  //void setColorPalette(color[] palette) {
  //  this.palette = palette;
  //}
  
  int getNumColors() { return settings.palette.length; }
  
  color getColor(int index) {
    int numColors = settings.palette.length;
    int cyclingOffset = int(settings.getParam(settings.keyColorCyclingSpeed)*numColors/40)*frameCount;
    index = (index + cyclingOffset) % numColors;
    
    // calculate brightness and index offsets for audio beats
    float brightTotal = 0;
    float brightBeat = 0;
    int audioOffset = 0;
    for (int i=0; i<settings.numBands(); i++) {
      float indRange = numColors/settings.numBands; //basePaletteColors;
      //float indStart = (i-0.5)*indRange
      //if (settings.isBeat(i) && index >= i*indRange && index < (i+1)*indRange) {
      float smooth = sin((index - i*indRange) / indRange * PI / 2);  // 1% cpu
      brightTotal += settings.getParam(settings.getKeyAudioBrightnessChange(i));
      brightBeat += settings.beatPos(i) * settings.getParam(settings.getKeyAudioBrightnessChange(i));
      audioOffset += smooth * int(settings.beatPos(i) * MAX_AUDIO_COLOR_OFFSET * settings.getParam(settings.getKeyAudioColorChange(i)));
      //}
    }
    
    //println(audioOffset);
    int ind = (index + audioOffset + numColors) % numColors;
    color col = settings.palette[ind];
    
    colorMode(RGB);
    short r = rgbGamma[(int)red(col)][0];
    short g = rgbGamma[(int)green(col)][1];
    short b = rgbGamma[(int)blue(col)][2];
    col = color(r, g, b);
    
    // adjust saturation
    colorMode(HSB);
    col = color(hue(col), constrain(saturation(col), MIN_SATURATION, 255), brightness(col));

    // cap max brightness on each RGB channel
    colorMode(RGB);
    
    float percentMainBrightnessControl = 1 - brightTotal/3;
    if (percentMainBrightnessControl < 0.5) {
      percentMainBrightnessControl = 0.5; //main control always affects at least min level of brightness
    }
    float brightSetting = settings.getParam(settings.keyBrightness);
    float totalBright = brightSetting * percentMainBrightnessControl;
    if (brightTotal > 0) {
      totalBright += (brightBeat / brightTotal) * (1 - percentMainBrightnessControl);
    }
    assert(totalBright >= 0 && totalBright <= 1.0): "invalid totalBright" + totalBright;
    totalBright *= 255;
 //   println("_totalBright:" + totalBright);
    col = color(constrain(red(col), 0, totalBright), constrain(green(col), 0, totalBright), constrain(blue(col), 0, totalBright));
    
    return col;
  }

  color replaceAlpha(color c, float newAlpha) {
    colorMode(RGB);
    return color(red(c), green(c), blue(c), newAlpha);
  }
  
  float randomYForBottle(float x, float scale) {
    float percent = (x * scale) / width;
    float start = percent * height / 2.0;
    float y =  random(start, start + height/2.0);
//    println("x:" + x + " upper:" +  (x + height/2.0) + "  result: " + y);
    return y / scale;
  }

  boolean isTouching(int touchNum, int[] xy, long touchCutoffTime) {
    if (xy != null) {
      xy[0] = int(xTouches[touchNum] * (width-1) + 0.5);
      xy[1] = int(yTouches[touchNum] * (height-1) + 0.5);
    }
    
    return millis() - lastTouchTimes[touchNum] <= touchCutoffTime;
  }
  
  // adapted from https://github.com/adafruit/Adavision/blob/master/Processing/WS2801/src/WS2801.java
  // Fancy gamma correction; separate R,G,B ranges and exponents:
  double lastGamma = 0;
  private void setGamma(double gamma) {
    if (gamma != lastGamma) {
      setGamma(0, 255, gamma, 0, 255, gamma, 0, 255, gamma);
      lastGamma = gamma;
    }
  }
  private void setGamma(int rMin, int rMax, double rGamma,
	        int gMin, int gMax, double gGamma,
	        int bMin, int bMax, double bGamma) {
    double rRange, gRange, bRange, d;

    rRange = (double)(rMax - rMin);
    gRange = (double)(gMax - gMin);
    bRange = (double)(bMax - bMin);

    for(short i=0; i<256; i++) {
      d = (double)i / 255.0;
      rgbGamma[i][0] = (short)(rMin + (int)Math.floor(rRange * Math.pow(d,rGamma) + 0.5));
      rgbGamma[i][1] = (short)(gMin + (int)Math.floor(gRange * Math.pow(d,gGamma) + 0.5));
      rgbGamma[i][2] = (short)(bMin + (int)Math.floor(bRange * Math.pow(d,bGamma) + 0.5));
    }
  }
  
  void setSettingsBackup(Object backup) {
    settingsBackup = backup;
  }
  
  Object getSettingsBackup() {
    return settingsBackup;
  }
  
}
