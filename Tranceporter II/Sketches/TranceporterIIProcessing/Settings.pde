import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.net.SocketException;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

import com.qindesign.osc.OscBundle;
import com.qindesign.osc.OscDatagramClient;
import com.qindesign.osc.OscDatagramServer;
import com.qindesign.osc.OscMessage;
import com.qindesign.osc.OscPacket;
import com.qindesign.osc.OscPacketReceiver;

class Settings implements OscPacketReceiver {
  private java.net.InetAddress localhost;
  {
    try {
      localhost = InetAddress.getLocalHost();
    } catch (java.net.UnknownHostException ex) {
      // Shouldn't happen
      throw new RuntimeException(ex);
    }
  }

  private boolean[][] whichModes = new boolean[4][5];
  private color[] palette;
  private boolean[] isBeat;
  private Map<String, Float> paramMap; // Values of controls specific to any Sketch
  private Map<String, Float> paramGlobalMap; // Values of controls that control all Sketches
  private Map<String, Function> actions;
  private int numBands;
  private OscDatagramClient oscClient;
  private OscDatagramServer oscServer;
  private InetSocketAddress oscReceiverAddress;
  private int paletteType;
  private List<String> keyNames;
  private List<String> keyGlobalNames;

  static final String keySpeed = "/pageControl/speed";
  static final String keyColorCyclingSpeed = "/pageControl/cycling";
  static final String keyCustom1 = "/pageControl/custom1";
  static final String keyCustom2 = "/pageControl/custom2";
  static final String keyBrightness="/pageControl/brightness";
  static final String keyAudioSpeedChange1 = "/pageAudio/speedChange/1";
  static final String keyAudioSpeedChange2 = "/pageAudio/speedChange/2";
  static final String keyAudioSpeedChange3 = "/pageAudio/speedChange/3";
  static final String keyAudioColorChange1 = "/pageAudio/colorChange/1";
  static final String keyAudioColorChange2 = "/pageAudio/colorChange/2";
  static final String keyAudioColorChange3 = "/pageAudio/colorChange/3";
  static final String keyAudioBrightnessChange1 = "/pageAudio/brightnessChange/1";
  static final String keyAudioBrightnessChange2 = "/pageAudio/brightnessChange/2";
  static final String keyAudioBrightnessChange3 = "/pageAudio/brightnessChange/3";
  static final String keyAudioSensitivity1 = "/pageAudio/sensitivity/1";
  static final String keyAudioSensitivity2 = "/pageAudio/sensitivity/2";
  static final String keyAudioSensitivity3 = "/pageAudio/sensitivity/3";
  static final String keyBeatLength = "/pageAudio/beatLength";
  static final String keyCustom1Label = "/pageControl/custom1_label";
  static final String keyCustom2Label = "/pageControl/custom2_label";
  static final String keyFlash = "/pageAudio/flashToggle";

  static final String keyModeName = "/pageControl/mode";
  static final String keyPaletteName = "/pageControl/palette";

  static final String keyGlobalAutoChangeSpeed = "/sketches/autoChange";
  static final String keyGlobalAutoChangeSpeedLabel = "/sketches/autoChange_label";

  /** Arguments (all floats): accelX, accelY, accelZ, pitch, roll, tilt */
  static final String keyWiimoteAccel   = "/wiimoteControl/accel";
  /** Arguments: buttons (int).  See {@link Wiimote}. */
  static final String keyWiimoteButtons = "/wiimoteControl/buttons";
  /** Arguments: Wiimote.path (String) */
  static final String keyWiimoteConnected = "/wiimoteControl/connected";
  /** Arguments: Wiimote.path (String) */
  static final String keyWiimoteDisconnected = "/wiimoteControl/disconnected";
  static final String wiimoteAddressStart = "/wii";

