class PacMan extends Drawer {
  private static final float MAX_ANGLE = PI / 4;

  private float rollAngle;
  private int buttons;
  private int releasedButtons;

  private final int centerX = (int) (width * 0.55);
  private final int centerY = (int) (height * 0.55);
  private final int diameter = (int) (min(width, height) * 0.65);
  private float desiredFrameRate;

  // Ball State

  PacMan(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.RepeatingSides);
  }

  String getName() {
    return "Pac-Man";
  }

  void wiimoteAccel(float x, float y, float z, float pitch, float roll, float tilt) {
  }

  void wiimoteButtons(int buttons) {
  }

  void setup() {
    desiredFrameRate = frameRate * 2;
  }

  void draw() {
    pg.background(0);
    pg.colorMode(RGB);
    pg.stroke(255, 255, 0);
    pg.fill(255, 255, 0);

    float angle = abs(2 * (frameCount % desiredFrameRate) / (float) desiredFrameRate - 1.0f);
    angle *= MAX_ANGLE;
    angle = PI - angle;

    pg.arc(centerX, centerY, diameter, diameter, -angle, angle);
  }
}
