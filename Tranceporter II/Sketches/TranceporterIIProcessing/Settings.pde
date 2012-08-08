import java.lang.reflect.*;

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
    
    if (false) {
      keyNames = Arrays.asList(
                               keySpeed, keyColorCyclingSpeed,keyCustom1,keyCustom2, keyBrightness,
                               keyAudioSpeedChange1, keyAudioSpeedChange2, keyAudioSpeedChange3,
                               keyAudioColorChange1, keyAudioColorChange2, keyAudioColorChange3,
                               keyAudioBrightnessChange1, keyAudioBrightnessChange2, keyAudioBrightnessChange3,
                               keyAudioSensitivity1, keyAudioSensitivity2, keyAudioSensitivity3,
                               keyBeatLength);
      
    }
    else {

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

    }
    
    this.numBands = numBands;
    setDefaultSettings();
    
    actions = new HashMap();
    actions.put("/1/multixy1/1",  new FunctionFloatFloat() {
              public void function(float x, float y) {
                main.touchXY(1, x, y);
              }});
    actions.put("/1/multixy1/2",  new FunctionFloatFloat() {
              public void function(float x, float y) {
                main.touchXY(2, x, y);
              }});
    actions.put("/1/multixy1/3",  new FunctionFloatFloat() {
            public void function(float x, float y) {
              main.touchXY(3, x, y);
            }});
    actions.put("/1/multixy1/4",  new FunctionFloatFloat() {
            public void function(float x, float y) {
              main.touchXY(4, x, y);
            }});
    actions.put("/1/multixy1/5",  new FunctionFloatFloat() {
            public void function(float x, float y) {
              main.touchXY(5, x, y);
            }});
    actions.put("/1/push1",       new VoidFunction() {
            public void function() {
              main.newEffect();
            }});
    actions.put("/1/push2",       new VoidFunction() {
            public void function() {
              main.newPaletteType();
            }});
    actions.put("/1/push3",       new VoidFunction() {
            public void function() {
              main.newPalette();
            }});
    actions.put("/1/push4",       new VoidFunction() {
            public void function() {
              main.reset();
            }});
    actions.put("/2/push1",       new VoidFunction() {
            public void function() {
              main.tap();
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
    assert result != null : "getParam does not have " + paramName;
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

  void sendAllSettingsToPad() {
    for (Object controlName : paramMap.keySet()) {
      float value = (Float)paramMap.get(controlName);
      sendMessageToPad((String)controlName, value);
    }
  }
  

}
