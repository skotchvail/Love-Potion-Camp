// Visualzation of boucing balls in 2D
// Custom1: # of balls

import toxi.geom.Vec2D;

class BouncingBalls2D extends Drawer {
  ArrayList<ball> balls = new ArrayList();
  float maxRadius = 2.1, minRadius = 1.1;
  float startMomentum = 0.5;
  float maxMass = maxRadius*maxRadius;
  float kMaxGravity = 0.025;
  float kStickiness = 0.000;
  float kFriction   = 0.000;
  float kColorAlpha = 1.0;
  float minHue = 0.0;
  float maxHue = 1.0;
  float baseRadius = 1.3;
  Vec2D gravity;
  int beatAssign;
  PImage imageLove;
  boolean isSlosh;
  float logoY;
  PFont font;
  boolean useImageLogo;

  BouncingBalls2D(Pixels p, Settings s, boolean isSlosh) {
    super(p, s, P2D, DrawType.TwoSides);
    this.isSlosh = isSlosh;
  }

  String getName() {
    if (isSlosh) {
      return "Slosh";
    }
    else {
      return "BouncingBalls2D";
    }
  }
  String getCustom1Label() { return "# Balls";}
  String getCustom2Label() {
    if (isSlosh) {
      return "Acceleration";
    }
    else {
      return "Size";
    }
  }

  void setup() {

    float numBallsSlider = 0.3;

    if (isSlosh) {
      numBallsSlider = 0.9;
      maxRadius = 2.1;
      minRadius = 2.1;
      kMaxGravity = 0.20;
      kStickiness = 0.002;
      kFriction   = 0.035;
      kColorAlpha = 0.4;
      minHue = 0.53;
      maxHue = 0.76;
      baseRadius = 2.0;

      font = loadFont("RomanSD-16.vlw");
      
      imageLove = loadImage("Logo Love Potion.png");
      imageLove.resize(round(imageLove.width * 0.08), 0);
    }

    gravity = new Vec2D(0, kMaxGravity);

    colorMode(HSB, 1.0);
    pg.colorMode(HSB, 1.0);
    pg.smooth();
    settings.setParam(settings.keyCustom1, numBallsSlider);
    reset();
  }

  void reset() {
    settings.setParam(settings.keyCustom2, 0.5); // start acceleration off at 50%
    balls.clear();
    for(int i=0; i<balls.size();i++) {
      addBall();
    }
    logoY = height * 0.52;
  }

  // true if pos is outside of bottle
  boolean outOfBounds(Vec2D pos) {
    if (pos.x < 0 || pos.x >= ledWidth / 2) {
      return true;
    }
    if (pos.y < 0 || pos.y >= height) {
      return true;
    }
    
    int offset = ((int)pos.y * ledWidth + (int)pos.x);
    return (offset >= p.bottleBounds.length || offset < 0 || p.bottleBounds[offset]);
  }

  void addBall() {
    float radius = random(minRadius, maxRadius);
    float mass = radius*radius;
    color col = color(mass/maxMass, 0.5, 1.0, kColorAlpha);
    Vec2D pos;
    while (true) {
      pos = new Vec2D(random(0, ledWidth / 2 - 1), random(0, ledHeight / 3));
      if (!outOfBounds(pos)) {
        break;
      }
    }
    Vec2D dpos = new Vec2D(random(-1, 1), random(-1, 1));
    dpos = dpos.normalizeTo(startMomentum/mass);
    balls.add(new ball(pos, dpos, radius, col, mass));
  }

