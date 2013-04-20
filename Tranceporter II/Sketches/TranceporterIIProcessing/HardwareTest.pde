/*
 
 For testing the hardware layout of the LED's
 */

int cursorStrand;
int cursorOrdinal;

class HardwareTest extends Drawer {
  
  HardwareTest(Pixels p, Settings s) {
    super(p, s, JAVA2D);
  }
  
  void setup(){
    colorMode(RGB, 255);
    settings.setParam(settings.keyFlash, 0.0);
  }
  
  String getName() { return "Hardware Test"; }
  String getCustom1Label() { return "Strand/Checks";}
  String getCustom2Label() { return "Cursor Finder";}
  
  
  float lastTimeSwitched;
  int movementPixelFast;
  int[] strandColor = {
  color(255,  176,    33),    // strand 0
  color(0,    0,    200),    // strand 1
  color(0,    220,  0),   // strand 2
  color(0,    200,  200),     // strand 3
  color(200,  0,    0),   // strand 4
  color(200,  0,    150),     // strand 5
  color(200,  100,  0),     // strand 6
  color(200,  55,   100),   // strand 7
  };
  
  void keyPressed() {
    
    int oldCursorOrdinal = cursorOrdinal;
    int oldCursorStrand = cursorStrand;
    
    //which strand
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
    
    //which LED on strand
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
    cursorOrdinal %= strandSize;
    
    if (key == 'x') {
      //p.ledRawSet(cursorStrand, cursorOrdinal, -999999, -999999);
    }
    
    // TOOD: Ralph says: read arrow keys - I'm not sure this is actually useful - it doesn't seem to work
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
        int whichOrdinal = cursorOrdinal;
        Point a;
        
        // this will throw an exception if we've received a keystroke that runs off the map - maybe we should just set a floor/ceiling
        do {
          assert(whichOrdinal > 0) : "bad whichOrdinal: " + whichOrdinal;
          a = p.ledGet(cursorStrand, whichOrdinal, false);
          whichOrdinal--;
        } while (a.x < 0);
        
        // println("Setting " + cursorStrand + ", " + cursorOrdinal + ", " + (a.x + xChange) + ", " + (a.y + yChange) );
        p.ledRawSet(cursorStrand, cursorOrdinal, a.x + xChange, a.y + yChange);
        //p.ledInterpolate();
        
      }
    }
    
    println( "keyPressed cursorStrand:"  + (cursorStrand + 1) +  "cursorOrdinal:" + (cursorOrdinal + 1));
  }
  
  String[] getTextLines() {
    
    Point a = p.ledGet(cursorStrand, cursorOrdinal, false);
    
    
    return new String[]{
      
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
    
    // TODO: this doesn't seem to work, so let's not display it for now
    // myStrings.add(new String("arrows   select pixel in indicated direction"));
    
    return myStrings;
  }
  
  final float kLevelGrid = 0.4;
  final float kLevelGreen = 0.2;
  
  boolean isTrainingMode() {
    float setting = settings.getParam(settings.keyCustom1);
    if (setting > kLevelGrid) {
      return false;
    }
    return true;
  }
  
  
  void draw() {
    colorMode(RGB,255);
    
    if (millis() - lastTimeSwitched  >= 100) {
      //do something once a second
      movementPixelFast++;
      lastTimeSwitched = millis();
    }
    
    int movementPixelSlow = movementPixelFast / 10;
    
    float setting = settings.getParam(settings.keyCustom1);
    //    println("setting = " + setting);
    
    int chunkX = 255 / width;
    int chunkY = 255 / height;
    
    if (setting > kLevelGrid) {
      pg.background(color(0,0,0));
      
      int unit = 10;
      if (setting > 0.95)
        unit = 2;
      else if (setting > 0.90)
        unit = 3;
      else if (setting > 0.85)
        unit = 4;
      else if (setting > 0.80)
        unit = 5;
      else if (setting > 0.75)
        unit = 6;
      else if (setting > 0.70)
        unit = 7;
      else if (setting > 0.65)
        unit = 8;
      else if (setting > 0.60)
        unit = 9;
      
      for (int x = 0; x < pg.width; x++) {
        if (x % unit == 0) {
          for (int y = 0; y < pg.height; y += unit) {
            
            int tensDigitX = (x % 100)/unit;
            int tensDigitY = (y % 100)/unit;
            
            pg.noStroke();
            
            int color1 = color(0,0,100);
            int color2 = color(100,50,0);
            
            int c = ((tensDigitX + tensDigitY) % 2 == 0) ? color1: color2;
            
            pg.fill(c);
            
            //            pg.fill(color(10 + (tensDigitX * chunkX * unit), ((tensDigitX + tensDigitY) % 2 == 0) ? 100: 200, 255 - (tensDigitY * chunkY * unit)));
            pg.rect(x,y,unit,unit);
          }
        }
        int whichPixel = movementPixelSlow % 10;
        if ((x % 10) == whichPixel) {
          pg.stroke(color(0,0,0));
          pg.line(x,0,x,ledHeight);
        }
      }
    }
    else if (setting >= kLevelGreen) {
      pg.background(0,30,0);
    }
    else {
      pg.background(color(220,238,191));
      
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
            //            int color1 = color(108,158,190);
            //            int color2 = color(69,69,190);
            
            int color1 = color(140,140,140);
            int color2 = color(25,25,25);
            //color2 = color(255,255,255);
            c = ((secondDigit % 2) == 1)?color1:color2;
          }
          
          int whichPixel = (movementPixelFast + 1) % 10;
          if (lastDigit == whichPixel) {
            c = color(red(c)/2,green(c)/2,blue(c)/2);
          }
          pg.set(a.x,a.y,c);
        }
      }
    }
    
    if (true) {
      
      int cursorFinder = (int)(settings.getParam(settings.keyCustom2) * 20);
      
      //if (setting >= kLevelGreen && setting < kLevelGrid) {
      if (cursorFinder > 0) {
        for (int i = cursorOrdinal - cursorFinder; i < cursorOrdinal + cursorFinder; i++) {
          if (i < 0) {
            continue;
          }
          if (i >= p.getStrandSize(cursorStrand)) {
            continue;
          }
          Point a = p.ledGet(cursorStrand, i);
          color c = color(255,255,0);
          
          if (a.x >= 0 && a.y >= 0) {
            pg.set(a.x,a.y,c);
          }
          
        }
      }
      
      
      Point a = p.ledGet(cursorStrand, cursorOrdinal);
      final int FRAMES = 10;
      float factor = (frameCount % ( FRAMES * 2)) / (FRAMES * 1.0);
      
      if (factor > 1.0) {
        factor = 2.0 - factor;
      }
      color c = color(0 * factor, 0 * factor, 255 * factor);
      
      if (a.x >= 0 && a.y >= 0) {
        pg.set(a.x,a.y,c);
      }
      
      
    }
    
    
  }
  
}
