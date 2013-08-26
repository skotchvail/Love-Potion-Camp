import java.lang.Override;

import com.qindesign.wii.Wiimote;
import com.qindesign.wii.WiimoteMath;

class CircularPong extends Drawer {
  private static final float HALF_PADDLE_SPAN = PI / 12;
  private static final float PADDLE_STROKE_WIDTH = 3;
  private static final float HALF_PADDLE_STROKE_WIDTH = PADDLE_STROKE_WIDTH / 2;
  private static final float BALL_DIA = 2;
  private static final float BALL_RADIUS = BALL_DIA / 2;
  private static final float TIME_TO_CROSS_ARENA_RADIUS = 2;

  private static final float TIME_FOR_ONE_ROTATION_IN_DEMO = 2.5;

  private final float centerX = width * 0.5;
  private final float centerY = height * 0.55;
  private final float arenaDiameter = min(width, height) * 0.65;
  private final float arenaRadius = arenaDiameter / 2;
  private final float halfCollisionSpan = HALF_PADDLE_SPAN + BALL_DIA/arenaRadius;

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

  // Demo mode

  private boolean demoMode;

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
  }

  @Override
  void setup() {
    demoMode = true;
  }

  @Override
  void justEnteredSketch() {
    reset();
    this.myFrameRate = round(frameRate);
    System.out.println("myFrameRate = " + myFrameRate);

    buttons = 0;
    releasedButtons = 0;

    demoMode = true;
  }

  @Override
  void wiimoteConnected(String path) {
    demoMode = false;
  }

  @Override
  void wiimoteDisconnected(String path) {
    demoMode = true;
  }

  /**
   * Resets everything.  This sets the state to START.
   */
  @Override
  void reset() {
    ballX = centerX;
    ballY = centerY;
    ballSpeedX = 0;
    ballSpeedY = 0;

    rollAngle = HALF_PI;
    countdownToBallStart = 0;

    state = START;
  }

  /**
   * Starts the ball moving.  This sets the state to PLAYING.
   */
  private void start() {
    float speed = arenaRadius / TIME_TO_CROSS_ARENA_RADIUS / myFrameRate;

    float angle = random(TWO_PI);
    ballSpeedX = cos(angle) * speed;
    ballSpeedY = sin(angle) * speed;

    state = PLAYING;
  }

  private int countdownToBallStart;

  @Override
  void draw() {
    boolean startBall = false;
    float targetRollAngle = calculateTargetRollAngle();

    if (demoMode) {
      // Demo mode

      if (targetRollAngle == targetRollAngle) {
        float angleDiff = angleDiff(targetRollAngle, rollAngle);
        float deltaAngle = Math.signum(angleDiff) * TWO_PI / TIME_FOR_ONE_ROTATION_IN_DEMO / myFrameRate;
        float newRollAngle = rollAngle + deltaAngle;
        if (abs(angleDiff(targetRollAngle, newRollAngle)) > HALF_PADDLE_SPAN) {
          rollAngle = newRollAngle;
          rollAngle += randomGaussian()*BALL_DIA/1.5/arenaRadius;
        } else {
          rollAngle = targetRollAngle;
          rollAngle += randomGaussian()*BALL_RADIUS/3/arenaRadius;
        }

        // Add some noise

      } else {
        // The ball is still

        if (countdownToBallStart <= 0) {
          countdownToBallStart = round(random(myFrameRate));
        } else {
          countdownToBallStart--;
        }
        startBall = (countdownToBallStart == 0);
      }
    } else {
      // Wii mode

      startBall = (releasedButtons & Wiimote.BUTTON_B) != 0;
      releasedButtons = 0;
    }

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
        if (startBall) {
          start();
        }
        break;
      case PLAYING:
        ballX += ballSpeedX;
        ballY += ballSpeedY;

        if (outOfBounds(ballX, ballY)) {
          reset();
        } else {
          // The ball is still in bounds

          if (reachedEdge(ballX, ballY)) {
            float ballAngle = atan2(ballY - centerY, ballX - centerX);
            float angleDiff = angleDiff(ballAngle, rollAngle);
            if (abs(angleDiff) <= halfCollisionSpan) {
              float theta = atan2(ballSpeedY, ballSpeedX);
              float phi = rollAngle - angleDiff;
              float newTheta = PI - theta + 2*phi;

              ballSpeedX = cos(newTheta);
              ballSpeedY = sin(newTheta);
            } else {
              state = LOST_BALL;
            }
          }
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

//    pg.stroke(255, 255, 0);
//    pg.fill(255, 255, 0);
//    pg.ellipse(arenaRadius*cos(targetRollAngle) + centerX, arenaRadius*sin(targetRollAngle) + centerY, BALL_DIA, BALL_DIA);
  }

  /**
   * Calculates the target roll angle given the location and speed of the ball.  If it cannot
   * be determined then this will return NaN.
   *
   * @return the target roll angle for the demo paddle, or NaN if it could not be determined.
   */
  private float calculateTargetRollAngle() {
    // Move towards the ball, but with random perturbations

    // Line intersecting with a circle:
    // Line: 'e' is ball location, 'd' is velocity
    // x = e_x + t*d_x
    // y = e_y + t*d_y
    // Circle:
    // x^2 + y^2 - r^2 = 0
    //
    // Plug in and solve for quadratic equation for 't':
    // a = d_x^2 + d_y^2
    // b = 2*(e_x*d_x + e_y*d_y)
    // c = e_x^2 + e_y^2 - r^2

    // See: http://stackoverflow.com/questions/1073336/circle-line-collision-detection

    float ex = ballX - centerX;
    float ey = ballY - centerY;
    float dx = ballSpeedX;
    float dy = ballSpeedY;

    float a = dx*dx + dy*dy;
    if (a == 0) {
      return Float.NaN;
    }

    float b = 2*(ex*dx + ey*dy);
    float c = ex*ex + ey*ey - arenaRadius*arenaRadius;

    // Discrimininant

    float discriminant = b*b - 4*a*c;
    if (discriminant >= 0) {
      discriminant = sqrt(discriminant);
      float t = (-b - discriminant)/(2*a);
      if (t < 0) {
        t = (-b + discriminant)/(2*a);
      }

      // We have a target roll angle, after solving for the intersection point

      float targetRollAngle = atan2(ey + t*dy, ex + t*dx);
      if (targetRollAngle < 0) {
        targetRollAngle += TWO_PI;
      }
      return targetRollAngle;
    } else {
      return Float.NaN;
    }
  }

  /**
   * Detects whether the ball has reached the edge of the arena.
   */
  private boolean reachedEdge(float x, float y) {
    float dx = x - centerX;
    float dy = y - centerY;
    float ballRadius = (float) WiimoteMath.mag(dx, dy);
    return ballRadius + BALL_RADIUS >= arenaRadius - HALF_PADDLE_STROKE_WIDTH;
  }

  /**
   * Calculates the difference between two angles.
   */
  // See: http://gamedev.stackexchange.com/questions/4467/comparing-angles-and-working-out-the-difference
  private float angleDiff(float a, float b) {
    // First get them in the same range

    while (a < 0) {
      a += TWO_PI;
    }
    while (b < 0) {
      b += TWO_PI;
    }
    while (a > TWO_PI) {
      a -= TWO_PI;
    }
    while (b > TWO_PI) {
      b -= TWO_PI;
    }

    // Next calculate the difference and then normalize so that the magnitude < PI

    float diff = a - b;
    if (diff < -PI) {
      diff += TWO_PI;
    } else if (diff > PI) {
      diff -= TWO_PI;
    }

    return diff;
  }

  /**
   * Detects a collision between the current ball heading and the paddle.
   * See {@link #reachedEdge(float, float)}.
   *
   * @return the angle difference between the collision point and the center of the paddle.
   */
  private float collision(float x, float y) {
    float dx = x - centerX;
    float dy = y - centerY;
    float ballAngle = atan2(dy, dx);
    return angleDiff(ballAngle, rollAngle);
  }
}