  private Float lastAccel;
  void draw() {
    
    if (!isSlosh) {
      baseRadius = 1.3 * settings.getParam(settings.keyCustom2) * 4 + 0.4;
    }
    
    colorMode(HSB, 1.0);
    pg.colorMode(HSB, 1.0);
    pg.smooth();

    // Accommodate other controllers changing things
    Float accel = settings.getParam(settings.keyCustom2);
    if (!isSlosh) {
      accel = 0.5;
    }
    if (!accel.equals(lastAccel)) {
      gravity.x = (settings.getParam(settings.keyCustom2) - 0.5) * 2.0 * kMaxGravity;
      gravity.y = sqrt(kMaxGravity * kMaxGravity - gravity.x * gravity.x);
      lastAccel = accel;
    }

    float rawNumBalls = (settings.getParam(settings.keyCustom1) * 20) + 1;

    rawNumBalls *= rawNumBalls;
    int numBalls = (int)rawNumBalls;

    while (numBalls < balls.size()) {
      balls.remove(balls.size()-1);
    }
    while (numBalls > balls.size()) {
      addBall();
    }

    for(ball ball: balls) {
      ball.update(gravity);
    }
    for (int i=0; i<balls.size(); i++) {
      ball ball = balls.get(i);
      if (outOfBounds(ball.pos)) {
        continue;
      }
      for (int j=i+1; j<balls.size(); j++) {
        ball.checkForCollision(balls.get(j));
      }
    }

    pg.background(0);

    if (isSlosh) {

      final float kLevel1 = 0.05;
      final float kLevel2 = 0.10;
      final float kLevel3 = 0.25;
      final float kLevel4 = 0.29;
      float speed = settings.getParam(settings.keySpeed);

      if (speed > kLevel4) {
        float deltaY = map(speed * speed, kLevel4 * kLevel4, 1, 0, 2.5);
        logoY -= deltaY;
        float textHeight = 10;
        if (useImageLogo) {
          textHeight = imageLove.height;
        }
        if (logoY < -textHeight) {
          useImageLogo = !useImageLogo;
          logoY = height + textHeight / 2;
        }
      }

      if (speed > kLevel2) {
        if (useImageLogo) {
          float x = 58 - imageLove.width/2;
          // pg.image doesn't draw on fractional boundaries, so I am using textures instead
          // to get smooth movement
          // pg.image(imageLove, x, y);
          
          pg.tint(1.0, map(speed, kLevel2, kLevel3, 0, 1));
          
          pg.beginShape();
          pg.texture(imageLove);
          pg.vertex(x, logoY, 0, 0);
          pg.vertex(x + imageLove.width, logoY, imageLove.width, 0);
          pg.vertex(x + imageLove.width, logoY + imageLove.height, imageLove.width, imageLove.height);
          pg.vertex(x, logoY + imageLove.height, 0, imageLove.height);
          pg.endShape();
          
          x += ledWidth / 2;
          pg.beginShape();
          pg.texture(imageLove);
          pg.vertex(x, logoY, 0, 0);
          pg.vertex(x + imageLove.width, logoY, imageLove.width, 0);
          pg.vertex(x + imageLove.width, logoY + imageLove.height, imageLove.width, imageLove.height);
          pg.vertex(x, logoY + imageLove.height, 0, imageLove.height);
          pg.endShape();
          
          pg.noTint();
        }
        else {
          pg.fill(WHITE);
          pg.textFont(font);
          float fontSize = font.getSize();
          pg.textSize(fontSize);
          pg.textLeading((font.ascent() + font.descent()) * fontSize + 2);
          pg.textAlign(CENTER, CENTER);
          String displayText = "Love\nPotion";
          pg.text(displayText, 60, logoY);
          pg.text(displayText, 160, logoY);
        }
      }

    }

    if (false) {
      // For debugging, show the bottle bounds
      pg.stroke(255);
      pg.fill(0, 1.0, 1.0);
      for (int y = 0; y < ledHeight; y++) {
        for (int x = 0; x < ledWidth; x++) {
          if (p.bottleBounds[y * ledWidth + x]) {
            pg.set(x, y, WHITE);
          }
        }
      }
    }

    pg.noStroke();
    for (int i = 0; i < balls.size(); i++) {
      balls.get(i).draw(pg);
    }
  }

  class ball {
    Vec2D pos, dpos, oldPos;
    color col;
    float radius, mass, startMomentum;
    int whichBeat;

    ball(Vec2D pos, Vec2D dpos, float radius, color col, float mass) {
      this.pos = pos;
      this.dpos = dpos;
      this.radius = radius;
      this.mass = mass;
      this.col = col;
      this.startMomentum = getMomentum();
      updateColor();
      beatAssign++;
      whichBeat = beatAssign % 3;
    }

