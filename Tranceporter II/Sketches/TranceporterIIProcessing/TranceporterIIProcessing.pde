// The main sketch

import oscP5.*;
import netP5.*;
import ddf.minim.analysis.*;
import ddf.minim.*;
import java.util.Arrays;
import java.util.List;


//ADJUSTABLE PARAMS
boolean render3d = true;
int baud = 921600;
//int baud = 0;
String iPadIP = "10.0.1.8";
int ledWidth = 60;
int ledHeight = 40;
int screenPixelSize = 5;
int screenWidth = 700;
int screenHeight = 400;
MainClass main;
Utility utility;

interface VoidFunction { void function(); }
interface FunctionFloatFloat { void function(float x, float y); }


void setup() {
  size(screenWidth, screenHeight);
  utility = new Utility();
  main = new MainClass();
  main.setup(this);
}

void draw() {
  main.settings.getParam(main.settings.getKeyAudioBrightnessChange(2));
  main.draw();
  main.settings.getParam(main.settings.getKeyAudioBrightnessChange(2));
}

void mouseClicked() {
  main.mouseClicked();
}

class MainClass {
  
  Pixels display;
  Console console;

  int NUM_COLORS = 512;
  float DEFAULT_GAMMA = 2.5;
  
  // Audio
  BeatDetect bd;
  int HISTORY_SIZE = 50;
  int SAMPLE_RATE = 44100;
  int SAMPLE_SIZE = 1024;
  int NUM_BANDS = 3;
  boolean[] analyzeBands = {true, true, true };
  //AudioSocket signal;
  AudioInput in;
  AudioOutput out;
  FFT fft;
  Minim minim;
  int MAX_BEAT_LENGTH = 750, MAX_AUDIO_SENSITIVITY = 12;
  
  Drawer[] modes;
  int modeInd = 0;

  
  PaletteManager pm = new PaletteManager();
  Settings settings = new Settings(NUM_BANDS);

  void setup(PApplet applet) {
    
    // redirect stdout/err
    try {
      console = new Console();
    } catch(Exception e) {
      println("Error redirecting stdout/stderr: " + e);
    }
    
    try {
      display = new Pixels(applet, baud);
      println("### Started at " + baud);
    } catch (Exception e) {
      baud = 0;
      display = new Pixels(applet, baud);
      println("### Started in standalone mode");
    }
    
    modes = new Drawer[] { new HardwareTest(display, settings), new Paint(display, settings), new Bzr3(display, settings),
      new Fire(display, settings), new AlienBlob(display, settings), new BouncingBalls2D(display, settings), new Smoke(display, settings) };
    
    settings.initOSC();
    pm.init(applet);
    
    newEffectFirstTime();
    //  modes[modeInd].setup();
    //  updatePaletteName();
    //  newPalette();
    
    // Audio features
    minim = new Minim(applet);
    in = minim.getLineIn(Minim.STEREO, SAMPLE_SIZE, SAMPLE_RATE);
    fft = new FFT(SAMPLE_SIZE, SAMPLE_RATE);
    
    bd = new BeatDetect(fft, NUM_BANDS, HISTORY_SIZE);
    for (int i=0; i<NUM_BANDS; i++)
      bd.analyzeBand(i, analyzeBands[i]);
    bd.setFFTWindow(FFT.HAMMING);
    
    frameRate(SAMPLE_RATE/SAMPLE_SIZE);
    
    settings.sendAllSettingsToPad();
    updateIPadGUI();
    
    println("Done setup");
  }

  void draw() {
    if (key == ' ')
      return;
    
    for (int i=0; i<NUM_BANDS; i++) {
      float audioSensitivity = 1 - settings.getParam(settings.getKeyAudioSensitivity(i));
      bd.setSensitivity(i, audioSensitivity * MAX_AUDIO_SENSITIVITY, (int)(settings.getParam(settings.keyBeatLength)*MAX_BEAT_LENGTH));
    }
    bd.update(in.mix);
    for (int i=0; i<NUM_BANDS; i++)
      settings.setIsBeat(i, bd.isBeat("spectralFlux", i));
    Drawer d = modes[modeInd];
    
    if (settings.palette == null) {
      assert(settings.palette != null);
      // println("can't draw, palett is null");
      return;
    }
    
    d.setMousePressed(mousePressed);
    
    if (d.getLastMouseX() != mouseX || d.getLastMouseY() != mouseY) {
      d.setMouseCoords(mouseX, mouseY);
    }
    
    //  sendParamsOSC();
    d.update();
    display.drawToScreen();
    display.drawToLeds();
  }
  
