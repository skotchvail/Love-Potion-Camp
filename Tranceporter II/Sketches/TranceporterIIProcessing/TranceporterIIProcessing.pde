// The main sketch

import oscP5.*;
import netP5.*;
import ddf.minim.analysis.*;
import ddf.minim.*;
import java.util.Arrays;
import java.util.List;
import java.util.prefs.Preferences;


//ADJUSTABLE PARAMS
String iPadIP = "10.0.1.8";
int ledWidth = 60;
int ledHeight = 60;
int screenPixelSize = 5;
int screenWidth = 700;
int screenHeight = 400;

int SAMPLE_RATE = 44100;
int SAMPLE_SIZE = 1024;
int FRAME_RATE = SAMPLE_RATE/SAMPLE_SIZE;


boolean draw2dGrid;
boolean draw3dSimulation;
boolean needToFlushPrefs;
MainClass main;
Utility utility;
Preferences prefs;

interface VoidFunction { void function(); }
interface FunctionFloatFloat { void function(float x, float y); }
  
void setup() {
  size(screenWidth, screenHeight);
  
  println("target FRAME_RATE:" + FRAME_RATE);
  utility = new Utility();
  prefs = Preferences.userNodeForPackage(this.getClass());
  draw2dGrid = prefs.getBoolean("draw2dGrid", true);
  draw3dSimulation = prefs.getBoolean("draw3dSimulation", true);
  main = new MainClass();
  main.setup(this);
}

void draw() {
  main.draw();
}

void mouseClicked() {
  main.mouseClicked();
}

void keyPressed() {
    main.keyPressed();
}


class MainClass {
  
  Pixels display;
  Console console;

  int NUM_COLORS = 512;
  float DEFAULT_GAMMA = 2.5;
  
  // Audio
  BeatDetect bd;
  int HISTORY_SIZE = 50;
  int NUM_BANDS = 3;
  boolean[] analyzeBands = {true, true, true };
  //AudioSocket signal;
  AudioInput audioIn;
  AudioOutput out;
  FFT fft;
  Minim minim;
  int MAX_BEAT_LENGTH = 750, MAX_AUDIO_SENSITIVITY = 12;
  
  Drawer[][] modes;
  int modeCol;
  int modeRow;
  float lastModeChangeTimeStamp;
  
  PaletteManager pm = new PaletteManager();
  Settings settings = new Settings(NUM_BANDS);

  void setup(PApplet applet) {
    
    // redirect stdout/err
    try {
      console = new Console();
    } catch(Exception e) {
      println("Error redirecting stdout/stderr: " + e);
    }
    
    display = new LedMap(applet);
    display.setup();
    
    modes = new Drawer[][] {
      //column 0
      {
        new Tunnel(display,settings),             //0,0
        new Bzr3(display, settings),              //0,1
        new Fire(display, settings),              //0,2
        new Equalizer3d(display, settings),       //0,32
      },
      //column 1
      {
        new AlienBlob(display, settings),         //1,0
        new BouncingBalls2D(display, settings),   //1,1
        new Smoke(display, settings),             //1,2
        new DroppingParticles(display, settings), //1,3
      },
      //column 2
      {
        new HardwareTest(display, settings),      //2,0
        new Paint(display, settings),             //2,1
        new EyeMotion(display, settings),         //2,2
        new Heart(display, settings),             //2,3

      }
    };
    settings.initOSC();
    pm.init(applet);

    modeCol = prefs.getInt("modeCol",1);
    modeRow = prefs.getInt("modeRow",0);
    
    // Audio features
    minim = new Minim(applet);
    audioIn = minim.getLineIn(Minim.STEREO, SAMPLE_SIZE, SAMPLE_RATE);
    fft = new FFT(SAMPLE_SIZE, SAMPLE_RATE);
    
    bd = new BeatDetect(fft, NUM_BANDS, HISTORY_SIZE);
    for (int i=0; i<NUM_BANDS; i++)
      bd.analyzeBand(i, analyzeBands[i]);
    bd.setFFTWindow(FFT.HAMMING);
    
    newEffectFirstTime();
    
    //frameRate(SAMPLE_RATE/SAMPLE_SIZE);
    frameRate(FRAME_RATE);
    
    settings.sendAllSettingsToPad();
    updateIPadGUI();
    
    println("Done setup");
  }

  void draw() {
    
    if (needToFlushPrefs) {
      needToFlushPrefs = false;
      try {
        prefs.flush();
      } catch(Exception e) {
        println("main flushing prefs: " + e);
      }
    }
    
    if (key == ' ')
      return;
    
    settings.heartBeat();
    
    for (int i=0; i<NUM_BANDS; i++) {
      float userSet = settings.getParam(settings.getKeyAudioSensitivity(i));
      float audioSensitivity = 1 - userSet;
      bd.setSensitivity(i, audioSensitivity * MAX_AUDIO_SENSITIVITY, (int)(settings.getParam(settings.keyBeatLength)*MAX_BEAT_LENGTH));
      bd.analyzeBand(i,(userSet != 0));
      
    }
    bd.update(audioIn.mix);
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
    
    if (settings.millisBetweenAutoChanges() < millis() - lastModeChangeTimeStamp) {
      newEffect();
    }
  }
  
  
  void keyPressed() {
    
    if (key == 'n') {
      println("switching to new effect");
      newEffect();
    }
    
    if (key == '2') {
      draw2dGrid = !draw2dGrid;
      prefs.putBoolean("draw2dGrid", draw2dGrid);
      needToFlushPrefs = true;
      println("2D grid: " + draw2dGrid);
    }
    
    if (key == '3') {
      draw3dSimulation = !draw3dSimulation;
      prefs.putBoolean("draw3dSimulation", draw3dSimulation);
      needToFlushPrefs = true;
      println("3D grid: " + draw3dSimulation);
    }
    
    modes[modeCol][modeRow].keyPressed();
  }
  
  Drawer currentMode() {
    return modes[modeCol][modeRow];
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
    Drawer mode = modes[modeCol][modeRow];
    mode.setup();
    mouseX = mode.mouseX; //let the mode set the mouseX,Y in their setup and honor that.
    mouseY = mode.mouseY;
    
    println("Initial mouseX:" + mouseX + " mouseY: " + mouseY);
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
    lastModeChangeTimeStamp = millis();
    
    int oldModeCol = modeCol;
    int oldModeRow = modeRow;
    findNextMode();
    prefs.putInt("modeCol",modeCol);
    prefs.putInt("modeRow",modeRow);
    needToFlushPrefs = true;
    
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
  }
  
  void debugPaletteType(String extra) {
    println(extra + " paletteType = " + settings.paletteType + " " + pm.getPaletteDisplayName() + (settings.palette == null?" (null)":" (not null)"));
  }
  
  void updateIPadGUI()
  {
    settings.updateLabelForAutoChanger();
    
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


