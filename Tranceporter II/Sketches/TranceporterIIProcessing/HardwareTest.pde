/*
 For testing the hardware layout of the LED's
 */

class HardwareTest extends Drawer {
  
  // Processing doesn't allow enums yet (sigh)
  final int kModeLowPower = 0;
  final int kModeLedTraining = 1;
  final int kModeCheckerboard = 2;
  final int kModeEachLedPanel = 3;
  final int kModeLowPowerWithCursor = 4;
  final int kModeVerticalLineSweep = 5;
  
  int drawMode = kModeLowPower;
  float lastTimeSwitched;
  int movementPixelFast;
  boolean povOutside;
  boolean iPadActionsAllowed;
  
  int[] strandColor = {
    color(255,  176,    33),    // strand 0
    color(0,    0,    200),     // strand 1
    color(0,    220,  0),       // strand 2
    color(0,    200,  200),     // strand 3
    color(200,  0,    0),       // strand 4
    color(200,  0,    150),     // strand 5
    color(200,  100,  0),       // strand 6
    color(200,  55,   100),     // strand 7
  };
  final color lowPowerColor = color(0, 30, 0);

  int cursorStrand;
  int cursorOrdinal;
  Point realCoordinate = new Point(); // Cursor Finder needs to temporarily overwrite the actual coordinates
  
