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
  final int kModeOverlap = 6;
  final int kModeCross = 7;
  final int kModeNumDrawModes = 8;
  
  int drawMode = kModeLowPower;
  float lastTimeSwitched;
  float fader1Percent = 0.7;
  int movementPixelFast;
  boolean povOutside;
  boolean iPadActionsAllowed;
  int sweepLine;
  
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
  final color lowPowerColor = color(50, 0, 0);

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
    if (cursorOrdinal >= main.ledMap.getStrandSize(cursorStrand)) {
      cursorOrdinal = 0;
    }
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
    return povOutside;
  }
  
  void set3DAngle() {
    p.mappedBottleRotation = main.ledMap.isStrandPortSide(cursorStrand) ? 0.75 : 0.25;
  }
  
  void sendToIPad() {
    super.sendToIPad();
    settings.sendMessageToIPad("/progLed/fader1", "" + fader1Percent);
    if (realCoordinate.x >= 0) {
      Point a = main.ledMap.convertDoubleSidedPoint(realCoordinate, cursorStrand);
      settings.sendMessageToIPad("/progLed/labelCoordinates", "" + a.x + ", " + a.y);
    }
    else {
      settings.sendMessageToIPad("/progLed/labelCoordinates", "missing");
    }
    settings.sendMessageToIPad("/progLed/labelStrand", "Strand " + (cursorStrand + 1));
    settings.sendMessageToIPad("/progLed/labelOrdinal", "LED " + cursorOrdinal);
    for (int i = 0; i < kModeNumDrawModes; i++) {
      settings.sendMessageToIPad("/progLed/drawModeToggle/1/" + (i+1), (iPadActionsAllowed && drawMode == i)?1:0);
    }
    int whichButton = povOutside ? 0 : 1;
    for (int i = 0; i < 2; i++) {
      settings.sendMessageToIPad("/progLed/toggleOutsideInside/1/" + (i+1), (iPadActionsAllowed && whichButton == i)?1:0);
    }
  }

  void backupRealCoordinate() {
    realCoordinate = main.ledMap.ledGet(cursorStrand, cursorOrdinal, false);
    Point zeroPoint = new Point(0, 0);
    zeroPoint = main.ledMap.convertDoubleSidedPoint(zeroPoint, cursorStrand);
    main.ledMap.ledProgramCoordinate(cursorStrand, cursorOrdinal, zeroPoint);
  }
  
  void restoreRealCoordinate() {
    main.ledMap.ledProgramCoordinate(cursorStrand, cursorOrdinal, realCoordinate);
  }
  
  final int programStrandHigher = 1;
  final int programStrandLower = 2;
  final int programOrdinalLower = 3;
  final int programOrdinalHigher = 4;
  final int programOrdinalMuchLower = 5;
  final int programOrdinalMuchHigher = 6;
  final int programCoordYHigher = 7;
  final int programCoordYLower = 8;
  final int programCoordXHigher = 9;
  final int programCoordXLower = 10;
  final int programLedOff = 11;
  final int programOffsetYHigher = 12;
  final int programOffsetYLower = 13;
  final int programOffsetXHigher = 14;
  final int programOffsetXLower = 15;
  final int programOffsetOrdinalHigher = 16;
  final int programOffsetOrdinalLower = 17;
  
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
      println("iPad actions not allowed until 'Outside' or 'Inside' is pressed");
      return;
    }
    
    if (action.equals("drawModeToggle")) {
      boolean pressed = (msg.get(0).floatValue() == 1.0);
      if (pressed) {
        drawMode = Integer.parseInt(list[4]) - 1;
        sendToIPad();
      }
    }
    else if (action.equals("ResetStrand")) {
      boolean pressed = (msg.get(0).floatValue() == 1.0);
      if (pressed) {
        restoreRealCoordinate();
        main.ledMap.readOneStrandFromDisk(cursorStrand);
        main.ledMap.ledInterpolate();
        backupRealCoordinate();
        p.forceUpdateMaskPixels();
        sendToIPad();
      }
    }
    else if (action.equals("SaveStrand")) {
      boolean pressed = (msg.get(0).floatValue() == 1.0);
      if (pressed) {
        restoreRealCoordinate();
        main.ledMap.writeOneStrandToDisk(cursorStrand);
        backupRealCoordinate();
      }
    }
    else if (action.equals("fader1")) {
      fader1Percent = msg.get(0).floatValue();
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
        else if (action.equals("offsetYHigher")) {
          command = programOffsetYLower;
        }
        else if (action.equals("offsetYLower")) {
          command = programOffsetYHigher;
        }
        else if (action.equals("offsetXRight")) {
          command = originToLeft() ? programOffsetXHigher : programOffsetXLower;
        }
        else if (action.equals("offsetXLeft")) {
          command = originToLeft() ? programOffsetXLower : programOffsetXHigher;
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
    else if (key == 'o') { // TODO: not really needed on keyPress GUI, since they work on the iPad
      command = programOffsetOrdinalHigher;
    }
    else if (key == 'O') {
      command = programOffsetOrdinalLower;
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
    
  void doProgramAction(final int command) {
    
    int oldCursorStrand = cursorStrand;
    
    restoreRealCoordinate();
    
    //X and Y offsets
    Point delta = new Point(0,0);
    if (command == programOffsetYHigher) {
      delta.y = +1;
    }
    else if (command == programOffsetYLower) {
      delta.y = -1;
    }
    else if (command == programOffsetXHigher) {
      delta.x = +1;
    }
    else if (command == programOffsetXLower) {
      delta.x = -1;
    }
    if (delta.x != 0 || delta.y != 0) {
      println("offset = " + delta);
      main.ledMap.ledProgramCoordinateOffset(cursorStrand, cursorOrdinal, delta);
      p.forceUpdateMaskPixels();
    }
    
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
      main.ledMap.ledProgramMissing(cursorStrand, cursorOrdinal);
      p.forceUpdateMaskPixels();
    }
    
    int ordinalOffset = 0;
    if (command == programOffsetOrdinalHigher) {
      ordinalOffset = +1;
    }
    else if (command == programOffsetOrdinalLower) {
      ordinalOffset = -1;
    }
    if (ordinalOffset != 0) {
      if (main.ledMap.ledProgramOrdinalOffset(cursorStrand, cursorOrdinal, ordinalOffset)) {
        cursorOrdinal += ordinalOffset;
        p.forceUpdateMaskPixels();
      }
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
      println("xChange + " + xChange + " yChange " + yChange + " ordinal " + whichOrdinal);
      while (whichOrdinal >= 0) {
        a = main.ledMap.ledGet(cursorStrand, whichOrdinal, false);
        if (a.x >= 0) {
          break;
        }
        whichOrdinal--;
      };
      
      if (a.x < 0) {
        Point zeroPoint = new Point(0, 0);
        zeroPoint = main.ledMap.convertDoubleSidedPoint(zeroPoint, cursorStrand);
        main.ledMap.ledProgramCoordinate(cursorStrand, cursorOrdinal, zeroPoint);
      }
      else {
        int newX = a.x + xChange;
        int newY = a.y + yChange;
        
        int halfWidth = ledWidth / 2;
        boolean portSide = main.ledMap.isStrandPortSide(cursorStrand);
        int maxX = halfWidth;
        int minX = 0;
        if (!portSide) {
          maxX = ledWidth;
          minX = halfWidth;
        }
        
        if (newX >= maxX) {
          newX = minX;
        }
        else if (newX < minX) {
          newX = maxX - 1;
        }

        if (newY >= ledHeight) {
          newY = 0;
        }
        else if (newY < 0) {
          newY = ledHeight - 1;
        }
        main.ledMap.ledProgramCoordinate(cursorStrand, cursorOrdinal, new Point(newX, newY));
        p.forceUpdateMaskPixels();
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
    a = main.ledMap.convertDoubleSidedPoint(a, cursorStrand);

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
    myStrings.add(new String("o\tordinal offset"));
    return myStrings;
  }
  
  boolean isTrainingMode() {
    return (drawMode == kModeLedTraining);
  }

  void drawCheckerboard() {
    // Draw checkerboard pattern
    pg.background(color(0, 0, 0));

    int unit = (int)map(fader1Percent, 0.0, 1.0, 10, 2);
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
  
  void drawOverlap() {
    color black = color(0, 0, 0);
    Arrays.fill(pg.pixels, black);

    color colors[] =   {
      color(100, 0, 0),
      color(0, 100, 0),
      color(0, 0, 100),
      color(0, 100, 100),
    };

    // Draw the pixels that overlap in a bright color
    for (int whichStrand = 0; whichStrand < main.ledMap.getNumStrands(); whichStrand++) {
      for (Point point: main.ledMap.pointsForStrand(whichStrand)) {
        if (point.x >= 0) {
          int index = point.y * pg.width + point.x;
          if (pg.pixels[index] == black) {
            pg.pixels[index] = colors[whichStrand % colors.length];
          }
          else {
            pg.pixels[index] = color(255, 255, 0);
          }
        }
      }
    }
    pg.updatePixels();
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
    
    int halfStrands = main.ledMap.getNumStrands() / 2;
    
    pg.fill(0, 15);
    pg.rect(0, 0, width, height);
    float factor = map(settings.getParam(settings.keySpeed), 0.0, 1.0, 0.02, 0.3);
    
    int whichStrand = (int)(frameCount * factor) % halfStrands;
    color theColor = colors[whichStrand % colors.length];
    for (Point point: main.ledMap.pointsForStrand(whichStrand)) {
      pg.set(point.x, point.y, theColor);
    }

    whichStrand += halfStrands;
    for (Point point: main.ledMap.pointsForStrand(whichStrand)) {
      pg.set(point.x, point.y, theColor);
    }
  }
  
  void drawLineSweep() {
    pg.noStroke();
    pg.fill(0, 15);
    pg.rect(0, 0, width, height);
    int halfWidth = width / 2;

    final int kLevels = 20;
    int interval = kLevels - (int)(fader1Percent * (kLevels - 1));
    if (interval < kLevels && (frameCount % interval) == 0) {
      sweepLine++;
    }
    int counter = (sweepLine) % (halfWidth + height);
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

  void drawCross() {
    
    pg.noStroke();
    pg.fill(0);
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
    
    pg.noStroke();
    // Vertical above
    pg.fill(255, 190, 0);
    pg.rect(realCoordinate.x, 0, 1, realCoordinate.y);

    // Vertical below
    pg.fill(134, 155, 210);
    pg.rect(realCoordinate.x, realCoordinate.y, 1, height);

    // Vertical left
    pg.fill(200, 50, 50);
    pg.rect(0, realCoordinate.y, realCoordinate.x, 1);
    
    // Vertical right
    pg.fill(50, 200, 50);
    pg.rect(realCoordinate.x, realCoordinate.y, width, 1);
    
    // Vertical on other side
    int otherSideX = ledWidth - realCoordinate.x - 1;
    pg.fill(100, 100, 100);
    pg.rect(otherSideX, 0, 1, height / 2);

  }

  void drawTrainingMode() {
    // Erase background
    pg.noStroke();
    pg.fill(0);
    pg.rect(0, 0, width, height);

    // Draw this Strand in blue
    int numLeds = main.ledMap.getStrandSize(cursorStrand);
    pg.stroke(0, 0, 255);
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
    
    boolean useCursorFinder = true;
    int mode = drawMode;
    if (mode == kModeLowPower) {
      // Draw solid low power color
      pg.background(lowPowerColor);
      useCursorFinder = false;
    }
    else if (mode == kModeCheckerboard) {
      drawCheckerboard();
    }
    else if (mode == kModeEachLedPanel) {
      drawEachLedPanel();
    }
    else if (mode == kModeLowPowerWithCursor) {
      // Draw solid low power color
      pg.background(lowPowerColor);
    }
    else if (mode == kModeVerticalLineSweep) {
      drawLineSweep();
    }
    else if (mode == kModeOverlap) {
      drawOverlap();
    }
    else if (mode == kModeCross) {
      drawCross();
    }
    else {
      assert mode == kModeLedTraining : "unknown training mode " + mode;
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
      if (a.x >= 0) {
        pg.point(a.x, a.y);
      }
    }
  }
  
}
