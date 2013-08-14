class PacMan extends Drawer {
  private static final float MAX_ANGLE = PI / 4;

  private float rollAngle;
  private int buttons;
  private int releasedButtons;

  private final float centerX  = width * 0.55;
  private final float centerY  = height * 0.55;
  private final float diameter = min(width, height) * 0.65;
  private final float pelletDiameter = diameter * 0.15;
  private final float pelletStart    = centerX - diameter*7/8;
  private final float pelletStop     = centerX - diameter/8;

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

    float t = (frameCount % myFrameRate)/(float)myFrameRate;
    float angle = 1 - abs(2*t - 1);
    angle *= MAX_ANGLE;
    angle = PI - angle;

    // Pellet

    pg.stroke(255);
    pg.fill(255);
    pg.ellipse(lerp(pelletStart, pelletStop, t), centerY, pelletDiameter, pelletDiameter);


    // Pac-Man

    pg.stroke(255, 255, 0);
    pg.fill(255, 255, 0);
    pg.arc(centerX, centerY, diameter, diameter, -angle, angle);
  }
}