  HardwareTest(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.TwoSides);
  }
  
  void setup(){
    colorMode(RGB, 255);
    settings.setParam(settings.keyFlash, 0.0);
    cursorStrand = prefs.getInt("hardware.cursorStrand", 0);
    cursorOrdinal = prefs.getInt("hardware.cursorOrdinal", 0);
    backupRealCoordinate();
  }
  
  String getName() { return "Hardware Test"; }
  String getCustom1Label() { return "Strand/Checks";}
  String getCustom2Label() { return "Cursor Finder";}
  
  void justExitedSketch() {
    super.justExitedSketch();
    iPadActionsAllowed = false;
    sendToIPad();
  }
  
  boolean originToLeft() {
    boolean portSide = main.ledMap.isStrandPortSide(cursorStrand);
    return povOutside ? portSide : !portSide;
  }
  
  void set3DAngle() {
    p.mappedBottleRotation = originToLeft() ? 0.75 : 0.25;
  }
  
  void sendToIPad() {
    super.sendToIPad();
    Point a = realCoordinate;
    if (a.x >= 0) {
      settings.sendMessageToIPad("/progLed/labelCoordinates", "" + a.x + ", " + a.y);
    }
    else {
      settings.sendMessageToIPad("/progLed/labelCoordinates", "missing");
    }
    settings.sendMessageToIPad("/progLed/labelStrand", "Save Strand " + (cursorStrand + 1));
    settings.sendMessageToIPad("/progLed/labelOrdinal", "LED " + cursorOrdinal);
    for (int i = 0; i < 6; i++) {
      settings.sendMessageToIPad("/progLed/drawModeToggle/1/" + (i+1), (iPadActionsAllowed && drawMode == i)?1:0);
    }
    int whichButton = povOutside ? 0 : 1;
    for (int i = 0; i < 2; i++) {
      settings.sendMessageToIPad("/progLed/toggleOutsideInside/1/" + (i+1), (iPadActionsAllowed && whichButton == i)?1:0);
    }
  }

  void backupRealCoordinate() {
    realCoordinate = main.ledMap.ledGet(cursorStrand, cursorOrdinal, false);
    main.ledMap.ledRawSet(cursorStrand, cursorOrdinal, 0, 0);
  }
  
  void restoreRealCoordinate() {
    main.ledMap.ledRawSet(cursorStrand, cursorOrdinal, realCoordinate.x, realCoordinate.y);
  }
  
  final int programStrandHigher = 1;
  final int programStrandLower = 2;
  final int programOrdinalLower = 3;
  final int programOrdinalHigher = 4;
  final int programOrdinalMuchLower = 5;
  final int programOrdinalMuchHigher = 6;
  final int programCoordYHigher = 7;
  final int programCoordYLower = 8;
  final int programCoordXLower = 9;
  final int programCoordXHigher = 10;
  final int programLedOff = 11;
  
  void handleOscEvent(OscMessage msg) {
    
    String addr = msg.addrPattern();
    if (!addr.startsWith("/progLed/"))
        return;
    String[] list = split(addr, '/');
    String action = list[2];
    println("hw action = " + action);

    if (action.equals("toggleOutsideInside")) {
      boolean pressed = (msg.get(0).floatValue() == 1.0);
      if (pressed) {
        if (main.currentMode() != this) {
          main.switchToDrawer(this);
        }
        if (!iPadActionsAllowed) {
          drawMode = kModeVerticalLineSweep;
        }
        int whichButton = Integer.parseInt(list[4]) - 1;
        povOutside = whichButton == 0;
        iPadActionsAllowed = true;
        set3DAngle();
        sendToIPad();
        return;
      }
    }

    if (!iPadActionsAllowed) {
      println("iPad actions not allowed until 'Program LEDs' is pressed");
      return;
    }
    
    if (action.equals("drawModeToggle")) {
      boolean pressed = (msg.get(0).floatValue() == 1.0);
      if (pressed) {
        drawMode = Integer.parseInt(list[4]) - 1;
        sendToIPad();
      }
    }
    else if (action.equals("SaveStrand")) {
      boolean pressed = (msg.get(0).floatValue() == 1.0);
      if (pressed) {
        restoreRealCoordinate();
        main.ledMap.writeOneStrand(cursorStrand);
        backupRealCoordinate();
      }
    }
    else {
      boolean pressed = (msg.get(0).floatValue() != 1.0);
      if (pressed) {
        int command = 0;
        if (action.equals("missing")) {
          command = programLedOff;
        }
        else if (action.equals("strandHigher")) {
          command = programStrandHigher;
        }
        else if (action.equals("strandLower")) {
          command = programStrandLower;
        }
        else if (action.equals("ordinalLower")) {
          command = programOrdinalLower;
        }
        else if (action.equals("ordinalMuchLower")) {
          command = programOrdinalMuchLower;
        }
        else if (action.equals("ordinalHigher")) {
          command = programOrdinalHigher;
        }
        else if (action.equals("ordinalMuchHigher")) {
          command = programOrdinalMuchHigher;
        }
        else if (action.equals("coordYHigher")) {
          command = programCoordYHigher;
        }
        else if (action.equals("coordYLower")) {
          command = programCoordYLower;
        }
        else if (action.equals("coordXLeft")) {
          command = originToLeft() ? programCoordXLower : programCoordXHigher;
        }
        else if (action.equals("coordXRight")) {
          command = originToLeft() ? programCoordXHigher : programCoordXLower;
        }
        if (command != 0) {
          doProgramAction(command);
        }
      }
    }
  }

  void keyPressed() {
    int command = 0;
    if (key == '>') {
      command = programStrandHigher;
    }
    else if (key == '<') {
      command = programStrandLower;
    }
    else if (key == '+') {
      command = programOrdinalMuchHigher;
    }
    else if (key == '_') {
      command = programOrdinalMuchLower;
    }
    else if (key == '=') {
      command = programOrdinalHigher;
    }
    else if (key == '-') {
      command = programOrdinalLower;
    }
    else if (key == 'x') {
      command = programLedOff;
    }
    else if (key == CODED) {
        if (keyCode == UP) {
          command = programCoordYHigher;
        }
        else if (keyCode == DOWN) {
          command = programCoordYLower;
        }
        else if (keyCode == LEFT) {
          command = originToLeft() ? programCoordXLower : programCoordXHigher;
        }
        else if (keyCode == RIGHT) {
          command = originToLeft() ? programCoordXHigher : programCoordXLower;
        }
    }

    if (command != 0) {
      doProgramAction(command);
    }
  }
    
  void doProgramAction(int command) {
    
    int oldCursorStrand = cursorStrand;
    
    restoreRealCoordinate();
    
    // Which strand
    if (command == programStrandHigher) {
      cursorStrand++;
    }
    else if (command == programStrandLower) {
      cursorStrand--;
    }
    if (cursorStrand < 0) {
      cursorStrand += main.ledMap.getNumStrands();
    }
    cursorStrand %= main.ledMap.getNumStrands();
    
    // Which LED on strand
    if (command == programOrdinalMuchHigher) {
      cursorOrdinal += 10;
    }
    else if (command == programOrdinalMuchLower) {
      cursorOrdinal -= 10;
    }
    else if (command == programOrdinalHigher) {
      cursorOrdinal++;
    }
    else if (command == programOrdinalLower) {
      cursorOrdinal--;
    }
    
    int strandSize = main.ledMap.getStrandSize(cursorStrand);
    
    if (cursorOrdinal < strandSize) {
      cursorOrdinal += strandSize;
    }
    assert cursorOrdinal >= 0;
    cursorOrdinal %= strandSize;
    
    if (command == programLedOff) {
      main.ledMap.ledSetRawValue(cursorStrand, cursorOrdinal, TC_PIXEL_UNUSED);
    }
    
    int xChange = 0;
    int yChange = 0;
    if (command == programCoordYHigher) {
      yChange = -1;
    }
    if (command == programCoordYLower) {
      yChange = +1;
    }
    if (command == programCoordXLower) {
      xChange = -1;
    }
    if (command == programCoordXHigher) {
      xChange = +1;
    }
    
    if (xChange != 0 || yChange != 0) {
      // Find the the current x, y
      // If current pixel is TC_PIXEL_UNUSED, base it on previous valid coordinate
      Point a = new Point(-1, -1);
      int whichOrdinal = cursorOrdinal;
      while (whichOrdinal >= 0) {
        a = main.ledMap.ledGet(cursorStrand, whichOrdinal, false);
        if (a.x >= 0) {
          break;
        }
        whichOrdinal--;
      };
      
      if (a.x < 0) {
        main.ledMap.ledRawSet(cursorStrand, cursorOrdinal, 0, 0);
      }
      else {
        int newX = a.x + xChange;
        int newY = a.y + yChange;
        
        int halfWidth = ledWidth / 2;
        if (newX >= halfWidth) {
          newX = 0;
        }
        else if (newX < 0) {
          newX = halfWidth - 1;
        }

        if (newY >= ledHeight) {
          newY = 0;
        }
        else if (newY < 0) {
          newY = ledHeight - 1;
        }
        main.ledMap.ledRawSet(cursorStrand, cursorOrdinal, newX, newY);
      }
    }
    prefs.putInt("hardware.cursorOrdinal", cursorOrdinal);
    prefs.putInt("hardware.cursorStrand", cursorStrand);
    needToFlushPrefs = true;
    backupRealCoordinate();
    sendToIPad();
    if (oldCursorStrand != cursorStrand) {
      set3DAngle();
    }
  }
  
  String[] getTextLines() {
    Point a = realCoordinate;
    
    return new String[] {
      "cursorStrand: " + (cursorStrand + 1),
      "cursorOrdinal: " + (cursorOrdinal + 0),
      a.x >= 0?("x:" + a.x + " y:" + a.y):"missingLed",
    };
  }
  
  ArrayList<String> getKeymapLines() {
    ArrayList<String> myStrings = main.getKeymapLines();
    
    myStrings.add(new String("← ↑ → ↓\tnavigate coordinates"));
    myStrings.add(new String("< >\tnavigate strands"));
    myStrings.add(new String("_ + - =\tnavigate LED's"));
    
    return myStrings;
  }
  
  boolean isTrainingMode() {
    return (drawMode == kModeLedTraining);
  }

  void drawCheckerboard() {
    // Draw checkerboard pattern
    pg.background(color(0, 0, 0));

    float slider = settings.getParam(settings.keyCustom1);
    int unit = (int)map(slider, 0.0, 1.0, 10, 2);
    int movementPixelSlow = movementPixelFast / 10;
    
    for (int x = 0; x < pg.width; x++) {
      if (x % unit == 0) {
        for (int y = 0; y < pg.height; y += unit) {
          
          int color1 = color(0, 0, 100);
          int color2 = color(100, 50, 0);
          int tensDigitX = (x % 100)/unit;
          int tensDigitY = (y % 100)/unit;
          int c = ((tensDigitX + tensDigitY) % 2 == 0) ? color1: color2;
          
          pg.noStroke();
          pg.fill(c);
          pg.rect(x, y, unit, unit);
        }
      }
      int whichPixel = movementPixelSlow % 10;
      if ((x % 10) == whichPixel) {
        pg.stroke(color(0, 0, 0));
        pg.line(x, 0, x, ledHeight);
      }
    }
  }
  
  void drawEachLedPanel() {
    // Draw Each panel one after the other
    
    //Fade out the previous graphics
    assert width == ledWidth;
    int halfWidth = width / 2;
    
    color colors[] =   {
      color(255, 0, 0),
      color(0, 255, 0),
      color(0, 0, 255),
      color(255, 255, 0),
    };
    
    pg.fill(0, 15);
    pg.rect(0, 0, width, height);
    float factor = map(settings.getParam(settings.keySpeed), 0.0, 1.0, 0.02, 0.3);
    int whichStrand = (int)(frameCount * factor) % main.ledMap.getNumStrands();
    color theColor = colors[whichStrand % colors.length];
    final boolean portSide = main.ledMap.isStrandPortSide(whichStrand);
    for (Point point: main.ledMap.pointsForStrand(whichStrand)) {
      if (!portSide) {
        point.x = width - point.x;
      }
      pg.set(point.x, point.y, theColor);
    }
  }
  
  void drawLineSweep() {
    pg.noStroke();
    pg.fill(0, 15);
    pg.rect(0, 0, width, height);
    int halfWidth = width / 2;
    int counter = (frameCount) % (halfWidth + height);
    if (counter < halfWidth) {
      pg.fill(255, 190, 0);
      pg.rect(halfWidth - counter, 0, 2, height + 1);
      pg.fill(134, 155, 210);
      pg.rect(halfWidth + counter, 0, 2, height + 1);
    }
    else {
      pg.fill(200, 50, 50);
      pg.rect(0, counter - halfWidth, halfWidth, 2);
      pg.fill(50, 200, 50);
      pg.rect(halfWidth, counter - halfWidth, halfWidth, 2);
    }
  }
  
  void drawTrainingMode() {
    // Erase background
    pg.noStroke();
    pg.fill(0, 10);
    pg.rect(0, 0, width, height);

    // Draw this Strand in blue
    int numLeds = main.ledMap.getStrandSize(cursorStrand);
    pg.stroke(0, 0, 255, 20);
    for (int ordinal = 0; ordinal < numLeds; ordinal++) {
      Point a = main.ledMap.ledGet(cursorStrand, ordinal);
      if (a.x < 0)
        continue;
      pg.point(a.x, a.y);
    }
    
    // Point out where the cursor is
    int half = 10;
    int delay = 4;
    int offset = (frameCount % ((half + 1) * delay)) / delay;
    
    color c = color(255, 255, 0);
    int whichOrdinal = cursorOrdinal - half + offset;
    if (whichOrdinal >= 0 && whichOrdinal < numLeds) {
      Point a = main.ledMap.ledGet(cursorStrand, whichOrdinal);
      pg.set(a.x,a.y,c);
    }
    
    whichOrdinal = cursorOrdinal + half - offset;
    if (whichOrdinal >= 0 && whichOrdinal < numLeds) {
      Point a = main.ledMap.ledGet(cursorStrand, whichOrdinal);
      pg.set(a.x,a.y,c);
    }
  }
  
  void draw() {
    colorMode(RGB, 255);
    
    if (millis() - lastTimeSwitched  >= 100) {
      //do something once a second
      movementPixelFast++;
      lastTimeSwitched = millis();
    }
    
    boolean useCursorFinder = false;
    int mode = drawMode;
    if (mode == kModeCheckerboard) {
      useCursorFinder = true;
      drawCheckerboard();
    }
    else if (mode == kModeLowPower) {
      // Draw solid low power color
      pg.background(lowPowerColor);
    }
    else if (mode == kModeEachLedPanel) {
      useCursorFinder = true;
      drawEachLedPanel();
    }
    else if (mode == kModeVerticalLineSweep) {
      useCursorFinder = true;
      drawLineSweep();
    }
    else if (mode == kModeLowPowerWithCursor) {
      useCursorFinder = true;
      // Draw solid low power color
      pg.background(lowPowerColor);
    }
    else {
      assert mode == kModeLedTraining : "unknown training mode " + mode;
      useCursorFinder = true;
      drawTrainingMode();
    }
    
    // Put in the cursor finder
    if (useCursorFinder) {
      // Blink the currently selected LED
      final int FRAMES = 10;
      float factor = (frameCount % ( FRAMES * 2)) / (FRAMES * 1.0);
      if (factor > 1.0) {
        factor = 2.0 - factor;
      }
      pg.stroke(factor * 255);
      Point a = main.ledMap.ledGet(cursorStrand, cursorOrdinal);
      if (a.x >= 0 && a.y >= 0) {
        if (!main.ledMap.isStrandPortSide(cursorStrand)) {
          a.x += ledWidth / 2;
        }
        pg.point(a.x, a.y);
      }
    }
  }
  
}
