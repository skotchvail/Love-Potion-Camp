/*
 
  For testing the hardware layout of the LED's
 */

class HardwareTest extends Drawer {

  HardwareTest(Pixels p, Settings s) {
    super(p, s, JAVA2D);
  }
    
  void setup(){
    colorMode(RGB,255);
  
  }

  String getName() { return "Hardware Test"; }
  String getCustom1Label() { return "Strand/Checks";}
  

  float lastTimeSwitched;
  int movementPixelFast;
  int[] strandColor = {
    color(255,176,33),  color(255,0,0),     color(255,255,0),
    color(0,255,0),     color(0,255,255),   color(0,0,255),
    color(255,0,255),   color(128, 50, 90), color(100,200,150)};
  

  
  void draw() {
    colorMode(RGB,255);

    if (millis() - lastTimeSwitched  >= 100) {
      //do something once a second
      movementPixelFast++;
      lastTimeSwitched = millis();
    }
    
    int movementPixelSlow = movementPixelFast / 10;

    float setting = settings.getParam(settings.keyCustom1);
    
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
          if (lastDigit == whichPixel)
            c = color(red(c)/2,green(c)/2,blue(c)/2);
          
          pg.set(a.x,a.y,c);
        }
      }

    }
  }
}
