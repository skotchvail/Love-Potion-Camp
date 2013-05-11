import java.lang.reflect.*;

class Settings {
  
  private ArrayList oscMessages = new ArrayList();;
  private boolean[][] whichModes = new boolean[3][5];
  private color[] palette;
  private boolean[] isBeat;
  private HashMap paramMap; // Values of controls specific to any Sketch
  private HashMap paramGlobalMap; // Values of controls that control all Sketches
  private HashMap actions;
  private int numBands;
  private OscP5 oscP5;
  private NetAddress oscReceiver;
  private int paletteType;
  List<String> keyNames;
  List<String> keyGlobalNames;
  
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
    actions.put("/progLed/gotoHardwareTest",  new VoidFunction() {
      public void function() {
        main.gotoHardwareTest();
      }});
    
    
    paramGlobalMap = new HashMap();
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
    return main.bd.beatPos("spectralFlux", band);
  }
  
  float beatPosSimple(int band) {
    return main.bd.beatPosSimple("spectralFlux", band);
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
    Object result = null;
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
    return (Float) result;
  }
  
  void setDefaultSettings() {
    isBeat = new boolean[numBands];
    paramMap = new HashMap();
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
    oscP5 = new OscP5(this, 8000);
    oscReceiver = new NetAddress(iPadIP, 9000);
}

  private void enableControl(String controlKey, boolean enabled) {
    sendMessageToPad(controlKey + "/visible", enabled?"1":"0");
  }
  
  /* this comes in on a different thread than 
   the draw routines, so we need to add to a queue
   and then process the events during the heartbeat
   which is called from the main draw
   */
  void oscEvent(OscMessage msg) {
    synchronized(oscMessages)
    {
      oscMessages.add(msg);
    }
  }

  //call once per draw to process events
  void heartBeat() {
//TODO: Not sure how much synchronized slows down our framerate. 
//    if (oscMessages.size() == 0)
//      return;
    synchronized(oscMessages)
    {
      for (Object obj : oscMessages) {
        OscMessage msg = (OscMessage)obj;
        handleOscEvent(msg);
      }
      oscMessages.clear();
    }
    
  }

  /* unplugged OSC messages */
  void handleOscEvent(OscMessage msg) {
    String addr = msg.addrPattern();
    try {
      String ipAddress = msg.netAddress().address();
      if (ipAddress != null && ipAddress.length() > 0 && !ipAddress.equals(iPadIP)) {
        detectedNewIPadAddress(ipAddress);
      }
      
      Object func = actions.get(addr);
      if (func != null) {
        println("\naction = " + addr);
        if (addr.indexOf("/multixy") >= 0) {
          ((FunctionFloatFloat)func).function(msg.get(0).floatValue(), msg.get(1).floatValue());
        }
        else { 
          if (msg.get(0).floatValue() != 1.0) {
            ((VoidFunction)func).function();
          }
        }
      }
      else if (keyNames.contains(addr)) {
        float value = msg.get(0).floatValue();
        paramMap.put(addr, value);
        println("Set " + addr + " to " + value);
      }
      else if (keyGlobalNames.contains(addr)) {
        float value = msg.get(0).floatValue();
        paramGlobalMap.put(addr, value);
        println("Set global " + addr + " to " + value);
        
        if (addr.equals(keyGlobalAutoChangeSpeed)) {
          assert(getParam(keyGlobalAutoChangeSpeed) == value);
          updateLabelForAutoChanger();
        }
      }
      else if (addr.startsWith("/sketches/col")) {
        handleSketchToggles(addr, msg.get(0).floatValue());
      }
      else if (addr.equals("/pageControl") || addr.equals("/pageAudio") || addr.equals("/sketches") || addr.equals("/writer") || addr.equals("/progLed")) {
        // Just a page change, ignore
      }
      else if (addr.startsWith("/progLed/")) {
        main.currentMode().handleOscEvent(msg);
      }
      else {
        print("### Received an unhandled osc message: " + msg.addrPattern() + " " + msg.typetag() + " ");
        Object[] args = msg.arguments();
        for (int i=0; i<args.length; i++) {
          print(args[i].toString() + " ");
        }
        println();
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
    oscReceiver = new NetAddress(iPadIP, 9000);
    sendEntireGUIToIPad();
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
  
  /*
   Send Sketch specific control values to the iPad.
   Normally these need to be updated when we switch to a new Sketch, 
   since each Sketch tracks its own set of values.
   */
  void sendControlValuesForThisSketchToIPad() {
    // TODO: these methods may need to go on another thread to speed things up
    for (Object controlName : paramMap.keySet()) {
      float value = (Float)paramMap.get(controlName);
      sendMessageToPad((String)controlName, value);
    }

    Drawer currentMode = main.currentMode();
    
    String name = currentMode.getName();
    sendMessageToPad(keyModeName, name);

    name = currentMode.getCustom1Label();
    sendMessageToPad(keyCustom1Label, name);
    
    name = currentMode.getCustom2Label();
    sendMessageToPad(keyCustom2Label, name);
    
    sendMessageToPad(keyPaletteName, main.pm.getPaletteDisplayName());
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
        sendMessageToPad(sketchLabelName(col, row), name);
      }
    }
    
    updateLabelForAutoChanger();
    sendSketchGridTogglesToIPad();
    sendControlValuesForThisSketchToIPad();
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
        sendMessageToPad(sketchName(col, row) + "/toggle", whichModes[col][row]?"1":"0");
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
        whichModes[col][row] = prefs.getBoolean(sketchName(col, row), false);
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
    sendMessageToPad(keyGlobalAutoChangeSpeedLabel, label);
    sendMessageToPad(keyGlobalAutoChangeSpeed, getParam(keyGlobalAutoChangeSpeed));
  }

}
