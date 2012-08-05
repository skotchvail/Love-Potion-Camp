/*
 
  For testing the hardware layout of the LED's
 */

class HardwareTest extends Drawer {

  String getName() { return "Hardware Test"; }
  
  HardwareTest(Pixels p, Settings s) {
    super(p, s);
  }
    
  void setup(){
    colorMode(RGB,255);
  
  }


  float lastTimeSwitched;
  boolean drawGrid = false;
  void draw() {
    colorMode(RGB,255);
    pg.beginDraw();

//    if (millis() - lastTimeSwitched  >= 1000) {
//      //do something once a second
//      drawGrid = !drawGrid;
//      lastTimeSwitched = millis();
//    }

    boolean drawGrid = settings.getParam(settings.keyCustom1) > .5;
    
    int chunkX = 255 / ledWidth;
    int chunkY = 255 / ledHeight;
    
    if (drawGrid) {
      pg.noStroke();
      pg.background(color(0,0,0));

      for (int x = 0; x < pg.width; x += 10) {
        for (int y = 0; y < pg.height; y += 10) {
          
          int tensDigitX = (x % 100)/10;
          int tensDigitY = (y % 100)/10;

          pg.fill(color(10 + (tensDigitX * chunkX * 10), ((tensDigitX + tensDigitY) % 2 == 0) ? 100: 200, 255 - (tensDigitY * chunkY * 10)));
          pg.rect(x,y,10,10);
        }
      }
    }
    else {
      pg.background(color(220,238,191));
      
      for (int whichStrand = 0; whichStrand < p.kNumStrands; whichStrand++) {
        for (int ordinal = 0; ordinal < p.kPixelsPerStrand; ordinal++) {
          Point a = p.ledGet(whichStrand, ordinal);
          if (a.x < 0 || a.y < 0)
            continue;
          
          int lastDigit = ordinal % 10;
          int secondDigit = (ordinal % 100)/10;
          int c = color(255,255,255);
          if (lastDigit != 0) {
            c = color(50 + (10 * lastDigit), 80 + (10 * secondDigit),(255 - p.kPixelsPerStrand) + ordinal);
          }
          pg.set(a.x,a.y,c);
        }
      }

    }
    pg.endDraw();
  }
}
