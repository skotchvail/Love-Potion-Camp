/* OpenProcessing Tweak of *@*http://www.openprocessing.org/sketch/10148*@* */
/* !do not delete the line above, required for linking your tweak if you re-upload */
/**
 * Table lookup Plasma Demo Effect
 * by luis2048. 
 * 
 * Cycles of changing colours warped to give an illusion 
 * of liquid, organic movement.Colors are the sum of sine 
 * functions stored in array lookup tables to make this the fastest 
 * plasma in all the land. Palette lookup from Zsolt Minier
 *
 */
class FastPlasma extends Drawer {

  FastPlasma(Pixels p, Settings s) {
  super(p, s, JAVA2D);
  }

  String getName() { return "FastPlasma"; }

  int pal []=new int [128];
  int[] cls;
  float onetwentyseven = 340;
  float thirtytwo = 32; 
  
  void setup(){
//    size(900, 400);
    onetwentyseven = 127.5;
    thirtytwo = 4;

//    float piSplit1 = settings.getParam(settings.keyCustom1) * 25;
//    float piSplit2 = settings.getParam(settings.keyCustom1) * 50;
   
    float s1,s2;
    for (int i=0;i<128;i++) {
      s1=sin(i*PI/25);
      s2=sin(i*PI/50+PI/4);
      pal[i]=color(128+s1*128,128+s2*128,s1*128);
    }
    
    cls = new int[width*height];
    for (int x = 0; x < width; x++)
    {
      for (int y = 0; y < height; y++)
      {
        cls[x+y*width] = (int)((onetwentyseven + +(onetwentyseven * sin(x / thirtytwo)))+ (onetwentyseven + +(onetwentyseven * cos(y / thirtytwo))) + (onetwentyseven + +(onetwentyseven * sin(sqrt((x * x + y * y)) / thirtytwo)))  ) / 4;
      }
    }
  }
  
  void draw()
  {
    pg.loadPixels();
    for (int pixelCount = 0; pixelCount < cls.length; pixelCount++)
    {                    
      pg.pixels[pixelCount] =  pal[(cls[pixelCount] + frameCount)&127];
    }
    pg.updatePixels();  
  }

}



