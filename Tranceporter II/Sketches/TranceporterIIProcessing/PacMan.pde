class PacMan extends Drawer {
  private static final float MAX_ANGLE = PI / 4;

  private float rollAngle;
  private int buttons;
  private int releasedButtons;

  private final float centerX = width * 0.55;
  private final float centerY = height * 0.55;
  private final float diameter = min(width, height) * 0.65;
  private int myFrameRate;

  // Ball State

  PacMan(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.MirrorSides);
  }

  @Override
  String getName() {
    return "Pac-Man";
  }

  @Override
  void wiimoteAccel(float x, float y, float z, float pitch, float roll, float tilt) {
  }

  @Override
  void wiimoteButtons(int buttons) {
  }

  @Override
  void justEnteredSketch() {
    this.myFrameRate = round(frameRate) * 2;
  }

  @Override
  void draw() {
    pg.background(0);
    pg.colorMode(RGB);
    pg.stroke(255, 255, 0);
    pg.fill(255, 255, 0);

    float angle = abs(2*(frameCount % myFrameRate)/(float)myFrameRate - 1);
    angle *= MAX_ANGLE;
    angle = PI - angle;

    pg.arc(centerX, centerY, diameter, diameter, -angle, angle);
  }
}
