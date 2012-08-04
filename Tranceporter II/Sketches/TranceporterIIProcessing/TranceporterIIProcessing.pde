// The main sketch

import oscP5.*;
import netP5.*;
import ddf.minim.analysis.*;
import ddf.minim.*;
import java.util.Arrays;
import java.util.List;


//ADJUSTABLE PARAMS
int baud = 921600;
//int baud = 0;
String iPadIP = "10.0.1.8";
int ledWidth = 32;
int ledHeight = 17;
int screenPixelSize = 8;
int screenWidth = 800;
int screenHeight = 400; 

Pixels px;
SerialPacketWriter spw;
Console console;


int NUM_COLORS = 512;
//int FRAME_RATE = 100;

//HashMap controlInfo;
float DEFAULT_GAMMA = 2.5;

// Audio
BeatDetect bd;
int HISTORY_SIZE = 50;
int SAMPLE_SIZE = 1024;
int NUM_BANDS = 3;
boolean[] analyzeBands = {true, true, true };
int SAMPLE_RATE = 44100;
//AudioSocket signal;
AudioInput in;
AudioOutput out;
FFT fft;
Minim minim;
int MAX_BEAT_LENGTH = 750, MAX_AUDIO_SENSITIVITY = 12;

Drawer[] modes;
int modeInd = 0;
Utility utility = new Utility();

PaletteManager pm = new PaletteManager();
Settings settings = new Settings(NUM_BANDS);

void setup() {
  size(screenWidth, screenHeight);
  
  // redirect stdout/err
  try {
    console = new Console();
  } catch(Exception e) {
    println("Error redirecting stdout/stderr: " + e);
  }
  
  try {
    px = new Pixels(this, ledWidth, ledHeight, screenPixelSize, baud);
    println("### Started at " + baud);
  } catch (Exception e) {
    baud = 0;
    px = new Pixels(this, ledWidth, ledHeight, screenPixelSize, baud);
    println("### Started in standalone mode");
  }
  
  modes = new Drawer[] { new Paint(px, settings), new Bzr3(px, settings), 
                         new Fire(px, settings), new AlienBlob(px, settings), new BouncingBalls2D(px, settings) }; 

  settings.initOSC();

  modes[modeInd].setup();

  pm.init(this);
  updatePaletteName();
  newPalette();  
  
  // Audio features
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, SAMPLE_SIZE, SAMPLE_RATE);
  fft = new FFT(SAMPLE_SIZE, SAMPLE_RATE);  

  bd = new BeatDetect(fft, NUM_BANDS, HISTORY_SIZE);
  for (int i=0; i<NUM_BANDS; i++) bd.analyzeBand(i, analyzeBands[i]);
  bd.setFFTWindow(FFT.HAMMING);

  frameRate(SAMPLE_RATE/SAMPLE_SIZE);
  println("Done setup");
}

