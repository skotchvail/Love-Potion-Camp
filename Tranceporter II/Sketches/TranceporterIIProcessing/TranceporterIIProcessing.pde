// The main sketch

import java.util.Arrays;
import java.util.List;
import java.util.prefs.Preferences;

import ddf.minim.*;

//ADJUSTABLE PARAMS
String iPadIP = "10.0.1.8";
final int ledWidth = 92 * 2; // Both sides
final int ledHeight = 58;
final int screenPixelSize = 3;
final int screenWidth = 950;
final int screenHeight = 400;

final int SAMPLE_RATE = 44100;
final int SAMPLE_SIZE = 512;
final int FRAME_RATE = 24;

int FFT_BAND_PER_OCT  = 12;
int FFT_BASE_FREQ     = 55;

boolean draw2dGrid;
boolean draw3dSimulation;
boolean useTotalControlHardware;
boolean needToFlushPrefs;
boolean pauseAnimations;
float rotationSpeed;
float factorLowU = 0.2, factorHighU = 0.02, factorLowV = 0.02, factorHighV = 0.13;

MainClass main;
Utility utility;
Preferences prefs;
Point location;

interface VoidFunction { void function(); }
interface FunctionFloatFloat { void function(float x, float y); }
interface FunctionArgs { void function(Object[] args); }

void setup() {
  size(screenWidth, screenHeight, P2D);

  println("target FRAME_RATE:" + FRAME_RATE);
  utility = new Utility();
  prefs = Preferences.userNodeForPackage(this.getClass());
//  try {
//    prefs.clear();
//  }
//  catch(Exception e) {}
  draw2dGrid = prefs.getBoolean("draw2dGrid", true);
  useTotalControlHardware = prefs.getBoolean("useTotalControlHardware", false);
  draw3dSimulation = prefs.getBoolean("draw3dSimulation", true);
  rotationSpeed = prefs.getFloat("rotationSpeed", 1.0 / (FRAME_RATE * 30)); // default once every 30 seconds
  main = new MainClass();
  main.setup(this);
  prepareExitHandler();
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

private void prepareExitHandler() {

  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run () {
      main.shutdown();
  }
  }));
}

class MainClass {

  Pixels display;
  LedMap ledMap;
  Console console;

  int NUM_COLORS = 512;
  float DEFAULT_GAMMA = 2.5;

  // Audio
  BeatDetect beatDetect;
  int HISTORY_SIZE = 50;
  int NUM_BANDS = 3;
  boolean[] analyzeBands = {true, true, true };
  //AudioSocket signal;
  AudioInput audioIn;
  AudioOutput out;
  FFT fft;
  Minim minim;
  int MAX_BEAT_LENGTH = 750; // , MAX_AUDIO_SENSITIVITY = 12;
  HardwareTest hardwareTestEffect;

  Drawer[][] modes;
  ColumnRow whichEffect = new ColumnRow();
  float lastModeChangeTimeStamp;
  Point screenLocation = new Point();

  PaletteManager pm = new PaletteManager();
  Settings settings = new Settings(NUM_BANDS);
  WiimoteManager wiimoteManager = new WiimoteManager(settings);