  Settings(int numBands) throws IllegalAccessException {

    //get the list of key constants
    List<String> keyNames = new ArrayList<String>();
    List<String> keyGlobalNames    = new ArrayList<String>();

    for (Field field : getClass().getDeclaredFields()) {
      if (!String.class.isAssignableFrom(field.getType()) || !Modifier.isFinal(field.getModifiers())) {
        continue;
      }

      String name = field.getName();
      List<String> list = null;
      if (name.startsWith("keyGlobal")){
        list = keyGlobalNames;
      } else if (name.startsWith("key")){
        list = keyNames;
      }
      if (list != null) {
        list.add((String) field.get(this));
      }
    }

    this.keyNames       = keyNames;
    this.keyGlobalNames = keyGlobalNames;

    this.numBands = numBands;
    setDefaultSettings();

    // Construct actions

    actions = new HashMap<String, Function>();
    actions.put("/pageControl/multixy1/1",    new FloatFloatFunction() {
        public void function(float x, float y) {
          main.touchXY(1, x, y);
        }});
    actions.put("/pageControl/multixy1/2",    new FloatFloatFunction() {
        public void function(float x, float y) {
          main.touchXY(2, x, y);
        }});
    actions.put("/pageControl/multixy1/3",    new FloatFloatFunction() {
        public void function(float x, float y) {
          main.touchXY(3, x, y);
        }});
    actions.put("/pageControl/multixy1/4",    new FloatFloatFunction() {
        public void function(float x, float y) {
          main.touchXY(4, x, y);
        }});
    actions.put("/pageControl/multixy1/5",    new FloatFloatFunction() {
        public void function(float x, float y) {
          main.touchXY(5, x, y);
        }});

    actions.put("/pageControl/newEffect",     new ArgIsOneFunction() {
        public void function() {
          main.newEffect();
        }});
    actions.put("/pageControl/paletteType",   new ArgIsOneFunction() {
        public void function() {
          main.newPaletteType();
        }});
    actions.put("/pageControl/newPalette",    new ArgIsOneFunction() {
        public void function() {
          main.newPalette();
        }});
    actions.put("/pageControl/reset",         new ArgIsOneFunction() {
        public void function() {
          main.currentMode().reset();
          sendControlValuesForThisSketchToIPad();
        }});
    actions.put("/pageAudio/instaFlash",      new ArgIsOneFunction() {
        public void function() {
          main.currentMode().manualFlash = true;
        }});

    actions.put(keyWiimoteAccel, new Function() {
      public void function(Object[] args) {
        if (args.length < 6) return;

        double x = 1.0 - Math.abs((Float) args[4])/Math.PI;
        double y = ((Float) args[3])/Math.PI;

        main.wiimoteAccel(
            (Float) args[0], (Float) args[1], (Float) args[2],
            (Float) args[3], (Float) args[4], (Float) args[5]);
      }});
    actions.put(keyWiimoteButtons, new Function() {
      public void function(Object[] args) {
        if (args.length >= 1 && args[0] instanceof Integer) {
          main.wiimoteButtons((Integer) args[0]);
        }
      }});
    actions.put(keyWiimoteConnected, new Function() {
      public void function(Object[] args) {
        main.wiimoteConnected((String) args[0]);
      }});
    actions.put(keyWiimoteDisconnected, new Function() {
      public void function(Object[] args) {
        main.wiimoteDisconnected((String) args[0]);
      }});

    paramGlobalMap = new HashMap<String, Float>();
    setParam(keyGlobalAutoChangeSpeed, 1.0);
    updateSketchesFromPrefs();
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
    return main.beatDetect.beatPos("spectralFlux", band);
  }

  float beatPosSimple(int band) {
    return main.beatDetect.beatPosSimple("spectralFlux", band);
  }

  ////////////////////////////////////////////////////////////////////
  //General Setting Management

  void setParam(String paramName, float value) {
    if (keyNames.contains(paramName)) {
      paramMap.put(paramName, value);
    }
    else if (keyGlobalNames.contains(paramName)) {
      paramGlobalMap.put(paramName, value);
    }
  }

  float getParam(String paramName) {
    Float result = null;
    if (keyNames.contains(paramName)) {
      result = paramMap.get(paramName);
    }
    else if (keyGlobalNames.contains(paramName)) {
      result = paramGlobalMap.get(paramName);
    }
    else {
      assert false : "paraName not found:" + paramName;
    }
    assert result != null : "getParam does not have " + paramName + "\nresult = " + result + "\nparamMap = " + paramMap;
    return result;
  }

