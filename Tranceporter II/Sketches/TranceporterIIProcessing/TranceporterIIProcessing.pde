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
  updatePaletteType();
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
    bd.setSensitivity(i, settings.getParam(settings.getKeyAudioSensitivity(i)) * MAX_AUDIO_SENSITIVITY, (int)(settings.getParam(settings.keyBeatLength)*MAX_BEAT_LENGTH));
  }
  bd.update(in.mix);
  for (int i=0; i<NUM_BANDS; i++) settings.setIsBeat(i, bd.isBeat("spectralFlux", i));

//  if (millis() - lastDraw < 1000.0/FRAME_RATE) return;
  
  Drawer d = modes[modeInd];

  assert(settings.palette != null);
  if (settings.palette == null) return;

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
}

void newPaletteType() {
  pm.nextPaletteType();
  newPalette();
  updateIPadGUI();
}

void newProgram() {
  modeInd = (modeInd + 1) % modes.length;
  modes[modeInd].setup();
  updateIPadGUI();
  println("Advancing to next mode: " + modes[modeInd].getName());
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

void updateIPadGUI()
{
  updateModeName();
  updatePaletteType();
}

void updateModeName() {
  String name = modes[modeInd].getName();
  settings.temp_SendMessage(settings.keyModeName, name);
}

void updatePaletteType() {
  settings.temp_SendMessage(settings.keyPaletteName, pm.getPaletteType());
}

class Settings {
  private color[] palette;
  private float[] params;
  private boolean[] isBeat;
  private HashMap paramMap;
  private HashMap controlMap;
  private HashMap actions;
  private int numBands;
  private int basePaletteColors = 1;
  private OscP5 oscP5;
  private NetAddress oscReceiver;
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
    isBeat = new boolean[numBands];
    paramMap = new HashMap();
    
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
  
  void setParam(String paramName, float value) {
    paramMap.put(paramName, value);
  }
  
  //float getParam(String paramName) { println(paramMap.keySet()); println(paramName); return (Float) paramMap.get(paramName); }
  
  float getParam(String paramName) {

    if (false) {
      println("*** getParam(" + paramName + ")");
      
      Object rawValue = paramMap.get(paramName);
      if (rawValue == null) {
        if (keyNames.contains(paramName)) {
          paramMap.put(paramName, 0.0);
        }
        else
          assert(false);
      }
    }
    if (paramName.equals(settings.keySpeed)) {
      float speed = (Float) paramMap.get(paramName);
      for (int i=0; i<NUM_BANDS; i++) {
        if (isBeat(i)) {
          speed += beatPos(i)*(Float)paramMap.get(getKeyAudioSpeedChange(i));
        }
      }
      return constrain(speed, 0, 1);
    }
    
    if (paramName.startsWith("/2/multifader4/")) { //audioSensitivity
      return 1 - (Float)paramMap.get(paramName);
    }
    
    return (Float) paramMap.get(paramName);
  }
  
  void setPalette(color[] p, int basePaletteColors) {
    palette = p;
    this.basePaletteColors = basePaletteColors;
  }
  
  color[] getPalette() {
    return palette;
  }
  
  int basePaletteColors() {
    return basePaletteColors;
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

    setAndSendParam(keySpeed,0.3);
    setAndSendParam(keyColorCyclingSpeed,0.3);
    setAndSendParam(keyCustom1,0.3);
    setAndSendParam(keyCustom2,0.3);
    setAndSendParam(keyBrightness,0.5);
    setAndSendParam(keyAudioSpeedChange1,0.0);
    setAndSendParam(keyAudioSpeedChange2,0.0);
    setAndSendParam(keyAudioSpeedChange3,0.0);
    setAndSendParam(keyAudioColorChange1,0.0);
    setAndSendParam(keyAudioColorChange2,0.0);
    setAndSendParam(keyAudioColorChange3,0.0);
    setAndSendParam(keyAudioBrightnessChange1,0.0);
    setAndSendParam(keyAudioBrightnessChange2,0.0);
    setAndSendParam(keyAudioBrightnessChange3,0.0);
    setAndSendParam(keyAudioSensitivity1,0.0);
    setAndSendParam(keyAudioSensitivity2,0.0);
    setAndSendParam(keyAudioSensitivity3,0.0);
    setAndSendParam(keyBeatLength,0.5);
    updateIPadGUI();
    enableControl(keySpeed, false);
  }

  
  void setAndSendParam(String paramName, float value) {
    setParam(paramName,value);
    temp_SendMessage(paramName,value);
  }

  
  private void enableControl(String controlKey, boolean enabled) {
    temp_SendMessage(controlKey + "/visible",enabled?"1":"0");
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
    String ipAddress = msg.netAddress().address();
    if (ipAddress != null && ipAddress.length() > 0 && !ipAddress.equals(iPadIP)) {
      detectedNewIPadAddress(ipAddress);
    }

    Object func = actions.get(addr);
    if (func != null) {
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

    print("### Received an unhandled osc message: " + msg.addrPattern() + " " + msg.typetag() + " ");
    Object[] args = msg.arguments();
    for (int i=0; i<args.length; i++) {
      print(args[i].toString() + " ");
    }
    println();
  }

  private void detectedNewIPadAddress(String ipAddress)
  {
    println("detected new iPad address: " + iPadIP + " -> " + ipAddress);
    iPadIP = ipAddress; //once the iPad contacts us, we can contact them, if the hardcoded IP address is wrong
    oscReceiver = new NetAddress(iPadIP,9000);
    updateIPadGUI();
  }
  
  void temp_SendMessage(String key, String value) {
    OscMessage myMessage = new OscMessage(key);
    myMessage.add(value);
    oscP5.send(myMessage, oscReceiver);
  }

  void temp_SendMessage(String key, float value) {
    OscMessage myMessage = new OscMessage(key);
    myMessage.add(value);
    oscP5.send(myMessage, oscReceiver);
  }

}
