/*
 For testing the hardware layout of the LED's
 */

class HardwareTest extends Drawer {
  
  // Processing doesn't allow enums yet (sigh)
  final int kModeCheckerboard = 4;
  final float kModeCheckerboardLevel = 0.4;
  
  final int kModeLowPower = 3;
  final float kModeLowPowerLevel = 0.3;
  
  final int kModeEachLedPanel = 2;
  final float kModeEachLedPanelLevel = 0.2;
  
  final int kModeVerticalLineSweep = 1;
  final float kModeVerticalLineSweepLevel = 0.1;

  final int kModeLedTraining = 0;
  final float kModeLedTrainingLevel = 0.0;
  
  float lastTimeSwitched;
  int movementPixelFast;
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

  int cursorStrand;
  int cursorOrdinal;
  
  HardwareTest(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.TwoSides);
  }
  
  void setup(){
    colorMode(RGB, 255);
    settings.setParam(settings.keyFlash, 0.0);
  }
  
  String getName() { return "Hardware Test"; }
  String getCustom1Label() { return "Strand/Checks";}
  String getCustom2Label() { return "Cursor Finder";}
  
  void keyPressed() {
    
    int oldCursorOrdinal = cursorOrdinal;
    int oldCursorStrand = cursorStrand;
    
    // Which strand
    if (key == '>') {
      cursorStrand++;
    }
    else if (key == '<') {
      cursorStrand--;
    }
    if (cursorStrand < 0) {
      cursorStrand += p.getNumStrands();
    }
    cursorStrand %= p.getNumStrands();
    
    // Which LED on strand
    if (key == '+') {
      cursorOrdinal += 10;
    }
    else if (key == '_') {
      cursorOrdinal -= 10;
    }
    else if (key == '=') {
      cursorOrdinal++;
    }
    else if (key == '-') {
      cursorOrdinal--;
    }
    
    int strandSize = p.getStrandSize(cursorStrand);
    
    if (cursorOrdinal < strandSize ) {
      cursorOrdinal += strandSize;
    }
    assert cursorOrdinal >= 0;
    cursorOrdinal %= strandSize;
    
    if (key == 'x') {
      //p.ledRawSet(cursorStrand, cursorOrdinal, -999999, -999999);
    }
    
    if (key == CODED) {
      if (keyCode == UP || keyCode == DOWN || keyCode == LEFT || keyCode == RIGHT) {
        int xChange = 0;
        int yChange = 0;
        if (keyCode == UP) {
          yChange = -1;
        }
        if (keyCode == DOWN) {
          yChange = 1;
        }
        if (keyCode == LEFT) {
          xChange = 1;
        }
        if (keyCode == RIGHT) {
          xChange = -1;
        }

        // Find the x, y for the cursorOrdinal, and modify it
        Point a = new Point(-1, -1);
        int whichOrdinal = cursorOrdinal;
        while (whichOrdinal >= 0) {
          a = p.ledGet(cursorStrand, whichOrdinal, false);
          if (a.x >= 0) {
            break;
          }
          whichOrdinal--;
        };
        
        p.ledRawSet(cursorStrand, cursorOrdinal, a.x + xChange, a.y + yChange);
      }
    }
  }
  
  String[] getTextLines() {
    
    Point a = p.ledGet(cursorStrand, cursorOrdinal, false);
    
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
  
  int modeFromSlider() {
    float slider = settings.getParam(settings.keyCustom1);
    if (slider >= kModeCheckerboardLevel)
      return kModeCheckerboard;
    if (slider >= kModeLowPowerLevel)
      return kModeLowPower;
    if (slider >= kModeEachLedPanelLevel)
      return kModeEachLedPanel;
    if (slider >= kModeVerticalLineSweepLevel)
      return kModeVerticalLineSweep;
    return kModeLedTraining;
  }
  
  boolean isTrainingMode() {
    return (modeFromSlider() == kModeLedTraining);
  }

  void drawCheckerboard() {
    // Draw checkerboard pattern
    pg.background(color(0, 0, 0));

    float slider = settings.getParam(settings.keyCustom1);
    int unit = (int)map(slider, kModeCheckerboardLevel, 1.0, 10, 2);
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
    int whichStrand = (int)(frameCount * factor) % p.getNumStrands();
    color theColor = colors[whichStrand % colors.length];
    final boolean portSide = p.isStrandPortSide(whichStrand);
    for (Point point: p.pointsForStrand(whichStrand)) {
      if (!portSide) {
        point.x = width - point.x;
      }
      pg.set(point.x, point.y, theColor);
    }
  }
  
  void drawVerticalLineSweep() {
    pg.noStroke();
    pg.fill(0, 100 * settings.getParam(settings.keySpeed));
    pg.rect(0, 0, width, height);
    int counter = (frameCount) % width;
    pg.fill(255, 128, 0);
    pg.rect(counter, 0, 2, height + 1);
  }
  
  void drawTrainingMode() {
    // Draw Each LED a separate color
    pg.background(color(220, 238, 191));
    
    for (int whichStrand = 0; whichStrand < p.getNumStrands(); whichStrand++) {
      int strandSize = p.getStrandSize(whichStrand);
      for (int ordinal = 0; ordinal < strandSize; ordinal++) {
        Point a = p.ledGet(whichStrand, ordinal);
        if (a.x < 0 || a.y < 0)
          continue;
        
        int lastDigit = ordinal % 10;
        int secondDigit = (ordinal % 100)/10;
        int c = strandColor[whichStrand] ;
        
        if (lastDigit != 0) {
          int color1 = color(140, 140, 140);
          int color2 = color(25, 25, 25);
          c = ((secondDigit % 2) == 1)?color1:color2;
        }
        
        int whichPixel = (movementPixelFast + 1) % 10;
        if (lastDigit == whichPixel) {
          c = color(red(c)/2, green(c)/2, blue(c)/2);
        }
        pg.set(a.x, a.y, c);
      }
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
    int mode = modeFromSlider();
    if (mode == kModeCheckerboard) {
      useCursorFinder = true;
      drawCheckerboard();
    }
    else if (mode == kModeLowPower) {
      // Draw solid low power color
      pg.background(0, 30, 0);
    }
    else if (mode == kModeEachLedPanel) {
      useCursorFinder = true;
      drawEachLedPanel();
    }
    else if (mode == kModeVerticalLineSweep) {
      useCursorFinder = true;
      drawVerticalLineSweep();
    }
    else {
      assert mode == kModeLedTraining;
      useCursorFinder = true;
      drawTrainingMode();
    }
    
    // Put in the cursor finder
    if (useCursorFinder) {
      // Draw the LED's before and after the currently selected LED
      int cursorFinder = (int)(settings.getParam(settings.keyCustom2) * 20);
      if (cursorFinder > 0) {
        for (int i = cursorOrdinal - cursorFinder; i < cursorOrdinal + cursorFinder; i++) {
          if (i < 0) {
            continue;
          }
          if (i >= p.getStrandSize(cursorStrand)) {
            continue;
          }
          Point a = p.ledGet(cursorStrand, i);
          color c = color(255, 255, 0);
          
          if (a.x >= 0 && a.y >= 0) {
            pg.set(a.x, a.y, c);
          }
        }
      }

      // Blink the currently selected LED
      final int FRAMES = 10;
      float factor = (frameCount % ( FRAMES * 2)) / (FRAMES * 1.0);
      if (factor > 1.0) {
        factor = 2.0 - factor;
      }
      color c = color(0 * factor, 0 * factor, 255 * factor);
      Point a = p.ledGet(cursorStrand, cursorOrdinal);
      if (a.x >= 0 && a.y >= 0) {
        pg.set(a.x, a.y, c);
      }
    }
  }
  
}
