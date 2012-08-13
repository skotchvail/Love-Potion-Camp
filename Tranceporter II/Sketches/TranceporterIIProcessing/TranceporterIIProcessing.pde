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
int FRAME_RATE = 60;


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
  
  Drawer[][] modes;
  int modeCol = 0;
  int modeRow = 0;

  
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
    
    modes = new Drawer[][] {
      //column 0
      {
        new Tunnel(display,settings),             //0,0
        new Paint(display, settings),             //0,1
        new Bzr3(display, settings),              //0,2
        new Fire(display, settings),              //0,3
        new Equalizer3d(display, settings),       //0,4
      },
      //column 1
      {
        new AlienBlob(display, settings),         //1,0
        new BouncingBalls2D(display, settings),   //1,1
        new Smoke(display, settings),             //1,2
        new Heart(display, settings),             //1,3
        new DroppingParticles(display, settings), //1,4
      },
      //column 2
      {
        new HardwareTest(display, settings),      //2,0
        new EyeMotion(display, settings),         //2,1
      }
    };
    
    settings.initOSC();
    pm.init(applet);

    settings.setSketchOn(0, 0, true); //Tunnel
    settings.setSketchOn(0, 2, true); //Bzr
    settings.setSketchOn(0, 3, true); //Fire
    settings.setSketchOn(1, 0, true); //AlienBlob

    settings.setSketchOn(1, 3, true); //Heart
    modeCol = 2;
    modeRow = 1; //Eye Motion
    
    newEffectFirstTime();
    
    // Audio features
    minim = new Minim(applet);
    in = minim.getLineIn(Minim.STEREO, SAMPLE_SIZE, SAMPLE_RATE);
    fft = new FFT(SAMPLE_SIZE, SAMPLE_RATE);
    
    bd = new BeatDetect(fft, NUM_BANDS, HISTORY_SIZE);
    for (int i=0; i<NUM_BANDS; i++)
      bd.analyzeBand(i, analyzeBands[i]);
    bd.setFFTWindow(FFT.HAMMING);
    
    //frameRate(SAMPLE_RATE/SAMPLE_SIZE);
    frameRate(FRAME_RATE);
    
    settings.sendAllSettingsToPad();
    updateIPadGUI();
    
    println("Done setup");
  }

  void draw() {
    if (key == ' ')
      return;
    
    settings.heartBeat();
    
    for (int i=0; i<NUM_BANDS; i++) {
      float userSet = settings.getParam(settings.getKeyAudioSensitivity(i));
      float audioSensitivity = 1 - userSet;
      bd.setSensitivity(i, audioSensitivity * MAX_AUDIO_SENSITIVITY, (int)(settings.getParam(settings.keyBeatLength)*MAX_BEAT_LENGTH));
      bd.analyzeBand(i,(userSet != 0));
      
    }
    bd.update(in.mix);
    for (int i=0; i<NUM_BANDS; i++)
      settings.setIsBeat(i, bd.isBeat("spectralFlux", i));
    Drawer d = modes[modeCol][modeRow];
    
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
    modes[modeCol][modeRow].setup();
  }
  
  void findNextMode() {
    
    int oldModeCol = modeCol;
    int oldModeRow = modeRow;

    for (int col = oldModeCol; col < modes.length; col++) {
      for (int row = 0; row < modes[col].length; row++) {
        if (col == oldModeCol && row <= oldModeRow)
          continue;
        
        println("loop1 col" + col + " row" + row + " on:" + settings.isSketchOn(col,row));
        
        if (settings.isSketchOn(col,row)) {
          modeCol = col;
          modeRow = row;
          return;
        }
      }
    }
    
    if (modeCol == oldModeCol && modeRow == oldModeRow) {
      
      for (int col = 0; col <= oldModeCol; col++) {
        for (int row = 0; row < modes[col].length; row++) {
          if (col == oldModeCol && row >= oldModeRow)
            break;
          
          println("loop2 col" + col + " row" + row + " on:" + settings.isSketchOn(col,row));
          
          if (settings.isSketchOn(col,row)) {
            modeCol = col;
            modeRow = row;
            return;
          }
        }
      }
    }
  }
  
  void newEffect() {
    int oldModeCol = modeCol;
    int oldModeRow = modeRow;
    findNextMode();
    
    println("newEffect " + modes[oldModeCol][oldModeRow].getName() + " -> "+ modes[modeCol][modeRow].getName());
    
    if (modeCol == oldModeCol && modeRow == oldModeRow) {
      return;
    }
    
    // Each mode tracks its own settings
    Object newSettings = modes[modeCol][modeRow].getSettingsBackup();
    Object oldSettings = settings.switchSettings(newSettings);
    modes[oldModeCol][oldModeRow].setSettingsBackup(oldSettings);
    
    if (newSettings == null) {
      newEffectFirstTime();
    }
    else {
      pm.setPaletteType(settings.paletteType, NUM_COLORS, settings.palette);
    }

    assert(settings.palette != null);
    settings.sendAllSettingsToPad();
    updateIPadGUI();
  }
  
  void reset() {
    modes[modeCol][modeRow].reset();
    updateIPadGUI();
  }
  
  void touchXY(int touchNum, float x, float y) {
    if (frameCount % 10 == 0) println("Touch" + touchNum + " at " + nf(x,1,2) + " " + nf(y,1,2));
    modes[modeCol][modeRow].setTouch(touchNum, x, y);
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
  
  void debugPaletteType(String extra) {
    println(extra + " paletteType = " + settings.paletteType + " " + pm.getPaletteDisplayName() + (settings.palette == null?" (null)":" (not null)"));
  }
  
  void updateIPadGUI()
  {
    String name = modes[modeCol][modeRow].getName();
    settings.sendMessageToPad(settings.keyModeName, name);
    
    name = modes[modeCol][modeRow].getCustom1Label();
    settings.sendMessageToPad(settings.keyCustom1Label, name);
    
    name = modes[modeCol][modeRow].getCustom2Label();
    settings.sendMessageToPad(settings.keyCustom2Label, name);
    
    settings.sendMessageToPad(settings.keyPaletteName, pm.getPaletteDisplayName());
    
    for (int col = 0; col < modes.length; col++) {
      for (int row = 0; row < modes[col].length; row++) {
        name = modes[col][row].getName();
        settings.sendMessageToPad(settings.sketchLabelName(col,row),name);
      }
    }
    
    settings.sendSketchesToPad();
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