  void setDefaultSettings() {
    isBeat = new boolean[numBands];
    paramMap = new HashMap<String, Float>();
    palette = null;
    paletteType = 0;

    setParam(keySpeed, 0.3f);
    setParam(keyColorCyclingSpeed, 0.3f);
    setParam(keyCustom1, 0.3f);
    setParam(keyCustom2, 0.3f);
    setParam(keyBrightness, 0.75f);
    setParam(keyAudioSpeedChange1, 0.3f);
    setParam(keyAudioSpeedChange2, 0.3f);
    setParam(keyAudioSpeedChange3, 0.3f);
    setParam(keyAudioColorChange1, 0.3f);
    setParam(keyAudioColorChange2, 0.3f);
    setParam(keyAudioColorChange3, 0.3f);
    setParam(keyAudioBrightnessChange1, 0.0f);
    setParam(keyAudioBrightnessChange2, 0.0f);
    setParam(keyAudioBrightnessChange3, 0.0f);
    setParam(keyAudioSensitivity1, 0.8f);
    setParam(keyAudioSensitivity2, 0.3f);
    setParam(keyAudioSensitivity3, 0.3f);
    setParam(keyBeatLength, 0.5f);
    setParam(keyFlash, 0.0f);

  }

  public Map<String, Object> switchSettings(Map<String, Object> newSettings) {
    Map<String, Object> saver = new HashMap<String, Object>();
    saver.put("1", paramMap);
    saver.put("2", Utility.toIntegerList(palette));
    saver.put("3", Utility.toBooleanList(isBeat));
    saver.put("4", paletteType);

    if (newSettings == null) {
      println("newSettings are null");
      setDefaultSettings();
    }
    else {
      paramMap = (Map<String, Float>)newSettings.get("1");
      palette = Utility.toIntArray((List<Integer>)newSettings.get("2"));
      isBeat = Utility.toBooleanArray((List<Boolean>)newSettings.get("3"));
      paletteType = (Integer)newSettings.get("4");
      assert(palette != null);
    }
    return saver;
  }



////////////////////////////////////////////////////////////////////
//Key helpers

  String getKeyAudioSpeedChange(int index) {
    switch(index) {
      case 0:
        return keyAudioSpeedChange1;
      case 1:
        return keyAudioSpeedChange2;
      case 2:
        return keyAudioSpeedChange3;
      default:
        assert(false);
    }
    return null;
  }

  String getKeyAudioColorChange(int index) {
    switch(index) {
      case 0:
        return keyAudioColorChange1;
      case 1:
        return keyAudioColorChange2;
      case 2:
        return keyAudioColorChange3;
      default:
        assert(false);
    }
    return null;
  }

  String getKeyAudioBrightnessChange(int index) {
    switch(index) {
      case 0:
        return keyAudioBrightnessChange1;
      case 1:
        return keyAudioBrightnessChange2;
      case 2:
        return keyAudioBrightnessChange3;
      default:
        assert(false);
    }
    return null;
  }

  String getKeyAudioSensitivity(int index) {
    switch(index) {
      case 0:
        return keyAudioSensitivity1;
      case 1:
        return keyAudioSensitivity2;
      case 2:
        return keyAudioSensitivity3;
      default:
        assert(false);
    }
    return null;
  }


////////////////////////////////////////////////////////////////////
//OSC 5 stuff
  void initOSC() {
    try {
      oscServer = new OscDatagramServer(8000, this, null);
      oscClient = new OscDatagramClient();
    } catch (SocketException ex) {
      System.err.println("Could not start OSC server or client: " + ex);
    }
    oscReceiverAddress = new InetSocketAddress(iPadIP, 9000);
  }

  private void enableControl(String controlKey, boolean enabled) {
    sendMessageToIPad(controlKey + "/visible", enabled?"1":"0");
  }

  /* These come in on a different thread than
   the draw routines, so we need to add to a queue
   and then process the events during handleQueuedOSCEvents
   which is called from the main draw
   */
  private BlockingQueue<OscMessage> oscMessages = new LinkedBlockingQueue<OscMessage>();

  /**
   * Receive an OSC message.
   *
   * @param message the message.
   */
  public void oscMessage(OscMessage message) {
      oscMessages.add(message);
    }

  /**
   * Receive an OSC bundle.
   *
   * @param message the bundle.
   */
  public void oscBundle(OscBundle bundle) {
    for (OscPacket packet : bundle.elements()) {
      if (packet instanceof OscMessage) {
        oscMessage((OscMessage) packet);
      } else if (packet instanceof OscBundle) {
        oscBundle((OscBundle) packet);
      }
    }
  }