  void setup(PApplet applet) {

    if (true) {
      // redirect stdout/err
      try {
        console = new Console();
      } catch(Exception e) {
        println("Error redirecting stdout/stderr: " + e);
      }
    }

    ledMap = new LedMap();
    display = new Pixels(applet);
    display.setup();

    hardwareTestEffect =  new HardwareTest(display, settings);

    modes = new Drawer[][] {
      //column 0
      {
        new Tunnel(display, settings),            //0, 0
        new Bzr3(display, settings),              //0, 1
        new Fire(display, settings),              //0, 2
        new Equalizer3d(display, settings),       //0, 3
        new FastPlasma(display, settings),        //0, 4
      },
      //column 1
      {
        new AlienBlob(display, settings),               //1, 0
        new BouncingBalls2D(display, settings, false),  //1, 1
        new Smoke(display, settings),                   //1, 2
        new DroppingParticles(display, settings),       //1, 3
        new BouncingBalls2D(display, settings, true),   //1, 4
      },
      //column 2
      {
        new Paint(display, settings),             //2, 0
        new EyeMotion(display, settings),         //2, 1
        new Heart(display, settings),             //2, 2

      },
      //column 3 (Hidden from GUI)
      {
        hardwareTestEffect,      //3, 0
      },

    };

    settings.initOSC();
    wiimoteManager.setup();
    pm.init(applet);

    whichEffect.column = prefs.getInt("whichEffect.column", 1);
    whichEffect.row = prefs.getInt("whichEffect.row", 3);

    if (whichEffect.column >= modes.length || whichEffect.row >= modes[whichEffect.column].length) {
        whichEffect = new ColumnRow(0, 0);
    }
    //settings.setSketchOn(2, 2, true);

    // Audio features
    minim = new Minim(applet);
    audioIn = minim.getLineIn(Minim.STEREO, SAMPLE_SIZE, SAMPLE_RATE);

    // create a new Fast Fourier Transform object
    fft = new FFT(SAMPLE_SIZE, SAMPLE_RATE);

    // Sets the number of averages used when computing
    // the spectrum based on the minimum bandwidth for an octave
    // and the number of bands per octave.
    fft.logAverages(FFT_BASE_FREQ, FFT_BAND_PER_OCT);
    System.out.println("Sound Control: FFT on " + fft.avgSize()
      + " log bands. samplerate: " + SAMPLE_RATE + "Hz. "
      + SAMPLE_RATE / SAMPLE_SIZE + " buffers of "
      + SAMPLE_SIZE + " samples per second.");

    // pause for 100 milliseconds - presumably to give the hardware time to catch up
    delay(100);

    // Sets the window to use on the samples
    // before taking the forward transform.
    // The result of using a window is to reduce the noise in the spectrum somewhat.
    fft.window(FFT.HAMMING);

    // create our new beat detect object (passing it the FFT as an argument)
    beatDetect = new BeatDetect(fft, NUM_BANDS, HISTORY_SIZE);

    // define which bands we are analyzing
    for (int i=0; i<NUM_BANDS; i++) {
      beatDetect.analyzeBand(i, analyzeBands[i]);
    }

    // // Sets the window to use on the samples
    // // before taking the forward transform.
    // @REVIEW now done above when we call fft.window();
    // Because why not do it here where we're initializing the object already?
    // beatDetect.setFFTWindow();

    newEffectFirstTime();

    frameRate(FRAME_RATE);

    settings.sendEntireGUIToIPad();
    currentMode().justEnteredSketch();

    println("Done setup");
  }

  void shutdown() {
    ledMap.shutdown();
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

    if (frameCount == 2) {
      screenLocation.x = prefs.getInt("screenLocationX", 0);
      screenLocation.y = prefs.getInt("screenLocationY", 0);
      frame.setLocation(screenLocation);
    }
    else if (frameCount % 60 == 58) {
      if (!screenLocation.equals(frame.getLocation())) {
        screenLocation = frame.getLocation();
        prefs.putInt("screenLocationX", screenLocation.x);
        prefs.putInt("screenLocationY", screenLocation.y);
      }
    }

    if (pauseAnimations)
      return;

    settings.handleQueuedOSCEvents();

    beatDetect.update(audioIn.mix);

    for (int i=0; i<NUM_BANDS; i++)
      settings.setIsBeat(i, beatDetect.isBeat("spectralFlux", i));
    Drawer d = currentMode();

    if (settings.palette == null) {
      assert(settings.palette != null);
      // println("can't draw, palett is null");
      return;
    }

    d.update();
    display.drawToScreen();
    ledMap.drawToLeds();

    if (settings.millisBetweenAutoChanges() < millis() - lastModeChangeTimeStamp) {
      newEffect();
    }
  }

  ArrayList<String> getKeymapLines() {

    ArrayList<String> myStrings = new ArrayList();
    myStrings.add(new String("space\tfreeze"));
    myStrings.add(new String("n\tnext Sketch"));
    String hardwareOnString = ledMap.runConcurrent ? "(on faster parallel)": "(on slower non-parallel)";
    if (!useTotalControlHardware) {
      hardwareOnString = "(off)";
    }
    myStrings.add(new String("t\tconnect to Hardware " + hardwareOnString));
    myStrings.add(new String("p\tprogram LED's"));
    myStrings.add(new String("2 3\tshow/hide 2d or 3d display"));
    myStrings.add(new String("[ ]\t3D display rotation speed"));

    return myStrings;
  }

