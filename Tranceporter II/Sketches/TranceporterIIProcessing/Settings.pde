import java.lang.reflect.*;

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

  private boolean[][] whichModes = new boolean[3][5];
  private color[] palette;
  private boolean[] isBeat;
  private HashMap<String, Float> paramMap; // Values of controls specific to any Sketch
  private HashMap<String, Float> paramGlobalMap; // Values of controls that control all Sketches
  private HashMap actions;
  private int numBands;
  private OscDatagramClient oscClient;
  private OscDatagramServer oscServer;
  private InetSocketAddress oscReceiverAddress;
  private int paletteType;
  List<String> keyNames;
  List<String> keyGlobalNames;

  private HidDevice wiiDevice;
  private Wiimote wii;
  private ExecutorService wiiExecutor;

  final String keySpeed = "/pageControl/speed";
  final String keyColorCyclingSpeed = "/pageControl/cycling";
  final String keyCustom1 = "/pageControl/custom1";
  final String keyCustom2 = "/pageControl/custom2";
  final String keyBrightness="/pageControl/brightness";
  final String keyAudioSpeedChange1 = "/pageAudio/speedChange/1";
  final String keyAudioSpeedChange2 = "/pageAudio/speedChange/2";
  final String keyAudioSpeedChange3 = "/pageAudio/speedChange/3";
  final String keyAudioColorChange1 = "/pageAudio/colorChange/1";
  final String keyAudioColorChange2 = "/pageAudio/colorChange/2";
  final String keyAudioColorChange3 = "/pageAudio/colorChange/3";
  final String keyAudioBrightnessChange1 = "/pageAudio/brightnessChange/1";
  final String keyAudioBrightnessChange2 = "/pageAudio/brightnessChange/2";
  final String keyAudioBrightnessChange3 = "/pageAudio/brightnessChange/3";
  final String keyAudioSensitivity1 = "/pageAudio/sensitivity/1";
  final String keyAudioSensitivity2 = "/pageAudio/sensitivity/2";
  final String keyAudioSensitivity3 = "/pageAudio/sensitivity/3";
  final String keyBeatLength = "/pageAudio/beatLength";
  final String keyCustom1Label = "/pageControl/custom1_label";
  final String keyCustom2Label = "/pageControl/custom2_label";
  final String keyFlash = "/pageAudio/flashToggle";

  final String keyModeName = "/pageControl/mode";
  final String keyPaletteName = "/pageControl/palette";

  final String keyGlobalAutoChangeSpeed = "/sketches/autoChange";
  final String keyGlobalAutoChangeSpeedLabel = "/sketches/autoChange_label";

  Settings(int numBands) {

    //get the list of key constants
    ArrayList localModeList =  new ArrayList();
    ArrayList globalList =  new ArrayList();

    Class cls = this.getClass();

    try {
      Field fieldlist[] = cls.getDeclaredFields();
      for (int i = 0; i < fieldlist.length; i++) {
        Field fld = fieldlist[i];
        if (fld.getType() != String.class || !Modifier.isFinal(fld.getModifiers())) {
          continue;
        }

        String name = fld.getName();
        if (name.startsWith("keyGlobal")){
          fld.setAccessible(true);
          String value = (String)fld.get(this);
          globalList.add(value);
        }
        else if (name.startsWith("key")){
          fld.setAccessible(true);
          String value = (String)fld.get(this);
          localModeList.add(value);
        }
      }
      keyNames = localModeList;
      keyGlobalNames = globalList;

    }
    catch (Exception e){
      assert false : "got exception: " + e;
    }

    this.numBands = numBands;
    setDefaultSettings();

    actions = new HashMap();
    actions.put("/pageControl/multixy1/1",    new FunctionFloatFloat() {
        public void function(float x, float y) {
          main.touchXY(1, x, y);
        }});
    actions.put("/pageControl/multixy1/2",    new FunctionFloatFloat() {
        public void function(float x, float y) {
          main.touchXY(2, x, y);
        }});
    actions.put("/pageControl/multixy1/3",    new FunctionFloatFloat() {
        public void function(float x, float y) {
          main.touchXY(3, x, y);
        }});
    actions.put("/pageControl/multixy1/4",    new FunctionFloatFloat() {
        public void function(float x, float y) {
          main.touchXY(4, x, y);
        }});
    actions.put("/pageControl/multixy1/5",    new FunctionFloatFloat() {
        public void function(float x, float y) {
          main.touchXY(5, x, y);
        }});

    actions.put("/pageControl/newEffect",     new VoidFunction() {
        public void function() {
          main.newEffect();
        }});
    actions.put("/pageControl/paletteType",   new VoidFunction() {
        public void function() {
          main.newPaletteType();
        }});
    actions.put("/pageControl/newPalette",    new VoidFunction() {
        public void function() {
          main.newPalette();
        }});
    actions.put("/pageControl/reset",         new VoidFunction() {
        public void function() {
          main.currentMode().reset();
          sendControlValuesForThisSketchToIPad();
        }});
    actions.put("/pageAudio/instaFlash",      new VoidFunction() {
        public void function() {
          main.currentMode().manualFlash = true;
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

    setParam(keySpeed, 0.3);
    setParam(keyColorCyclingSpeed, 0.3);
    setParam(keyCustom1, 0.3);
    setParam(keyCustom2, 0.3);
    setParam(keyBrightness, 0.75);
    setParam(keyAudioSpeedChange1, 0.3);
    setParam(keyAudioSpeedChange2, 0.3);
    setParam(keyAudioSpeedChange3, 0.3);
    setParam(keyAudioColorChange1, 0.3);
    setParam(keyAudioColorChange2, 0.3);
    setParam(keyAudioColorChange3, 0.3);
    setParam(keyAudioBrightnessChange1, 0.0);
    setParam(keyAudioBrightnessChange2, 0.0);
    setParam(keyAudioBrightnessChange3, 0.0);
    setParam(keyAudioSensitivity1, 0.8);
    setParam(keyAudioSensitivity2, 0.3);
    setParam(keyAudioSensitivity3, 0.3);
    setParam(keyBeatLength, 0.5);
    setParam(keyFlash, 0.0);

  }

  public Object switchSettings(Object newSettings) {
    HashMap saver = new HashMap();
    saver.put("1", paramMap);
    saver.put("2", utility.toIntegerList(palette));
    saver.put("3", utility.toBooleanList(isBeat));
    saver.put("4", paletteType);

    if (newSettings == null) {
      println("newSettings are null");
      setDefaultSettings();
    }
    else {
      HashMap setter = (HashMap)newSettings;
      paramMap = (HashMap<String, Float>)setter.get("1");
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

  void initWiimote() {
    // Wii stuff

    try {
      HidManager hid = HidManager.getInstance();

      List<HidDeviceInfo> wiimotes = Wiimote.findWiimotes(hid);
      if (wiimotes.size() == 0) {
        System.out.println("No Wii controllers found!");
        return;
      }

      for (HidDeviceInfo device : wiimotes) {
        wiiDevice = hid.open(wiimotes.get(0));
        if (wiiDevice != null) {
          break;
        }
      }
      if (wiiDevice == null) {
        System.out.println("Could not open any of the found Wii controllers!");
      }

      System.out.println("Monitoring Wii controller: " + wiiDevice);
      WiimoteListener listener = new WiimoteListener() {
        @Override
        public void status(WiimoteStatus status) {
        }

        private boolean lastButtonState;
        @Override
        public void buttons(int buttons) {
          if (((buttons & Wiimote.BUTTON_RIGHT) != 0) != lastButtonState) {
            // Only watch for a button change
            float param = (lastButtonState) ? 0.0f : 1.0f;
            lastButtonState = !lastButtonState;

            oscMessage(new OscMessage("/pageControl/newEffect", new Object[] { param }));
          }
        }

        private long lastTime;

        @Override
        public void accelerometer(float x, float y, float z) {
          long time = System.currentTimeMillis();

          if (time - lastTime < 200L) return;

          double roll = 1.0 - Math.abs(WiiMath.roll(x, y, z))/Math.PI;
          double pitch = 1.0 - WiiMath.pitch(x, y, z)/Math.PI;

          oscMessage(new OscMessage(keyCustom2, new Object[] { (float) roll }));
          oscMessage(new OscMessage(keyCustom1, new Object[] { (float) pitch }));

          lastTime = time;
        }

        @Override
        public void memory(int error, int offset, byte[] data, int dataOff, int dataLen) {
        }

        @Override
        public void ack(int report, int error) {
        }
      };

      wii = new Wiimote(wiiDevice);
      wiiExecutor = Executors.newSingleThreadExecutor();
      wiiExecutor.submit(wii.getEventLoop(listener));
      wii.requestData(Wiimote.REPORT_BUTTONS_AND_ACCEL, false);
    } catch (Exception ex) {
      ex.printStackTrace();
    }
  }

  private void enableControl(String controlKey, boolean enabled) {
    sendMessageToIPad(controlKey + "/visible", enabled?"1":"0");
  }

  /* These come in on a different thread than
   the draw routines, so we need to add to a queue
   and then process the events during handleQueuedOSCEvents
   which is called from the main draw
   */
  private ArrayList<OscMessage> oscMessages = new ArrayList<OscMessage>();

  /**
   * Receive an OSC message.
   *
   * @param message the message.
   */
  public void oscMessage(OscMessage message) {
    synchronized (oscMessages) {
      oscMessages.add(message);
    }
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
    ArrayList<OscMessage> messages;
    synchronized(oscMessages) {
      messages = (ArrayList<OscMessage>)oscMessages.clone();
      oscMessages.clear();
    }

    for (OscMessage msg : messages) {
      handleOscEvent(msg);
    }
  }

  /* unplugged OSC messages */
  void handleOscEvent(OscMessage msg) {
    String addr = msg.getAddress();
    try {
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
      Float arg0 = (args.length >= 1 && args[0] instanceof Number)
          ? ((Number) args[0]).floatValue()
          : null;
      Float arg1 = (args.length >= 2 && args[1] instanceof Number)
          ? ((Number) args[1]).floatValue()
          : null;

      Object func = actions.get(addr);
      if (func != null) {
        println("\naction = " + addr);
        if (arg0 != null) {
          if (addr.indexOf("/multixy") >= 0) {
            if (arg1 != null) {
              ((FunctionFloatFloat)func).function(arg0, arg1);
            }
          }
          else {
            if (arg0.equals(1.0f)) {
              ((VoidFunction)func).function();
            }
          }
        }
      }
      else if (keyNames.contains(addr)) {
        if (arg0 != null) {
          paramMap.put(addr, arg0);
          println("Set " + addr + " to " + arg0);
        }
      }
      else if (keyGlobalNames.contains(addr)) {
        if (arg0 != null) {
          paramGlobalMap.put(addr, arg0);
          println("Set global " + addr + " to " + arg0);

          if (addr.equals(keyGlobalAutoChangeSpeed)) {
            assert(new Float(getParam(keyGlobalAutoChangeSpeed)).equals(arg0));
            updateLabelForAutoChanger();
          }
        }
      }
      else if (addr.startsWith("/sketches/col")) {
        if (arg0 != null) {
          handleSketchToggles(addr, arg0);
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
    } catch (Exception e) {
      // Print out the exception that occurred
      System.out.println("Action Exception " + addr + ": " + e.getMessage());
      e.printStackTrace();
    }
  }

  private void detectedNewIPadAddress(String ipAddress) {
    println("detected new iPad address: " + iPadIP + " -> " + ipAddress);
    iPadIP = ipAddress; // Once the iPad contacts us, we can contact them, if the hardcoded IP address is wrong
    oscReceiverAddress = new InetSocketAddress(iPadIP, 9000);
    sendEntireGUIToIPad();
  }

  void sendMessageToIPad(String key, String value) {
    OscMessage myMessage = new OscMessage(key, new Object[] { value });
    try {
      oscClient.send(myMessage, oscReceiverAddress);
    } catch (IOException ex) {
      System.err.println("Error sending message: " + ex);
    }
  }

  void sendMessageToIPad(String key, float value) {
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
    for (int i=0; i < main.NUM_BANDS; i++) {
      if (isBeat(i)) {
        speed += beatPos(i)*(Float)getParam(getKeyAudioSpeedChange(i));
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
    String label = "AutoChange " + seconds + "s";

    if (milliseconds == Integer.MAX_VALUE) {
      label = "AutoChange Never";
    }
    else if (seconds >= 60) {
      label = "AutoChange " + (seconds/60) + "m " + (seconds % 60) +  "s";
    }
    sendMessageToIPad(keyGlobalAutoChangeSpeedLabel, label);
    sendMessageToIPad(keyGlobalAutoChangeSpeed, getParam(keyGlobalAutoChangeSpeed));
  }

}
