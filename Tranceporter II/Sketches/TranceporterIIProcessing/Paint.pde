// Visualization to allow painting on the LEDwall as if it were a canvas.
// Custom1: zero is the basic drawing mode; values greater than zero specify a disappearing tail

class Paint extends Drawer {
  static final int MAX_TAIL_LENGTH = 100;

  int[][] canvas;
  int[][] tailX, tailY;
  int tailInd;

  Paint(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.RepeatingSides);
    canvas = new int[width][height];
    tailX = new int[MAX_TAIL_LENGTH][MAX_FINGERS];
    tailY = new int[MAX_TAIL_LENGTH][MAX_FINGERS];
    for (int i=0; i<MAX_FINGERS; i++) {
      for (int j=0; j<MAX_TAIL_LENGTH; j++) {
        tailX[j][i] = tailY[j][i] = -1;
      }
    }
    tailInd = 0;
  }

  String getName() { return "Paint"; }
  String getCustom1Label() { return "Tail Length";}

  void setup() {
     settings.setParam(settings.keyBrightness, 0.8); // set brightness to 80%
     settings.setParam(settings.keyCustom1, 0);
  }

  void reset() {
    println("Paint clear()");
    clear();
  }

  void draw() {
    pg.background(0);
    int tailLength = round(settings.getParam(settings.keyCustom1)*MAX_TAIL_LENGTH);

    for (int i=0; i< MAX_FINGERS; i++) {
      tailX[tailInd][i] = -1;
      tailY[tailInd][i] = -1;

      while (true) {
        Vec2D touch = getTouchFor(i, 100);
        if (touch == null) {
          break;
        }
        int x = (int)touch.x;
        int y = (int)touch.y;

        if (tailLength == 0) {
          int index = (frameCount + i * getNumColors() / MAX_FINGERS) % (getNumColors() - 1) + 1;
          canvas[x][y] = index;
        } else {
          tailX[tailInd][i] = x;
          tailY[tailInd][i] = y;
        }
      }
    }

    if (tailLength == 0) {
      for (int x=0; x<width; x++) {
        for (int y=0; y<height; y++) {
          pg.set(x, y, getColor(canvas[x][y]));
        }
      }
    } else {
      for (int i=0; i< MAX_FINGERS; i++) {
        for (int j=0; j<tailLength; j++) {
          int ind = (tailInd - j + MAX_TAIL_LENGTH) % MAX_TAIL_LENGTH;
          int x = tailX[ind][i];
          int y = tailY[ind][i];
          if (x != -1 && y != -1) {
            pg.set(x, y, getColor((frameCount + i * getNumColors() / MAX_FINGERS) % (getNumColors() - 1) + 1));
          }
        }
      }
    }
    tailInd = (tailInd + 1) % MAX_TAIL_LENGTH;
  }

  void clear() {
    for (int x=0; x<width; x++) {
      for (int y=0; y<height; y++) {
        canvas[x][y] = 0;
      }
    }
  }

  color getColor(int index) {
    if (index == 0) {
      return BLACK;
    }
    else {
      return super.getColor(index);
    }
  }
}