  /**
   * An OSC parsing error occurred.
   *
   * @param data the data
   * @param off the data offset
   * @param len the data length
   */
  public void oscParseError(byte[] data, int off, int len) {
  }

  // Call once per draw to process events
  void handleQueuedOSCEvents() {
    Queue<OscMessage> messages = new LinkedList<OscMessage>();
    oscMessages.drainTo(messages);

    for (OscMessage message : messages) {
      handleOscEvent(message);
    }
  }

  /* unplugged OSC messages */
  void handleOscEvent(OscMessage msg) {
    String addr = msg.getAddress();

    // Only detect a new remote address (eg. iPad) if it's not a loopback address

    SocketAddress remoteAddress = msg.getRemoteAddress();
    if (remoteAddress instanceof InetSocketAddress) {
      InetAddress inetAddress = ((InetSocketAddress) remoteAddress).getAddress();
      if (!inetAddress.isLoopbackAddress()) {
        String ipAddress = inetAddress.getHostAddress();
        if (ipAddress != null && ipAddress.length() > 0 && !ipAddress.equals(iPadIP)) {
          detectedNewIPadAddress(ipAddress);
        }
      }
    }

    Object[] args = msg.getArgs();

    Function func = actions.get(addr);
    if (func != null) {
      if (!addr.startsWith(wiimoteAddressStart)) {
        println("\naction = " + addr);
      }
      func.function(args);
      return;
    }

    if (keyNames.contains(addr)) {
      Float f = Utility.getFloatFromArgs(args, 0);
      if (f != null) {
        paramMap.put(addr, f);
        println("Set " + addr + " to " + f);
      }
    }
    else if (keyGlobalNames.contains(addr)) {
      Float f = Utility.getFloatFromArgs(args, 0);
      if (f != null) {
        paramGlobalMap.put(addr, f);
        println("Set global " + addr + " to " + f);

        if (addr.equals(keyGlobalAutoChangeSpeed)) {
          assert(new Float(getParam(keyGlobalAutoChangeSpeed)).equals(f));
          updateLabelForAutoChanger();
        }
      }
    }
    else if (addr.startsWith("/sketches/col")) {
      Float f = Utility.getFloatFromArgs(args, 0);
      if (f != null) {
        handleSketchToggles(addr, f);
      }
    }
    else if (addr.equals("/pageControl") || addr.equals("/pageAudio") || addr.equals("/sketches") || addr.equals("/writer") || addr.equals("/progLed")) {
      // Just a page change, ignore
    }
    else if (addr.startsWith("/progLed/")) {
      main.hardwareTestEffect.handleOscEvent(msg);
    }
    else {
      println("### Received an unhandled osc message: " + msg);
    }
  }

  private void detectedNewIPadAddress(String ipAddress) {
    println("detected new iPad address: " + iPadIP + " -> " + ipAddress);
    iPadIP = ipAddress; // Once the iPad contacts us, we can contact them, if the hardcoded IP address is wrong
    oscReceiverAddress = new InetSocketAddress(iPadIP, 9000);
    sendEntireGUIToIPad();
  }

  void sendMessageToIPad(String key, Object value) {
    OscMessage myMessage = new OscMessage(key, new Object[] { value });
    try {
      oscClient.send(myMessage, oscReceiverAddress);
    } catch (IOException ex) {
      System.err.println("Error sending message: " + ex);
    }
  }

  /*
   Send Sketch specific control values to the iPad.
   Normally these need to be updated when we switch to a new Sketch,
   since each Sketch tracks its own set of values.
   */
  void sendControlValuesForThisSketchToIPad() {
    // TODO: these methods may need to go on another thread to speed things up
    for (String controlName : paramMap.keySet()) {
      float value = paramMap.get(controlName);
      sendMessageToIPad((String)controlName, value);
    }

    Drawer currentMode = main.currentMode();
    sendMessageToIPad(keyModeName, currentMode.getName());
    sendMessageToIPad(keyCustom1Label, currentMode.getCustom1Label());
    sendMessageToIPad(keyCustom2Label, currentMode.getCustom2Label());
    sendMessageToIPad(keyPaletteName, main.pm.getPaletteDisplayName());
    currentMode.sendToIPad();
  }

