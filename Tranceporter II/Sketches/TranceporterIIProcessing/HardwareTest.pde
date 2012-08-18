/*
 
 For testing the hardware layout of the LED's
 */

int cursorPreviousValue;
int cursorStrand;
int cursorOrdinal;

class HardwareTest extends Drawer {
  
  HardwareTest(Pixels p, Settings s) {
    super(p, s, JAVA2D);
  }
  
  void setup(){
    colorMode(RGB,255);
    settings.setParam(settings.keyFlash,0.0);
    cursorPreviousValue = p.ledGetRawValue(cursorStrand, cursorOrdinal, p.useTrainingMode);
  }
  
  String getName() { return "Hardware Test"; }
  String getCustom1Label() { return "Strand/Checks";}
  
  
  float lastTimeSwitched;
  int movementPixelFast;
  int[] strandColor = {
  color(255,176,33),  color(255,0,0),     color(255,255,0),
  color(0,255,0),     color(0,255,255),   color(0,0,255),
  color(255,0,255),   color(128, 50, 90), color(100,200,150)};
  
  void keyPressed() {
    
    int oldCursorOrdinal = cursorOrdinal;
    int oldCursorStrand = cursorStrand;
    
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
    if (cursorOrdinal < p.kPixelsPerStrand ) {
      cursorOrdinal += p.kPixelsPerStrand;
    }
    cursorOrdinal %= p.kPixelsPerStrand;
    if (key == '>') {
      cursorStrand++;
    }
    else if (key == '<') {
      cursorStrand--;
    }
    cursorStrand %= p.kNumStrands;
    if (cursorStrand != oldCursorStrand || cursorOrdinal != oldCursorOrdinal) {
      p.ledSetRawValue(oldCursorStrand, oldCursorOrdinal, cursorPreviousValue);
      cursorPreviousValue = p.ledGetRawValue(cursorStrand, cursorOrdinal, p.useTrainingMode);
      if (cursorPreviousValue < 0) {
        p.ledRawSet(cursorStrand, cursorOrdinal,0,0);
      }
    }

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
        int whichOrdinal = cursorOrdinal;
        Point a;
        do {
          assert(whichOrdinal > 0);
          a = p.ledGet(cursorStrand, whichOrdinal, false);
          whichOrdinal--;
        } while (a.x < 0);
        p.ledRawSet(cursorStrand, cursorOrdinal, a.x + xChange, a.y + yChange);
        //p.ledInterpolate();
        
      }
    }
    
    
    
    println( "cursorStrand:"  + cursorStrand + "cursorOrdinal:" + cursorOrdinal);
  }
  
  String[] getTextLines() {
    
    Point a = p.ledGet(cursorStrand, cursorOrdinal, false);
    
    
    return new String[]{
      
      "cursorStrand: " + cursorStrand,
      "cursorOrdinal: " + cursorOrdinal,
      a.x >= 0?("x:" + a.x + " y:" + a.y):"missingLed",
    };
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
    
    int chunkX = 255 / ledWidth;
    int chunkY = 255 / ledHeight;
    
    if (setting > 0.4) {
      p.useTrainingMode = false;
      
      pg.background(color(0,0,0));
      
      //      println("setting=" + setting);
      
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
    else if (setting > 0.29) {
      //p.useTrainingMode = false;
      pg.background(0,30,0);
    }
    else {
      p.useTrainingMode = true;
      
      pg.background(color(220,238,191));
      
      for (int whichStrand = 0; whichStrand < p.kNumStrands; whichStrand++) {
        for (int ordinal = 0; ordinal < p.kPixelsPerStrand; ordinal++) {
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
    
//    if (p.useTrainingMode) {
    if (true) {
      Point a = p.ledGet(cursorStrand, cursorOrdinal);
      final int FRAMES = 10;
      float factor = (frameCount % ( FRAMES * 2)) / (FRAMES * 1.0);
      
      if (factor > 1.0) {
        factor = 2 - factor;
      }
      color c = color(255 * factor, 0 * factor, 0 * factor);

      if (a.x >= 0 && a.y >= 0) {
        pg.set(a.x,a.y,c);
      }
    }

    
  }
  
}
