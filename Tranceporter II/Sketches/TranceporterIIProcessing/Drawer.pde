// Base class for drawing programs to be displayed on the LED wall. Subclasses must inherit
// draw(), setup(), getName(), reset() and a constructor. They then get access to height, width
// configured for the LEDwall dimensions and can use any PGraphics method like loadPixels, set, beginShape etc.

import java.util.Iterator;

class Drawer {

  static final int MAX_FINGERS = 5;
  static final int MIN_SATURATION = 245;
  static final int MAX_AUDIO_COLOR_OFFSET = 300;

  final color WHITE = color(255);
  final color BLACK = color(0);

  Pixels p; //flat 2D version
  DrawType drawType;
  boolean pressed;
  int pressX, pressY;
  PGraphics pg; //flat 2D version
  int width, height;
  int touchX, touchY;
  Gradient g;
  ArrayList<TouchInfo> touches;
  short[][] rgbGamma;
  Settings settings;
  private Map<String, Object> settingsBackup;

  Drawer(Pixels px, Settings s, String renderer, DrawType pixelDrawType) {
    p = px;
    pressed = false;
    drawType = pixelDrawType;
    width = (drawType == DrawType.TwoSides) ? ledWidth : ledWidth/2;
    height = ledHeight;
    pg = createGraphics(width, height, renderer);
    touches = new ArrayList<TouchInfo>();
    rgbGamma = new short[256][3];
    setGamma(main.DEFAULT_GAMMA);
    settings = s;
  }

  String getName() { return "None"; }
  String getCustom1Label() { return "Disabled";}
  String getCustom2Label() { return "Disabled";}

  void setup() {
  }

  void draw() {
  }

  void reset() {
  }

  boolean onsetOn1 = false;
  boolean onsetOn2 = false;
  boolean onsetOn3 = false;
  boolean onsetOn4 = false;

  boolean manualFlash = false;

  void update() {

    pg.beginDraw();
    int band = 0;

    boolean flash1 = main.beatDetect.isOnset("spectrum", band, 0);
    boolean flash2 = main.beatDetect.isOnset("spectrum", band, 1);
    boolean flash3 = main.beatDetect.isOnset("spectralFlux", band, 0);
    boolean flash4 = main.beatDetect.isOnset("spectralFlux", band, 1);

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

    pg.loadPixels();
    main.ledMap.copyPixels(pg.pixels, drawType);
  }

  boolean isTrainingMode() {
    return false;
  }

  void justEnteredSketch() {
    println("just entered: " + getName());
  }

  void justExitedSketch() {
    println("just exited: " + getName());
  }

  void sendToIPad() {
    // Send any GUI to iPad
  }

  void handleOscEvent(OscMessage msg) {
  }

  void keyPressed() {
  }

  String[] getTextLines() {
    return null;
  }

  ArrayList<String> getKeymapLines() {
    return main.getKeymapLines();
  }

  void setTouch(int touchNum, float x, float y) {
    if (touchNum == 1) {
      touchX = round(x * width);
      touchY = round(y * height);
    }

    TouchInfo t = new TouchInfo();
    t.x = x;
    t.y = y;
    t.whichFinger = touchNum;
    t.time = millis();
    touches.add(t);
    if (touches.size() > 100) {
      touches.remove(0);
    }
  }

  /**
   * Receives Wiimote acceleration readings.  By default, this translates roll and pitch into X and Y coordinates
   * and calls {@link #setTouch(int, float, float)} with the finger number set to 1.
   *
   * @see MainClass#wiimoteAccel
   */
  void wiimoteAccel(float x, float y, float z, float pitch, float roll, float tilt) {
    double touchX = 1.0 - Math.abs(roll)/Math.PI;
    double touchY = pitch / Math.PI;
    setTouch(1, (float) touchX, (float) touchY);
  }

  /**
   * @see MainClass#wiimoteButtons
   */
  void wiimoteButtons(int buttons) {
  }

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

  Vec2D getTouchFor(int touchNum, long touchCutoffTime) {

    Iterator<TouchInfo> it = touches.iterator();
    while (it.hasNext()) {
      TouchInfo t = it.next();
      if (t.whichFinger == touchNum) {
        it.remove();
        boolean youngEnough = millis() - t.time <= touchCutoffTime;
        if (youngEnough) {
          Vec2D result = new Vec2D(t.x, t.y);
          result.scaleSelf(width - 1, height - 1);
          return result;
        }
      }
    }
    return null;
  }

  // adapted from https://github.com/adafruit/Adavision/blob/master/Processing/WS2801/src/WS2801.java
  // Fancy gamma correction; separate RGB ranges and exponents:
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
      rgbGamma[i][0] = (short)(rMin + (int)Math.floor(rRange * Math.pow(d, rGamma) + 0.5));
      rgbGamma[i][1] = (short)(gMin + (int)Math.floor(gRange * Math.pow(d, gGamma) + 0.5));
      rgbGamma[i][2] = (short)(bMin + (int)Math.floor(bRange * Math.pow(d, bGamma) + 0.5));
    }
  }

  void setSettingsBackup(Map<String, Object> backup) {
    settingsBackup = backup;
  }

  Map<String, Object> getSettingsBackup() {
    return settingsBackup;
  }

}

class TouchInfo
{
  int whichFinger;
  float x;
  float y;
  long time;

  String toString()
  {
    return "touch " + x + ", " + y + " on finger: " + whichFinger;
  }
}
