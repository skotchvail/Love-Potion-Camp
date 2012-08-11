import java.lang.reflect.*;

class Settings {
  
  private ArrayList oscMessages = new ArrayList();;
  private boolean[][] whichModes = new boolean[3][5];
  private color[] palette;
  private boolean[] isBeat;
  private HashMap paramMap;
  private HashMap actions;
  private int numBands;
  private OscP5 oscP5;
  private NetAddress oscReceiver;
  private int paletteType;
  List<String> keyNames;
  
  final String keySpeed="/pageControl/speed";
  final String keyColorCyclingSpeed="/pageControl/cycling";
  final String keyCustom1="/pageControl/custom1";
  final String keyCustom2="/pageControl/custom2";
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
  
  final String keyModeName = "/pageControl/mode";
  final String keyPaletteName = "/pageControl/palette";
  
  Settings(int numBands) {
    
    //get the list of key constants
    ArrayList theList =  new ArrayList();
    Class cls = this.getClass();
    
    try {
      Field fieldlist[] = cls.getDeclaredFields();
      for (int i = 0; i < fieldlist.length; i++) {
        Field fld = fieldlist[i];
        String name = fld.getName();
        if (name.startsWith("key")
            && fld.getType() == String.class
            && Modifier.isFinal(fld.getModifiers())
            ){
          
          fld.setAccessible(true);
          String value = (String)fld.get(this);
          theList.add(value);
        }
        keyNames = theList;
      }
      
    }
    catch (Exception e){
      assert false : "got exception: " + e;
    }
    
    
    this.numBands = numBands;
    setDefaultSettings();
    
    actions = new HashMap();
    actions.put("/pageControl/multixy1/1",  new FunctionFloatFloat() {
              public void function(float x, float y) {
                main.touchXY(1, x, y);
              }});
    actions.put("/pageControl/multixy1/2",  new FunctionFloatFloat() {
              public void function(float x, float y) {
                main.touchXY(2, x, y);
              }});
    actions.put("/pageControl/multixy1/3",  new FunctionFloatFloat() {
            public void function(float x, float y) {
              main.touchXY(3, x, y);
            }});
    actions.put("/pageControl/multixy1/4",  new FunctionFloatFloat() {
            public void function(float x, float y) {
              main.touchXY(4, x, y);
            }});
    actions.put("/pageControl/multixy1/5",  new FunctionFloatFloat() {
            public void function(float x, float y) {
              main.touchXY(5, x, y);
            }});
    actions.put("/pageControl/newEffect",   new VoidFunction() {
            public void function() {
              main.newEffect();
            }});
    actions.put("/pageControl/paletteType", new VoidFunction() {
            public void function() {
              main.newPaletteType();
            }});
    actions.put("/pageControl/newPalette",  new VoidFunction() {
            public void function() {
              main.newPalette();
            }});
    actions.put("/pageControl/reset",       new VoidFunction() {
            public void function() {
              main.reset();
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
    return main.bd.beatPos("spectralFlux", band);
  }
  
  float beatPosSimple(int band) {
    return main.bd.beatPosSimple("spectralFlux", band);
  }
  
  ////////////////////////////////////////////////////////////////////
  //General Setting Management

  void setParam(String paramName, float value) {
    paramMap.put(paramName, value);
  }
  
  float getParam(String paramName) {
    assert(keyNames.contains(paramName)) : "paraName = " + paramName + "\nkeyNames = " + keyNames;
    assert(paramMap != null) : "param is null";
    assert(paramName != null) : "paramName is null";
    
    if (paramName.equals(keySpeed)) {
      float speed = (Float) paramMap.get(paramName);
      for (int i=0; i < main.NUM_BANDS; i++) {
        if (isBeat(i)) {
          speed += beatPos(i)*(Float)paramMap.get(getKeyAudioSpeedChange(i));
        }
      }
      return constrain(speed, 0, 1);
    }
    
    Object result = paramMap.get(paramName);
    if (result == null) {
      println("DEBUGGING: getParam does not have " + paramName + "\nparamMap = " + paramMap);
      result = paramMap.get(paramName);
    }
    assert result != null : "getParam does not have " + paramName + "\nresult = " + result + "\nparamMap = " + paramMap;
    return (Float) result;
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
    oscP5 = new OscP5(this,8000);
    oscReceiver = new NetAddress(iPadIP,9000);
}

  private void enableControl(String controlKey, boolean enabled) {
    sendMessageToPad(controlKey + "/visible",enabled?"1":"0");
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
        setParam(addr, value);
        println("Set " + addr + " to " + value);
      }
      else if (addr.startsWith("/sketches/col")) {
        handleSketchToggles(addr, msg.get(0).floatValue());
      }
      else if (addr.equals("/pageControl") || addr.equals("/pageAudio")) {
        //just a page change, ignore
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

  private void detectedNewIPadAddress(String ipAddress)
  {
    println("detected new iPad address: " + iPadIP + " -> " + ipAddress);
    iPadIP = ipAddress; //once the iPad contacts us, we can contact them, if the hardcoded IP address is wrong
    oscReceiver = new NetAddress(iPadIP,9000);
    sendAllSettingsToPad();
    main.updateIPadGUI();  }
  
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

  
  //TODO: these methods may need to go on another thread to speed things up
  void sendAllSettingsToPad() {
    for (Object controlName : paramMap.keySet()) {
      float value = (Float)paramMap.get(controlName);
      sendMessageToPad((String)controlName, value);
    }
  }
  
  void handleSketchToggles(String addr, float value) {
    String substring = addr.substring("/sketches/col".length());
    println("value = " + value + " substring = " + substring);
    if (substring.indexOf("row") >= 0) {
      String[] temp = substring.split("row");
      int col = Integer.parseInt( temp[0] );
      int row = Integer.parseInt( temp[1] );
      
      whichModes[col][row] = (value > 0?true:false);
      
    }
    else {
      if (value == 1.0) {
        int col = Integer.parseInt( substring );
        println("toggle col = " + col);
        toggleColumn(col);
        
      }
    }
  }
  
  void toggleColumn(int column) {
    int numRows = whichModes[column].length;
    boolean on = whichModes[column][0];
    
    for (int row = 0; row < numRows; row++) {
      whichModes[column][row] = !on;
    }
    sendSketchesToPad();
  }
  
  void sendSketchesToPad() {
    int numCols = whichModes.length;
    int numRows = whichModes[0].length;
    
    for (int col = 0; col < numCols; col++) {
      for (int row = 0; row < numRows; row++) {
        sendMessageToPad(sketchName(col,row) + "/toggle",whichModes[col][row]?"1":"0");
        println("sendSketchesToPad " + sketchName(col,row) + "/toggle");
      }
    }
  }

  boolean isSketchOn(int col, int row) {
    return whichModes[col][row];
  }

  
  void setSketchOn(int col, int row, boolean state) {
    whichModes[col][row] = state;
  }
  
  String sketchName(int col, int row) {
    return "/sketches/col" + col + "row" + row;
  }

  String sketchLabelName(int col, int row) {
    return sketchName(col, row) + "_label";
  }
    
}
