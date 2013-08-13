class CircularPong extends Drawer {
  private static final float HALF_PADDLE_SPAN = (float) (Math.PI / 6.0 / 2.0);

  private float rollAngle;
  private int buttons;
  private int releasedButtons;

  private final int centerX = width/2;
  private final int centerY = height/2;
  private final int diameter = (int)(Math.min(width, height) * 0.65);

  CircularPong(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.RepeatingSides);
  }

  String getName() {
    return "Circular Pong";
  }

  void wiimoteAccel(float x, float y, float z, float pitch, float roll, float tilt) {
    this.rollAngle = (float) (-(roll + Math.PI));
  }

  void wiimoteButtons(int buttons) {
    this.releasedButtons = this.buttons & ~buttons;
    this.buttons = buttons;
  }

  void draw() {
    pg.background(0);
    pg.strokeWeight(3);
    pg.stroke(255);
    pg.noFill();
    pg.arc(centerX, centerY, diameter, diameter, rollAngle - HALF_PADDLE_SPAN, rollAngle + HALF_PADDLE_SPAN);
  }
}
