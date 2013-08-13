import com.qindesign.wii.Wiimote;
import com.qindesign.wii.WiimoteMath;

class CircularPong extends Drawer {
  private static final float HALF_PADDLE_SPAN = PI / 12;
  private static final float PADDLE_STROKE_WIDTH = 3;
  private static final float HALF_PADDLE_STROKE_WIDTH = PADDLE_STROKE_WIDTH / 2;
  private static final float BALL_DIA = 2;
  private static final float BALL_RADIUS = BALL_DIA / 2;
  private static final float TIME_TO_CROSS_ARENA_RADIUS = 2;

  private final float centerX = width * 0.5;
  private final float centerY = height * 0.55;
  private final float arenaDiameter = min(width, height) * 0.65;
  private final float arenaRadius = arenaDiameter / 2;

  private float myFrameRate;
  private float rollAngle;
  private int buttons;
  private int releasedButtons;

  // Ball State

  private float ballX;
  private float ballY;
  private float ballSpeedX;
  private float ballSpeedY;

  // Game State

  private static final int START = 0;
  private static final int PLAYING = 1;
  private static final int LOST_BALL = 2;
  private int state;


  CircularPong(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.RepeatingSides);
  }

  String getName() {
    return "Circular Pong";
  }

  @Override
  void wiimoteAccel(float x, float y, float z, float pitch, float roll, float tilt) {
    // Make the roll angle align with the bottom of the controller
    // Note that it will be in the range 0 to 2 pi

    rollAngle = PI - roll;
  }

  @Override
  void wiimoteButtons(int buttons) {
    this.releasedButtons = this.buttons & ~buttons;
    this.buttons = buttons;
    if (releasedButtons != 0) {
      System.out.println("releasedButtons = " + Integer.toBinaryString(releasedButtons));
    }
  }

  @Override
  void justEnteredSketch() {
    reset();
    this.myFrameRate = round(frameRate);
    System.out.println("myFrameRate = " + myFrameRate);

    buttons = 0;
    releasedButtons = 0;
  }

  @Override
  void reset() {
    ballX = centerX;
    ballY = centerY;
    ballSpeedX = 0;
    ballSpeedY = 0;

    state = START;
  }

  private void start() {
    float speed = arenaRadius / TIME_TO_CROSS_ARENA_RADIUS / myFrameRate;

    float angle = random(TWO_PI);
    ballSpeedX = cos(angle) * speed;
    ballSpeedY = sin(angle) * speed;

    state = PLAYING;
  }

  @Override
  void draw() {
    // Draw paddle

    pg.background(0);
    pg.strokeWeight(PADDLE_STROKE_WIDTH);
    pg.stroke(255);
    pg.noFill();
    float paddleStart = rollAngle - HALF_PADDLE_SPAN;
    float paddleEnd = rollAngle + HALF_PADDLE_SPAN;
    pg.arc(centerX, centerY, arenaDiameter, arenaDiameter, paddleStart, paddleEnd);

    // State machine

    switch (state) {
      case START:
        if ((releasedButtons & Wiimote.BUTTON_B) != 0) {
          start();
        }
        break;
      case PLAYING:
        ballX += ballSpeedX;
        ballY += ballSpeedY;

        if (outOfBounds(ballX, ballY)) {
          reset();
        } else if (collision(ballX, ballY)) {
          System.out.println("Collision!");
          ballSpeedX = -ballSpeedX;
          ballSpeedY = -ballSpeedY;
        }
        break;

      case LOST_BALL:
        ballX += ballSpeedX;
        ballY += ballSpeedY;

        if (outOfBounds(ballX, ballY)) {
          reset();
        }
        break;
    }

    // Draw ball

    pg.fill(255);
    pg.ellipse(ballX, ballY, BALL_DIA, BALL_DIA);

    // Reset buttons state

    releasedButtons = 0;
  }

  // Detects a collision between the given coordinates and the paddle
  private boolean collision(float x, float y) {
    float dx = x - centerX;
    float dy = y - centerY;
    float ballRadius = (float) WiimoteMath.mag(dx, dy);
    if (ballRadius + BALL_RADIUS >= arenaRadius - HALF_PADDLE_STROKE_WIDTH) {
      float ballAngle = atan2(dy, dx);
      // Make the comparison have the same range
      if (ballAngle < 0) ballAngle += TWO_PI;
      float angleDiff = ballAngle - rollAngle;

      if (angleDiff < -PI) {
        angleDiff += TWO_PI;
      } else if (angleDiff > PI) {
        angleDiff -= TWO_PI;
      }

      if (abs(angleDiff) <= HALF_PADDLE_SPAN) {
        return true;
      } else {
        state = LOST_BALL;
      }
    }

    return false;
  }

  // Checks whether the given coordinates are outside the bottle
  private boolean outOfBounds(float x, float y) {
    if (x < 0 || width <= x) {
      return true;
    }
    if (y < 0 || height <= y) {
      return true;
    }

    int offset = (int)y * width + (int)x;
    return offset < 0 || p.bottleBounds.length <= offset || p.bottleBounds[offset];
  }
}
