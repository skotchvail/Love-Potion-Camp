// Visualziation to displaying flickering fire adapted from http://processing.org/learning/topics/firecube.html
// Custom1: use palette; Custom2: bottom row randomization cluster size

class Fire extends Drawer {
  // This will contain the pixels used to calculate the fire effect
  int[][] fire;

  // Flame colors
  color[] palette;
  float angle;
  int[] calc1, calc2, calc3, calc4, calc5;

  String getName() { return "Fire"; }
  String getCustom1Label() { return "Which Color";}
  String getCustom2Label() { return "Cluster Size";}
  boolean oldStyle = false;

  Fire(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.MirrorSides);

    calc1 = new int[width];
    calc3 = new int[width];
    calc4 = new int[width];
    calc2 = new int[height];
    calc5 = new int[height];

    fire = new int[width][height];
    palette = new color[256];
  }

  void setup(){
    colorMode(HSB);

    // Generate the palette
    for(int x = 0; x < palette.length; x++) {
      //Hue goes from 0 to 85: red to yellow
      //Saturation is always the maximum: 255
      //Lightness is 0..255 for x=0..128, and 255 for x=128..255
      if (oldStyle) {
        palette[x] = color(x/3, 255, constrain(x * 3, 0, 255));
      }
      else {
        palette[x] = color(x/3, 255, constrain(x * 5, 0, 255));
      }
    }

    // Precalculate which pixel values to add during animation loop
    // this speeds up the effect by 10fps
    for (int x = 0; x < width; x++) {
      calc1[x] = x % width;
      calc3[x] = (x - 1 + width) % width;
      calc4[x] = (x + 1) % width;
    }

    for(int y = 0; y < height; y++) {
      calc2[y] = (y + 1) % height;
      calc5[y] = (y + 2) % height;
    }

    settings.setParam(settings.keySpeed, 0.6); // set speed to 60%
    settings.setParam(settings.keyBrightness, 0.6); // set brightness to 60%
  }

  void draw() {

    // Randomize the bottom row of the fire buffer
    int clusterSize = round(settings.getParam(settings.keyCustom2)*10) + 1;
    for(int x = 0; x < width; x+=clusterSize) {
      int i = int(random(0, 190));
      for (int x2=x; x2<min(x+clusterSize, width); x2++) {
        fire[x2][height-1] = i;
      }
    }

    pg.loadPixels();
    int counter = 0;
    // Do the fire calculations for every pixel, from top to bottom
    for (int y = 0; y < height; y++) {
      for(int x = 0; x < width; x++) {
        // Add pixel values around current pixel

        int fireVal;
        fireVal = fire[x][y] =
            ((fire[calc3[x]][calc2[y]]
            + fire[calc1[x]][calc2[y]]
            + fire[calc4[x]][calc2[y]]
            + fire[calc1[x]][calc5[y]]
            ) << 5) / 134;//135; //129;

        // Output everything to screen using our palette colors
        if (counter >= height*width) continue;
        if (int(settings.getParam(settings.keyCustom1) + 0.5) == 1) {
          pg.pixels[counter++] = getColor(fireVal*(getNumColors()-1)/256);
        } else {
          pg.pixels[counter++] = palette[fireVal];
        }
      }
    }
    for (int y = height - 1; y < height - 4; y++) {
      for(int x = 0; x < width; x++) {
        pg.pixels[y * width + x] = color(255, 200, 0);
      }
    }
    pg.updatePixels();
  }
}