    void updateColor() {
      colorMode(HSB, 1.0);

      float newHue = hue(this.col) - minHue;
      newHue = (newHue + settings.getParam(settings.keyColorCyclingSpeed) * 0.005) % (maxHue - minHue);
      newHue += minHue;
      this.col = color(newHue, 1.0, 1.0, kColorAlpha);
    }

    float getMomentum() {
      return mass * dpos.magnitude();
    }

    boolean aboveLine(Vec2D p1, Vec2D p2, Vec2D point) {
      Vec2D v1 = p1.sub(p2);
      Vec2D v2 = p2.sub(point);
      float result = v1.cross(v2);
      return result < 0;
    }
    
    Vec2D normalOffBoundary(Vec2D pos) {
      Vec2D center = new Vec2D(60, 25);

      
      if (pos.x > 89 && pos.y > 29) {
        Vec2D topLeftCorner = new Vec2D(89, 45);
        Vec2D bottomRightCorner = new Vec2D(ledHeight, ledWidth / 2);
        center.set(-1000, 40);
        if (pos.x > topLeftCorner.x && pos.y > topLeftCorner.y) {
          if (aboveLine(topLeftCorner, bottomRightCorner, pos)) {
            center.set(98, -1000);
          }
        }
      }
      else if (pos.x < 20) {
        center.set(33, 22);
        if (pos.y > 30) {
          center.set(12, -1000);
        }
      }

      Vec2D vector = center.sub(pos).getNormalized();
      return vector;
    }

    void update(Vec2D gravity) {
      oldPos = pos.copy(); // TODO: consider getting rid of oldPos
      dpos.scaleSelf(1.0 - kFriction);
      dpos.addSelf(gravity.scale(0.5));

      // If we hit a boundary, we need to bounce off
      if (outOfBounds(pos)) {
        // Figure out the normal vector that the ball should bounce of off
        Vec2D vector = normalOffBoundary(pos);
        float delta = dpos.magnitude();
        dpos.x = delta * vector.x;
        dpos.y = delta * vector.y;

        // Move towards getting out of the boundary, so we don't get stuck there
        for (int count = 0; count < 10; count++) {
          pos.addSelf(vector.scale(0.2));
          if (!outOfBounds(pos)) {
            break;
          }
        }
      }

      dpos.addSelf(gravity.scale(0.5));
      pos.addSelf(dpos);
    }

    void checkForCollision(ball b) {
      Vec2D diffPos = this.pos.sub(b.pos);
      float properDistance = this.radius + b.radius;
      float actualDistance = diffPos.magnitude();
      if (actualDistance < properDistance) {
        //println("collision");
        Vec2D norml = diffPos.getNormalized();
        float aci = this.dpos.dot(norml);
        float bci = b.dpos.dot(norml);
        float ma = this.mass;
        float mb = b.mass;

        float acf = (aci*(ma-mb) + 2*mb*bci) / (ma + mb);
        float bcf = (bci*(mb-ma) + 2*ma*aci) / (ma + mb);

        this.dpos.addSelf(norml.scale(acf-aci));
        b.dpos.addSelf(norml.scale(bcf-bci));

        this.dpos.scaleSelf(1.0 - kStickiness);
        b.dpos.scaleSelf(1.0 - kStickiness);

        // Don't let two balls take up the same space
        float d = actualDistance - properDistance;
        this.pos.addSelf(diffPos.scale(-d * 0.1));
        b.pos.addSelf(diffPos.scale(d * 0.1));

        // change color
        updateColor();
        b.updateColor();
      }
    }

    void draw(PGraphics pg) {
      pg.fill(col);
      pg.ellipseMode(CENTER);
      float beatRadius = radius * (baseRadius + (settings.isBeat(whichBeat)?1.0:0.0));
      pg.ellipse(pos.x, pos.y, beatRadius, beatRadius); // port side
      pg.ellipse(ledWidth - pos.x, pos.y, beatRadius, beatRadius); // startboard side
    }
  }
}