  void newPalette() {
    settings.palette = new color[NUM_COLORS];
    pm.getNewPalette(NUM_COLORS, settings.palette);
    settings.paletteType = pm.getPaletteType();
  }
  
  void newPaletteType() {
    pm.nextPaletteType();
    newPalette();
    updateIPadGUI();
  }
  
  void newEffectFirstTime() {
    settings.palette = new color[NUM_COLORS];
    pm.setPaletteType(settings.paletteType, NUM_COLORS, settings.palette);
    modes[modeInd].setup();
  }
  
  void newEffect() {
    int oldMode = modeInd;
    modeInd = (modeInd + 1) % modes.length;
    println("newEffect " + modes[oldMode].getName() + " -> "+ modes[modeInd].getName());
    
    // Each mode tracks its own settings
    Object newSettings = modes[modeInd].getSettingsBackup();
    Object oldSettings = settings.switchSettings(newSettings);
    modes[oldMode].setSettingsBackup(oldSettings);
    
    if (newSettings == null) {
      newEffectFirstTime();
    }
    else {
      pm.setPaletteType(settings.paletteType, NUM_COLORS, settings.palette);
    }
    //  if (settings.palette == null ) {
    //    settings.palette = new color[NUM_COLORS];
    //  }
    //  pm.setPaletteType(settings.paletteType, NUM_COLORS, settings.palette);
    //  if (newSettings == nil) {
    //    modes[modeInd].setup();
    //  }
    assert(settings.palette != null);
    settings.sendAllSettingsToPad();
    updateIPadGUI();
  }
  
  void reset() {
    modes[modeInd].reset();
    updateIPadGUI();
  }
  
  void touchXY(int touchNum, float x, float y) {
    if (frameCount % 10 == 0) println("Touch" + touchNum + " at " + nf(x,1,2) + " " + nf(y,1,2));
    modes[modeInd].setTouch(touchNum, x, y);
  }
  
  void mouseClicked() {
    Point p = new Point(mouseX,mouseY);
    if (display.getBox2D().contains(p)) {
      newEffect();
    }
    else if (display.getBox3D().contains(p)) {
      display.toggle3dRender();
    }
  }
  
  void tap() {
  }
  
  void debugPaletteType(String extra) {
    println(extra + " paletteType = " + settings.paletteType + " " + pm.getPaletteDisplayName() + (settings.palette == null?" (null)":" (not null)"));
  }
  
  void updateIPadGUI()
  {
    updateModeName();
    updatePaletteName();
  }
  
  void updateModeName() {
    String name = modes[modeInd].getName();
    settings.sendMessageToPad(settings.keyModeName, name);
  }
  
  void updatePaletteName() {
    settings.sendMessageToPad(settings.keyPaletteName, pm.getPaletteDisplayName());
  }
}

class Utility {
  public ArrayList<Integer> toIntegerList(int[] intArray) {
    ArrayList<Integer> intList = new ArrayList<Integer>();
    for (int index = 0; index < intArray.length; index++) {
      intList.add(intArray[index]);
    }
    return intList;
  }
  
  public int[] toIntArray(List<Integer> integerList) {
    int[] intArray = new int[integerList.size()];
    for (int i = 0; i < integerList.size(); i++) {
      intArray[i] = integerList.get(i);
    }
    return intArray;
  }
  
  public ArrayList<Boolean> toBooleanList(boolean[] booleanArray) {
    ArrayList<Boolean> booleanList = new ArrayList<Boolean>();
    for (int index = 0; index < booleanArray.length; index++) {
      booleanList.add(booleanArray[index]);
    }
    return booleanList;
  }
  
  public boolean[] toBooleanArray(List<Boolean> booleanList) {
    boolean[] boolArray = new boolean[booleanList.size()];
    for (int i = 0; i < booleanList.size(); i++) {
      boolArray[i] = booleanList.get(i);
    }
    return boolArray;
  }
}