  void keyPressed() {

    if (key == ' ') {
      pauseAnimations = !pauseAnimations;
    }
    else if (key == 'n') {
      println("switching to new effect");
      newEffect();
    }
    else if (key == '2') {
      draw2dGrid = !draw2dGrid;
      prefs.putBoolean("draw2dGrid", draw2dGrid);
      needToFlushPrefs = true;
      println("2D grid: " + draw2dGrid);
    }
    else if (key == '3') {
      draw3dSimulation = !draw3dSimulation;
      prefs.putBoolean("draw3dSimulation", draw3dSimulation);
      needToFlushPrefs = true;
      println("3D grid: " + draw3dSimulation);
    }
    else if (key == 't') {
      useTotalControlHardware = !useTotalControlHardware;
      prefs.putBoolean("useTotalControlHardware", useTotalControlHardware);
      needToFlushPrefs = true;
      println("useTotalControlHardware: " + useTotalControlHardware);
    }
    else if (key == 'p') {
      if (currentMode() != hardwareTestEffect
          ) {
        switchToDrawer(hardwareTestEffect);
      }
    }
    else if (key == ']') {
      rotationSpeed = max(rotationSpeed, 0.0004);
      rotationSpeed = min(rotationSpeed * 1.1, 1.0 / (FRAME_RATE * 0.5)); // Fastest once every half second
      prefs.putFloat("rotationSpeed", rotationSpeed);
      needToFlushPrefs = true;
      //println("rotationSpeed = " + nf(rotationSpeed, 1, 4));
    }
    else if (key == '[') {
      rotationSpeed = rotationSpeed * 0.92;
      if (rotationSpeed < 0.0005) {
        rotationSpeed = 0;
      }
      prefs.putFloat("rotationSpeed", rotationSpeed);
      needToFlushPrefs = true;
      //println("rotationSpeed = " + nf(rotationSpeed, 1, 4));
    }
    else if (key == 'F') {
      factorHighU = min(factorHighU + 0.01, 1.0);
      println("U = (" + factorLowU + " -> " + factorHighU + ") V = (" + factorLowV + " -> " + factorHighV + ")");
    }
    else if (key == 'S') {
      factorHighU = max(factorHighU - 0.01, 0.0);
      println("U = (" + factorLowU + " -> " + factorHighU + ") V = (" + factorLowV + " -> " + factorHighV + ")");
    }
    else if (key == 'E') {
      factorHighV = min(factorHighV + 0.01, 1.0);
      println("U = (" + factorLowU + " -> " + factorHighU + ") V = (" + factorLowV + " -> " + factorHighV + ")");
    }
    else if (key == 'D') {
      factorHighV = max(factorHighV - 0.01, 0.0);
      println("U = (" + factorLowU + " -> " + factorHighU + ") V = (" + factorLowV + " -> " + factorHighV + ")");
    }
    else if (key == 'f') {
      factorLowU = min(factorLowU + 0.01, 1.0);
      println("U = (" + factorLowU + " -> " + factorHighU + ") V = (" + factorLowV + " -> " + factorHighV + ")");
    }
    else if (key == 's') {
      factorLowU = max(factorLowU - 0.01, 0.0);
      println("U = (" + factorLowU + " -> " + factorHighU + ") V = (" + factorLowV + " -> " + factorHighV + ")");
    }
    else if (key == 'e') {
      factorLowV = min(factorLowV + 0.01, 1.0);
      println("U = (" + factorLowU + " -> " + factorHighU + ") V = (" + factorLowV + " -> " + factorHighV + ")");
    }
    else if (key == 'd') {
      factorLowV = max(factorLowV - 0.01, 0.0);
      println("U = (" + factorLowU + " -> " + factorHighU + ") V = (" + factorLowV + " -> " + factorHighV + ")");
    }
    else {
      println("pressed " + int(key) + " " + keyCode);
    }

    currentMode().keyPressed();
  }


  Drawer getMode(ColumnRow coord) {
    return modes[coord.column][coord.row];
  }

  Drawer currentMode() {
    return getMode(whichEffect);
  }

  void newPalette() {
    settings.palette = new color[NUM_COLORS];
    pm.getNewPalette(NUM_COLORS, settings.palette);
    settings.paletteType = pm.getPaletteType();
  }

