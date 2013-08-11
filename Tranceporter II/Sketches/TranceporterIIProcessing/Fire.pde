// Visualziation to displaying flickering fire adapted from http://processing.org/learning/topics/firecube.html
// Custom1: use palette; Custom2: bottom row randomization cluster size

class Fire extends Drawer {
  // This will contain the pixels used to calculate the fire effect
  int[][] fire;

  // Flame colors
  color[] palette = new color[140];
  float angle;
  int[] calc1, calc2, calc3, calc4, calc5;
  int height2;
  float whichColor = -1;

  String getName() { return "Fire"; }
  String getCustom1Label() { return "Which Color";}
  String getCustom2Label() { return "Cluster Size";}

  Fire(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.MirrorSides);
    height2 = height - 4;

    calc1 = new int[width];
    calc3 = new int[width];
    calc4 = new int[width];
    calc2 = new int[height2];
    calc5 = new int[height2];

    fire = new int[width][height2];
  }

  void setup(){
    colorMode(HSB);
    
    // Precalculate which pixel values to add during animation loop
    // this speeds up the effect by 10fps
    for (int x = 0; x < width; x++) {
      calc1[x] = x % width;
      calc3[x] = (x - 1 + width) % width;
      calc4[x] = (x + 1) % width;
    }

    for(int y = 0; y < height2; y++) {
      calc2[y] = (y + 1) % height2;
      calc5[y] = (y + 2) % height2;
    }
  }

  void draw() {

    if (whichColor != settings.getParam(settings.keyCustom1)) {
      whichColor = settings.getParam(settings.keyCustom1);
      generatePalette();
    }
    
    // Randomize the bottom row of the fire buffer
    int clusterSize = round(settings.getParam(settings.keyCustom2)*10) + 1;
    for(int x = 0; x < width; x+=clusterSize) {
      int i = int(random(0, 190));
      for (int x2=x; x2<min(x+clusterSize, width); x2++) {
        fire[x2][height2-1] = i;
      }
    }

    pg.loadPixels();
    int counter = 0;
    // Do the fire calculations for every pixel, from top to bottom
    for (int y = 0; y < height2; y++) {
      for(int x = 0; x < width; x++) {
        // Add pixel values around current pixel

        int fireVal =
            fire[calc3[x]][calc2[y]]
            + fire[calc1[x]][calc2[y]]
            + fire[calc4[x]][calc2[y]]
            + fire[calc1[x]][calc5[y]]
            ;
        fireVal *= 0.242; // between 0 and 140, approximately
        fireVal = constrain(fireVal, 0, palette.length - 1);
        fire[x][y] = fireVal;
        
        // Output everything to screen using our palette colors
        pg.pixels[counter++] = palette[fireVal];
      }
    }
    
    for (int y = height2; y < height; y++) {
      for(int x = 0; x < width; x++) {
        pg.pixels[y * width + x] = BLACK;
      }
    }
    pg.updatePixels();
  }
  
  void generatePalette() {
    colorMode(HSB);

    int startHue = 0; // Red
    int endHue = 64; // Yellow
    if (whichColor > 0.3) {
      int interval = 40;
      startHue = (int)map(whichColor, 0.3, 1.0, 0, 255 - interval);
      endHue = startHue + interval;
    }
    
    int paletteSize = palette.length;
    int whiteBorder = (int)(paletteSize * 0.6);
    for(int x = 0; x < whiteBorder; x++) {
      palette[x] = color(map(x, 0, whiteBorder, startHue, endHue), 255, map(x, 0, whiteBorder * 0.6, 0, 255));
    }
    for(int x = whiteBorder; x < paletteSize; x++) {
      palette[x] = color(endHue, paletteSize - x, 255);
    }
  }
  
}