  /*
   When we first talk to iPad, initialize it with all
   of the control labels and values.
   */
  void sendEntireGUIToIPad() {
    // TODO: these methods may need to go on another thread to speed things up

    Drawer[][] modes = main.modes;

    for (int col = 0; col < modes.length; col++) {
      for (int row = 0; row < modes[col].length; row++) {
        String name = modes[col][row].getName();
        sendMessageToIPad(sketchLabelName(col, row), name);
      }
    }

    updateLabelForAutoChanger();
    sendSketchGridTogglesToIPad();
    sendControlValuesForThisSketchToIPad();
    main.hardwareTestEffect.sendToIPad();
  }


  void handleSketchToggles(String addr, float value) {
    String substring = addr.substring("/sketches/col".length());
    println("value = " + value + " substring = " + substring);
    if (substring.indexOf("row") >= 0) {
      String[] temp = substring.split("row");
      int col = Integer.parseInt(temp[0]);
      int row = Integer.parseInt(temp[1]);

      setSketchOn(col, row, value > 0?true:false);
    }
    else {
      if (value == 1.0) {
        int col = Integer.parseInt(substring);
        println("toggle col = " + col);
        toggleColumn(col);

      }
    }
  }

  void toggleColumn(int column) {
    int numRows = whichModes[column].length;
    boolean on = whichModes[column][0];

    for (int row = 0; row < numRows; row++) {
      setSketchOn(column, row, !on);
    }
    sendSketchGridTogglesToIPad();
  }

  void sendSketchGridTogglesToIPad() {
    int numCols = whichModes.length;
    int numRows = whichModes[0].length;

    for (int col = 0; col < numCols; col++) {
      for (int row = 0; row < numRows; row++) {
        sendMessageToIPad(sketchName(col, row) + "/toggle", whichModes[col][row]?"1":"0");
        println("sendSketchGridTogglesToIPad " + sketchName(col, row) + "/toggle");
      }
    }
  }

  boolean isSketchOn(int col, int row) {
    return whichModes[col][row];
  }

  void setSketchOn(int col, int row, boolean state) {
    whichModes[col][row] = state;
    prefs.putBoolean(sketchName(col, row), state);
    needToFlushPrefs = true;
  }

  void updateSketchesFromPrefs() {
    int numCols = whichModes.length;
    int numRows = whichModes[0].length;

    for (int col = 0; col < numCols; col++) {
      for (int row = 0; row < numRows; row++) {
        whichModes[col][row] = prefs.getBoolean(sketchName(col, row), true);
      }
    }
  }

  String sketchName(int col, int row) {
    return "/sketches/col" + col + "row" + row;
  }

  String sketchLabelName(int col, int row) {
    return sketchName(col, row) + "_label";
  }

  float speedWithAudioSpeed() {
    float speed = getParam(keySpeed);
    for (int i = 0; i < main.NUM_BANDS; i++) {
      if (isBeat(i)) {
        speed += beatPos(i) * getParam(getKeyAudioSpeedChange(i));
      }
    }
    return constrain(speed, 0, 1);
  }

  int millisBetweenAutoChanges() {
    float result = getParam(keyGlobalAutoChangeSpeed);
    if (result == 1.0) {
      return Integer.MAX_VALUE;
    }

    float MAX_SECONDS = 60*10; //10 minutes
    float MIN_SECONDS = 10;    //10 seconds

    float seconds = result;
    seconds *= sqrt(MAX_SECONDS - MIN_SECONDS);
    seconds *= seconds; //exponential control
    seconds += MIN_SECONDS;

    if (seconds < 30) {
    }
    else if (seconds < 90) {
      seconds = round(seconds / 10.0);
      seconds *= 10;
    }
    else {
      seconds = round(seconds / 30.0);
      seconds *= 30;
    }

    return (int)(seconds * 1000);
  }

  void updateLabelForAutoChanger() {
    int milliseconds = millisBetweenAutoChanges();

    int seconds = round(milliseconds/1000.0);
    String label;

    if (milliseconds == Integer.MAX_VALUE) {
      label = "AutoChange Never";
    }
    else if (seconds >= 60) {
      label = "AutoChange " + (seconds/60) + "m " + (seconds % 60) +  "s";
    }
    else {
      label = "AutoChange " + seconds + "s";
    }

    sendMessageToIPad(keyGlobalAutoChangeSpeedLabel, label);
    sendMessageToIPad(keyGlobalAutoChangeSpeed, getParam(keyGlobalAutoChangeSpeed));
  }

}
