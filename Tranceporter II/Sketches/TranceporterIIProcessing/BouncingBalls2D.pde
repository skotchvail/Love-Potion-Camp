// Visualzation of boucing balls in 2D
// Custom1: # of balls

import toxi.geom.*;
import java.text.DecimalFormat;

class BouncingBalls2D extends Drawer {
  ArrayList<ball> balls = new ArrayList();
  float maxRadius = 2.1, minRadius = 1.1;
  Vec2D bounds;
  Vec2D centerOfBox;
  float startMomentum = 0.5;
  float maxMass = maxRadius*maxRadius;
  float kMaxGravity = 0.025;
  float kStickiness = 0.000;
  float kFriction   = 0.000;
  float kColorAlpha = 1.0;
  float minHue = 0.0;
  float maxHue = 1.0;
  float baseRadius = 1.0;
  Vec2D gravity;
  int beatAssign;
  PImage imageLove;
  boolean isSlosh;
  float logoY = 10;
  
  BouncingBalls2D(Pixels p, Settings s, boolean isSlosh) {
    super(p, s, P2D, DrawType.MirrorSides);
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
  String getCustom2Label() { return "Acceleration";}

  void setup() {
    
    float numBallsSlider = 0.3;
    
    if (isSlosh) {
      numBallsSlider = 0.9;
      maxRadius = 2.1;
      minRadius = 2.1;
      kMaxGravity = 0.20;
      kStickiness = 0.002;
      kFriction   = 0.080;
      kColorAlpha = 0.4;
      minHue = 0.53;
      maxHue = 0.76;
      baseRadius = 2.0;
      
      imageLove = loadImage("Logo Love Potion.png");
      imageLove.resize(round(imageLove.width * 0.062), 0);
    }
    
    gravity = new Vec2D(0, kMaxGravity);
    
    colorMode(HSB, 1.0);
    pg.colorMode(HSB, 1.0);
    pg.smooth();
    bounds = new Vec2D(width, height);
    centerOfBox = bounds.scale(0.5);
    settings.setParam(settings.keyCustom1, numBallsSlider);
    reset();
  }
  
  void reset() {
    settings.setParam(settings.keyCustom2, 0.5); // start acceleration off at 50%
    balls.clear();
    for(int i=0; i<balls.size();i++) {
      addBall();
    }
  }
  
  void addBall() {
    float radius = random(minRadius, maxRadius);
    float mass = radius*radius;
    color col = color(mass/maxMass, 0.5, 1.0, kColorAlpha);
    
    Vec2D pos = new Vec2D(random(0, bounds.x), random(0, centerOfBox.y));
    Vec2D dpos = new Vec2D(random(-1, 1), random(-1, 1));
    dpos = dpos.normalizeTo(startMomentum/mass);
    balls.add(new ball(pos, dpos, radius, col, mass));
  }
  
  void draw() {
    
    colorMode(HSB, 1.0);
    pg.colorMode(HSB, 1.0);
    pg.smooth();
    
    gravity.x = (settings.getParam(settings.keyCustom2) - 0.5) * 2.0 * kMaxGravity;
    gravity.y = sqrt(kMaxGravity * kMaxGravity - gravity.x * gravity.x);
    
    float rawNumBalls = (settings.getParam(settings.keyCustom1) * 20) + 1;
  
    rawNumBalls *= rawNumBalls;
    int numBalls = (int)rawNumBalls;
    
    while (numBalls < balls.size()) {
      balls.remove(balls.size()-1);
    }
    while (numBalls > balls.size()) {
      addBall();
    }
    
    int numBallInBoundary = 0;
    for(ball ball: balls) {
      ball.update(gravity);
      if (ball.inBoundary) {
        numBallInBoundary++;
      }
    }
    if (false && frameCount % 30 == 0) {
      println("numBalls in boundary: " + numBallInBoundary + " out of " + balls.size());
    }
    checkForCollisions();

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
        if (logoY < -imageLove.height) {
          logoY = height + imageLove.height / 2;
        }
      }
      
      if (speed > kLevel2) {
        float x = 48 - imageLove.width/2;
        // pg.image doesn't draw on fractional boundaries, so I am using textures instead
        // to get smooth movement
        // pg.image(imageLove, x, y);
        
        pg.beginShape();
        pg.tint(1.0, map(speed, kLevel2, kLevel3, 0, 1));
        pg.texture(imageLove);
        pg.vertex(x, logoY, 0, 0);
        pg.vertex(x + imageLove.width, logoY, imageLove.width, 0);
        pg.vertex(x + imageLove.width, logoY + imageLove.height, imageLove.width, imageLove.height);
        pg.vertex(x, logoY + imageLove.height, 0, imageLove.height);
        pg.endShape();
        pg.noTint();
      }

    }
    
    if (false) {
      // For debugging, show the bottle bounds
      pg.stroke(255);
      pg.fill(0, 1.0, 1.0);
      for (int y = 0; y < ledHeight; y++) {
        for (int x = 0; x < ledWidth; x++) {
          if (p.bottleBounds[y * ledWidth + x]) {
            pg.set(x, y, color(0.7, 1.0, 1.0));
          }
        }
      }
    }
    
    pg.noStroke();    
    for (int i = 0; i < balls.size(); i++) {
      balls.get(i).draw(pg);
    }
  }
  
  void checkForCollisions() {
    for (int i=0; i<balls.size(); i++) {
      for (int j=i+1; j<balls.size(); j++) {
        balls.get(i).checkForCollision(balls.get(j));
      }
    }
  }
  
  class ball {
    Vec2D pos, dpos;
    color col;
    float radius, mass, startMomentum;
    int whichBeat;
    boolean inBoundary;
    
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
    
    void update(Vec2D gravity) {

      dpos.scaleSelf(1.0 - kFriction);
      dpos.addSelf(gravity.scale(0.5));
      int offset = ((int)pos.y * ledWidth + (int)pos.x);

      // If we hit a boundary, we need to bounce off
      inBoundary = false;
      if (offset >= p.bottleBounds.length || offset < 0 || p.bottleBounds[offset]) {
        inBoundary = true;
        
        // Figure out the normal vector that the ball should bounce of off
        Vec2D center = new Vec2D(50, 30);
        
        if (pos.x > 77 && pos.y > 31) {
          center.set(-1000, 40);
        }
        else if (pos.x > 57 && pos.y > 32) {
          center.set(65, 13);
        }
        else if (pos.x > 20 && pos.y > 32) {
          center.set(62, 7);
        }
        
        Vec2D vector = center.sub(pos).getNormalized();
        float delta = dpos.magnitude();
        dpos.x = delta * vector.x;
        dpos.y = delta * vector.y;
        
        // Move towards getting out of the boundary, so we don't get stuck there
        while (offset >= p.bottleBounds.length || offset < 0 || p.bottleBounds[offset]) {
          pos.addSelf(vector.scale(0.4));
          offset = ((int)pos.y * ledWidth + (int)pos.x);
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
      //float beatRadius = radius * 2;
      pg.ellipse(pos.x, pos.y, beatRadius, beatRadius);
    }
  }
}
