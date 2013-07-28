// Visualzation of boucing balls in 2D
// Custom1: # of balls

import toxi.geom.*;
import java.text.DecimalFormat;

class BouncingBalls2D extends Drawer {
  ArrayList<ball> balls = new ArrayList();
  float maxRadius = 2.1, minRadius = 0.76;
  Vec2D bounds;
  Vec2D centerOfBox;
  float startMomentum = 0.5;
  float maxMass = maxRadius*maxRadius;
  final float kMaxGravity = 0.025;
  final float kStickiness = 0.00;
  Vec2D gravity = new Vec2D(0, kMaxGravity);
  int beatAssign;
  
  BouncingBalls2D(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.MirrorSides);
  }
  
  String getName() { return "BouncingBalls2D"; }
  String getCustom1Label() { return "# Balls";}
  String getCustom2Label() { return "Acceleration";}

  void setup() {
    colorMode(HSB, 1.0);
    pg.colorMode(HSB, 1.0);
    pg.smooth();
    bounds = new Vec2D(width, height);
    centerOfBox = bounds.scale(0.5);
    settings.setParam(settings.keyCustom2, 0.5); // start acceleration off at 50%
    settings.setParam(settings.keyCustom1, 0.3);

    reset();
  }
  
  void reset() {
    balls.clear();
    for(int i=0; i<balls.size();i++) {
      addBall();
    }
  }
  
  void addBall() {
    float radius = random(minRadius, maxRadius);
    float mass = radius*radius;
    color col = color(mass/maxMass, 0.5, 1.0);
    
    Vec2D pos = new Vec2D(random(0, bounds.x), random(0, centerOfBox.y));
    Vec2D dpos = new Vec2D(random(-1, 1), random(-1, 1));
    dpos = dpos.normalizeTo(startMomentum/mass);
    balls.add(new ball(pos, dpos, radius, col, mass));
  }
  
  void draw() {
    
    colorMode(HSB, 1.0);
    pg.colorMode(HSB, 1.0);
    pg.smooth();
    
    gravity.x = (settings.getParam(settings.keyCustom2) - 0.5) * kMaxGravity;
    gravity.y = sqrt(kMaxGravity * kMaxGravity - gravity.x * gravity.x);
    
    float rawNumBalls = (settings.getParam(settings.keyCustom1) * 17) + 1;
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
//    println("numBalls in boundary: " + numBallInBoundary + " out of " + balls.size());
    checkForCollisions();

    pg.background(0);
    
    if (false) {
      // For debugging, show the bottle bounds
      pg.stroke(255);
      pg.fill(0, 1.0, 1.0);
      for (int y = 0; y < ledHeight; y++) {
        for (int x = 0; x < ledWidth; x++) {
          if (p.bottleBounds[y * ledWidth + x]) {
            pg.set(x, y, color(0.7,1.0,1.0));
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
      
      float newHue = (hue(this.col) + 0.005) % 1.0;
      this.col = color(newHue, 1.0, 1.0);
    }
    
    float getMomentum() {
      return mass * dpos.magnitude();
    }
    
    void update(Vec2D gravity) {
      dpos.addSelf(gravity.scale(0.5));
      int offset = ((int)pos.y * ledWidth + (int)pos.x);

      inBoundary = false;
      if (offset >= p.bottleBounds.length || offset < 0 || p.bottleBounds[offset]) {
        inBoundary = true;
        
        Vec2D vector = centerOfBox.sub(pos).getNormalized();
        float delta = dpos.magnitude();
        dpos.x = delta * vector.x;
        dpos.y = delta * vector.y;
        
        // Move towards getting out of the boundary, so we don't get stuck there
        pos.addSelf(vector.scale(0.1));
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
      float beatRadius = radius * (1.0 + (settings.isBeat(whichBeat)?1.0:0.0));
      //float beatRadius = radius * 2;
      pg.ellipse(pos.x, pos.y, beatRadius, beatRadius);
    }
  }
}