//long lastDraw = millis();
void draw() {
  if (key == ' ')
    return;
  
  for (int i=0; i<NUM_BANDS; i++) {
    float audioSensitivity = 1 - settings.getParam(settings.getKeyAudioSensitivity(i));
    bd.setSensitivity(i, audioSensitivity * MAX_AUDIO_SENSITIVITY, (int)(settings.getParam(settings.keyBeatLength)*MAX_BEAT_LENGTH));
  }
  bd.update(in.mix);
  for (int i=0; i<NUM_BANDS; i++) settings.setIsBeat(i, bd.isBeat("spectralFlux", i));

//  if (millis() - lastDraw < 1000.0/FRAME_RATE) return;
  
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
  px.drawToScreen();                 
  if (baud != 0) px.drawToLedWall(); 
  
//  lastDraw = millis();  
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

void newProgram() {
  int oldMode = modeInd;
  modeInd = (modeInd + 1) % modes.length;
  println("newProgram " + modes[oldMode].getName() + " -> "+ modes[modeInd].getName());

  // Each mode tracks its own settings
  Object newSettings = modes[modeInd].getSettingsBackup();
  Object oldSettings = settings.switchSettings(newSettings);
  modes[oldMode].setSettingsBackup(oldSettings);
  if (settings.palette == null ) {
    settings.palette = new color[NUM_COLORS];
  }
  pm.setPaletteType(settings.paletteType, NUM_COLORS, settings.palette);
  modes[modeInd].setup();
  assert(settings.palette != null);
  settings.sendAllSettingsToPad();
  updateIPadGUI();
}


interface VoidFunction { void function(); }
interface FunctionFloatFloat { void function(float x, float y); }

void reset() {
  modes[modeInd].reset();
  updateIPadGUI();
}

void touchXY(int touchNum, float x, float y) {
  if (frameCount % 10 == 0) println("Touch" + touchNum + " at " + nf(x,1,2) + " " + nf(y,1,2));
  modes[modeInd].setTouch(touchNum, x, y);
}

void mouseClicked() {
  println("got click");
  newProgram();
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


class Settings {
  private color[] palette;
  private boolean[] isBeat;
  private HashMap paramMap;
  private HashMap actions;
  private int numBands;
  private OscP5 oscP5;
  private NetAddress oscReceiver;
  private int paletteType;
  List<String> keyNames;
  
  final String keySpeed="/1/fader1";
  final String keyColorCyclingSpeed="/1/fader2";
  final String keyCustom1="/1/fader3";
  final String keyCustom2="/1/fader4";
  final String keyBrightness="/1/rotary1";
  final String keyAudioSpeedChange1 = "/2/multifader1/1";
  final String keyAudioSpeedChange2 = "/2/multifader1/2";
  final String keyAudioSpeedChange3 = "/2/multifader1/3";
  final String keyAudioColorChange1 = "/2/multifader2/1";
  final String keyAudioColorChange2 = "/2/multifader2/2";
  final String keyAudioColorChange3 = "/2/multifader2/3";
  final String keyAudioBrightnessChange1 = "/2/multifader3/1";
  final String keyAudioBrightnessChange2 = "/2/multifader3/2";
  final String keyAudioBrightnessChange3 = "/2/multifader3/3";
  final String keyAudioSensitivity1 = "/2/multifader4/1";
  final String keyAudioSensitivity2 = "/2/multifader4/2";
  final String keyAudioSensitivity3 = "/2/multifader4/3";
  final String keyBeatLength = "/2/rotary1";
  
  final String keyModeName = "/1/mode/";
  final String keyPaletteName = "/1/palette/";
  
  Settings(int numBands) {
    
    //TODO: Skotch: I tried to do this with reflection, but gave up when I got permission errors
    keyNames = Arrays.asList(
      keySpeed, keyColorCyclingSpeed,keyCustom1,keyCustom2, keyBrightness,
      keyAudioSpeedChange1, keyAudioSpeedChange2, keyAudioSpeedChange3,
      keyAudioColorChange1, keyAudioColorChange2, keyAudioColorChange3,
      keyAudioBrightnessChange1, keyAudioBrightnessChange2, keyAudioBrightnessChange3,
      keyAudioSensitivity1, keyAudioSensitivity2, keyAudioSensitivity3,
      keyBeatLength);

    //    keyNames =  new ArrayList();
    //    Class cls = this.getClass();
    //
    //    Field fieldlist[] = cls.getDeclaredFields();
    //    for (int i = 0; i < fieldlist.length; i++) {
    //      Field fld = fieldlist[i];
    //      String name = fld.getName();
    //      if (name.startsWith("key")
    //          && fld.getType() == String.class
    //          && Modifier.isFinal(fld.getModifiers(this))) {
    //
    //        fld.setAccessible(true);
    //        println("Field name=" + name);
    //        println("Field value=" + fld.get(null));
    //        keyNames.add(name);
    //      }
    //    }

    this.numBands = numBands;
    setDefaultSettings();
    
    actions = new HashMap();
    actions.put("/1/multixy1/1",  new FunctionFloatFloat() {
              public void function(float x, float y) {
                touchXY(1, x, y);
              }});
    actions.put("/1/multixy1/2",  new FunctionFloatFloat() {
              public void function(float x, float y) {
                touchXY(2, x, y);
              }});
    actions.put("/1/multixy1/3",  new FunctionFloatFloat() {
            public void function(float x, float y) {
              touchXY(3, x, y);
            }});
    actions.put("/1/multixy1/4",  new FunctionFloatFloat() {
            public void function(float x, float y) {
              touchXY(4, x, y);
            }});
    actions.put("/1/multixy1/5",  new FunctionFloatFloat() {
            public void function(float x, float y) {
              touchXY(5, x, y);
            }});
    actions.put("/1/push1",       new VoidFunction() {
            public void function() {
              newProgram();
            }});
    actions.put("/1/push2",       new VoidFunction() {
            public void function() {
              newPaletteType();
            }});
    actions.put("/1/push3",       new VoidFunction() {
            public void function() {
              newPalette();
            }});
    actions.put("/1/push4",       new VoidFunction() {
            public void function() {
              reset();
            }});
    actions.put("/2/push1",       new VoidFunction() {
            public void function() {
              tap();
            }});

   }
  
  int numBands() {
    return numBands;
  }
  
  color[] getPalette() {
    return palette;
  }

  boolean isBeat(int band) {
    return isBeat[band];
  }
  
  void setIsBeat(int band, boolean state) {
    isBeat[band] = state;
  }
  
  float beatPos(int band) {
    return bd.beatPos("spectralFlux", band);
  }
  
  float beatPosSimple(int band) {
    return bd.beatPosSimple("spectralFlux", band);
  }
  
  ////////////////////////////////////////////////////////////////////
  //General Setting Management

  void setParam(String paramName, float value) {
    paramMap.put(paramName, value);
  }
  
  float getParam(String paramName) {
    assert(keyNames.contains(paramName));
    
    if (paramName.equals(settings.keySpeed)) {
      float speed = (Float) paramMap.get(paramName);
      for (int i=0; i<NUM_BANDS; i++) {
        if (isBeat(i)) {
          speed += beatPos(i)*(Float)paramMap.get(getKeyAudioSpeedChange(i));
        }
      }
      return constrain(speed, 0, 1);
    }
    
    return (Float) paramMap.get(paramName);
  }
  
  void setDefaultSettings() {
    isBeat = new boolean[numBands];
    paramMap = new HashMap();
    palette = null;
    paletteType = 0;
    
    setParam(keySpeed,0.3);
    setParam(keyColorCyclingSpeed,0.3);
    setParam(keyCustom1,0.3);
    setParam(keyCustom2,0.3);
    setParam(keyBrightness,0.5);
    setParam(keyAudioSpeedChange1,0.3);
    setParam(keyAudioSpeedChange2,0.3);
    setParam(keyAudioSpeedChange3,0.3);
    setParam(keyAudioColorChange1,0.3);
    setParam(keyAudioColorChange2,0.3);
    setParam(keyAudioColorChange3,0.3);
    setParam(keyAudioBrightnessChange1,0.3);
    setParam(keyAudioBrightnessChange2,0.3);
    setParam(keyAudioBrightnessChange3,0.3);
    setParam(keyAudioSensitivity1,0.3);
    setParam(keyAudioSensitivity2,0.3);
    setParam(keyAudioSensitivity3,0.3);
    setParam(keyBeatLength,0.5);
  }

  public Object switchSettings(Object newSettings) {
    
    HashMap saver = new HashMap();
    saver.put("1",paramMap);
    saver.put("2",utility.toIntegerList(palette));
    saver.put("3",utility.toBooleanList(isBeat));
    saver.put("4",paletteType);
    
    if (newSettings == null) {
      println("newSettings are null");
      setDefaultSettings();
    }
    else {
      HashMap setter = (HashMap)newSettings;
      paramMap = (HashMap)setter.get("1");
      palette = utility.toIntArray((ArrayList<Integer>)setter.get("2"));
      isBeat = utility.toBooleanArray((ArrayList<Boolean>)setter.get("3"));
      paletteType = (Integer)setter.get("4");
      assert(palette != null);
    }
    return saver;
  }
  

 
////////////////////////////////////////////////////////////////////
//Key helpers

  String getKeyAudioSpeedChange(int index) {
    switch(index) {
      case 0:
        return settings.keyAudioSpeedChange1;
      case 1:
        return settings.keyAudioSpeedChange2;
      case 2:
        return settings.keyAudioSpeedChange3;
      default:
        assert(false);
    }
    return null;
  }
  
  String getKeyAudioColorChange(int index) {
    switch(index) {
      case 0:
        return settings.keyAudioColorChange1;
      case 1:
        return settings.keyAudioColorChange2;
      case 2:
        return settings.keyAudioColorChange3;
      default:
        assert(false);
    }
    return null;
  }
  
  String getKeyAudioBrightnessChange(int index) {
    switch(index) {
      case 0:
        return settings.keyAudioBrightnessChange1;
      case 1:
        return settings.keyAudioBrightnessChange2;
      case 2:
        return settings.keyAudioBrightnessChange3;
      default:
        assert(false);
    }
    return null;
  }
  
  String getKeyAudioSensitivity(int index) {
    switch(index) {
      case 0:
        return settings.keyAudioSensitivity1;
      case 1:
        return settings.keyAudioSensitivity2;
      case 2:
        return settings.keyAudioSensitivity3;
      default:
        assert(false);
    }
    return null;
  }
  
  
////////////////////////////////////////////////////////////////////
//OSC 5 stuff
  void initOSC() {
    oscP5 = new OscP5(this,8000);
    oscReceiver = new NetAddress(iPadIP,9000);

    sendAllSettingsToPad();
    updateIPadGUI();
//    enableControl(keySpeed, false);
  }

  private void enableControl(String controlKey, boolean enabled) {
    sendMessageToPad(controlKey + "/visible",enabled?"1":"0");
  }
  
  
  // send param values to the iPad if they've been updated from within the mode
  //void sendParamsOSC() {
  //  for (int i=0; i<lastParams.length; i++) {
  //    if (currParams[i] != lastParams[i]) {
  //      println("Setting param " + i + " value from mode via OSC: " + currParams[i]);
  //      OscMessage myMessage;
  //      if (i < NUM_FADERS) {
  //        myMessage = new OscMessage("/1/fader" + (i+1) + "/");
  //      } else {
  //        myMessage = new OscMessage("/1/rotary" + (i+1-NUM_FADERS) + "/");
  //      }
  //
  //      myMessage.add(currParams[i]);
  //      oscP5.send(myMessage, oscReceiver);
  //
  //      lastParams[i] = currParams[i];
  //    }
  //  }
  //}
  
  /* unplugged OSC messages */
  void oscEvent(OscMessage msg) {
    String addr = msg.addrPattern();
    
    try {
      String ipAddress = msg.netAddress().address();
      if (ipAddress != null && ipAddress.length() > 0 && !ipAddress.equals(iPadIP)) {
        detectedNewIPadAddress(ipAddress);
      }
      
      Object func = actions.get(addr);
      if (func != null) {
        println("\naction  = " + addr);
        if (addr.indexOf("push") >= 0) {
          if (msg.get(0).floatValue() != 1.0) {
            ((VoidFunction)func).function();
          }
        }
        else if (addr.indexOf("multixy") >= 0) {
          ((FunctionFloatFloat)func).function(msg.get(0).floatValue(), msg.get(1).floatValue());
        }
        return;
      }
      
      if (keyNames.contains(addr)) {
        float value = msg.get(0).floatValue();
        setParam(addr, value);
        println("Set " + addr + " to " + value);
        return;
      }
      
      if (addr.equals("/1") || addr.equals("/2")) {
        //just a page change, ignore
        return;
      }
      
      print("### Received an unhandled osc message: " + msg.addrPattern() + " " + msg.typetag() + " ");
      Object[] args = msg.arguments();
      for (int i=0; i<args.length; i++) {
        print(args[i].toString() + " ");
      }
      println();
    } catch (Exception e) {
      // Print out the exception that occurred
      System.out.println("Action Exception " + addr + ": " + e.getMessage());
      e.printStackTrace();
    }
  }

  private void detectedNewIPadAddress(String ipAddress)
  {
    println("detected new iPad address: " + iPadIP + " -> " + ipAddress);
    iPadIP = ipAddress; //once the iPad contacts us, we can contact them, if the hardcoded IP address is wrong
    oscReceiver = new NetAddress(iPadIP,9000);
    updateIPadGUI();
  }
  
  void sendMessageToPad(String key, String value) {
    OscMessage myMessage = new OscMessage(key);
    myMessage.add(value);
    oscP5.send(myMessage, oscReceiver);
  }

  void sendMessageToPad(String key, float value) {
    OscMessage myMessage = new OscMessage(key);
    myMessage.add(value);
    oscP5.send(myMessage, oscReceiver);
  }

  void sendAllSettingsToPad() {
    for (Object controlName : paramMap.keySet()) {
      float value = (Float)paramMap.get(controlName);
      sendMessageToPad((String)controlName, value);
    }
  }
  

}