  void newPaletteType() {
    pm.nextPaletteType();
    newPalette();
    settings.sendMessageToIPad(settings.keyPaletteName, pm.getPaletteDisplayName());
  }

  void newEffectFirstTime() {
    settings.palette = new color[NUM_COLORS];
    pm.setPaletteType(settings.paletteType, NUM_COLORS, settings.palette);
    Drawer mode = currentMode();
    mode.setup();
  }

  ColumnRow findNextMode() {

    // Scan from the current position to the end of the table
    for (int col = whichEffect.column; col < modes.length - 1; col++) {
      for (int row = 0; row < modes[col].length; row++) {
        if (col == whichEffect.column && row <= whichEffect.row)
          continue;

        if (settings.isSketchOn(col, row)) {
          return new ColumnRow(col, row);
        }
      }
    }

    // Scan from the start of the table to the current position
    for (int col = 0; col <= whichEffect.column && col < modes.length - 1; col++) {
      for (int row = 0; row < modes[col].length; row++) {
        if (col == whichEffect.column && row >= whichEffect.row)
          break;

        if (settings.isSketchOn(col, row)) {
          return new ColumnRow(col, row);
        }
      }
    }

    return whichEffect.clone();
  }

  void newEffect() {
    lastModeChangeTimeStamp = millis();
    ColumnRow coord = findNextMode();
    switchToNewEffect(coord);
  }

  void switchToNewEffect(ColumnRow newEffect) {
    prefs.putInt("whichEffect.column", newEffect.column);
    prefs.putInt("whichEffect.row", newEffect.row);
    needToFlushPrefs = true;

    println("newEffect " + currentMode().getName() + " -> "+ getMode(newEffect).getName());

    if (newEffect.column == whichEffect.column && newEffect.row == whichEffect.row) {
      return;
    }

    ColumnRow oldEffect = whichEffect;
    whichEffect = newEffect;

    // Each mode tracks its own settings
    Object newSettings = currentMode().getSettingsBackup();
    Object oldSettings = settings.switchSettings(newSettings);
    getMode(oldEffect).setSettingsBackup(oldSettings);

    if (newSettings == null) {
      newEffectFirstTime();
    }
    else {
      pm.setPaletteType(settings.paletteType, NUM_COLORS, settings.palette);
    }

    assert(settings.palette != null);
    settings.sendControlValuesForThisSketchToIPad();
    getMode(oldEffect).justExitedSketch();
    currentMode().justEnteredSketch();
  }

  void switchToDrawer(Drawer whichDrawer) {
    for (int col = 0; col < modes.length; col++) {
      for (int row = 0; row < modes[col].length; row++) {
        if (whichDrawer == modes[col][row]) {
          switchToNewEffect(new ColumnRow(col, row));
          assert(currentMode() == whichDrawer);
          return;
        }
      }
    }
    assert false : "cannot find Drawer to switch to: " + whichDrawer.getName();
  }

  void touchXY(int touchNum, float x, float y) {
    if (frameCount % 10 == 0) {
      println("Touch" + touchNum + " at " + nf(x, 1, 2) + " " + nf(y, 1, 2));
    }
    currentMode().setTouch(touchNum, x, y);
  }

  void mouseClicked() {
    Point p = new Point(mouseX, mouseY);
    Rectangle bounds = display.getBox2D();
    if (bounds.contains(p)) {
      Point convertedPoint = new Point(p);
      convertedPoint.translate(-bounds.x, -bounds.y);
      convertedPoint.x /= screenPixelSize;
      convertedPoint.y /= screenPixelSize;
      println("inside box: " + convertedPoint);
    }
    else {
      println("outside box");
    }
  }

  void debugPaletteType(String extra) {
    println(extra + " paletteType = " + settings.paletteType + " " + pm.getPaletteDisplayName() + (settings.palette == null?" (null)":" (not null)"));
  }
}

class ColumnRow implements Cloneable {
  int column;
  int row;

  ColumnRow() {
    column = 0;
    row = 0;
  }

  ColumnRow(int theColumn, int theRow) {
    column = theColumn;
    row = theRow;
  }

  ColumnRow clone() {
    return new ColumnRow(column, row);
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
