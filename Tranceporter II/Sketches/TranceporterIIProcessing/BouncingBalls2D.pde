// Visualzation of boucing balls in 2D
// Custom1: # of balls

import toxi.geom.*;
int NUM_DIMS = 2;

class BouncingBalls2D extends Drawer {
  ArrayList<ball> balls = new ArrayList();
  float maxRadius = 2, minRadius = 0.5;
  Bbox bbox;
  float startMomentum = 0.5;
  float maxMass = maxRadius*maxRadius;
  Vec2D gravity = new Vec2D(0, 0.025);
  int beatAssign;
  
  BouncingBalls2D(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.MirrorSides);
  }
  
  String getName() { return "BouncingBalls2D"; }
  String getCustom1Label() { return "# Balls";}

  void setup() {
    colorMode(HSB, 1.0);
    pg.colorMode(HSB, 1.0);
    pg.smooth();
    println("setting up bbox");
    bbox = new Bbox(new Vec2D(width, height));
    reset();
    assert(bbox != null);
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
    
    assert(bbox != null);
    Vec2D pos = new Vec2D(random(0, bbox.getDims().x), random(0, bbox.getDims().y/2));
    Vec2D dpos = new Vec2D(random(-1, 1), random(-1, 1));
    dpos = dpos.normalizeTo(startMomentum/mass);
    balls.add(new ball(bbox, pos, dpos, radius, col, mass));
    settings.setParam(settings.keyCustom1, 0.3);
  }
  
  void draw() {
    
    colorMode(HSB, 1.0);
    pg.colorMode(HSB, 1.0);
    pg.smooth();
    
    int numBalls = (int) (settings.getParam(settings.keyCustom1) * 17) + 1;
    numBalls *= numBalls;
    
    while (numBalls < balls.size()) {
      balls.remove(balls.size()-1);
    }
    while (numBalls > balls.size()) {
      addBall();
    }
    
    for(int i=0; i< balls.size();i++) {
      balls.get(i).update(gravity);
    }
    checkForCollisions();

    pg.background(0);
    pg.noStroke();    
    for (int i=0; i<balls.size(); i++) {
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
    Bbox bbox;
    color col;
    float radius, mass, startMomentum;
    int whichBeat;
    
    ball(Bbox bbox, Vec2D pos, Vec2D dpos, float radius, color col, float mass) {
      this.pos = pos;
      this.dpos = dpos;
      this.radius = radius;
      this.mass = mass;
      this.col = col;
      this.startMomentum = getMomentum();
      updateColor();
      this.bbox = bbox;
      beatAssign++;
      whichBeat = beatAssign % 3;
    }
    
    void updateColor() {
      colorMode(HSB, 1.0);
      
      float newHue = (hue(this.col) + 0.02) % 1.0;
      this.col = color(newHue, 1.0, 1.0);
    }
    
    float getMomentum() {
      return mass * dpos.magnitude();
    }
    
    void update(Vec2D gravity) {
      dpos.addSelf(gravity.scale(0.5));
      for (int i=0; i<NUM_DIMS; i++) {
        if(pos.getComponent(i) >= bbox.getDims().getComponent(i) - radius && dpos.getComponent(i) > 0) {
          dpos.setComponent(i, -abs(dpos.getComponent(i)));
          //if (i != 1) col = color((hue(col)+0.1)%1.0, 1.0, 1.0);
          //bbox.changeWallColor(i, 1);
          //pos.setComponent(i, bbox.getComponent(i)-1);
        }
        if(pos.getComponent(i) <= radius  && dpos.getComponent(i) < 0) {
          dpos.setComponent(i, abs(dpos.getComponent(i)));
          //col = color((hue(col)+0.1)%1.0, 1.0, 1.0);
          //bbox.changeWallColor(i, 0);
          //pos.setComponent(i, 0);
        }
      }
      
      dpos.addSelf(gravity.scale(0.5));
      pos.addSelf(dpos);
    }
    
    void checkForCollision(ball b) {
      Vec2D diffPos = this.pos.sub(b.pos);
      float d = diffPos.magnitude() - this.radius - b.radius;
      if (d < 0) {
        //println("collision");
        Vec2D norml = diffPos.getNormalized();
        float aci = this.dpos.dot(norml);
        float bci = b.dpos.dot(norml);
        float ma = this.mass;
        float mb = b.mass;
        
        //float acf = bci;
        float acf = (aci*(ma-mb) + 2*mb*bci) / (ma + mb);
        //float bcf = aci;
        float bcf = (bci*(mb-ma) + 2*ma*aci) / (ma + mb);
        
        this.dpos.addSelf(norml.scale(acf-aci));
        b.dpos.addSelf(norml.scale(bcf-bci));
        
        this.pos.addSelf(diffPos.scale(-d/2));
        b.pos.addSelf(diffPos.scale(d/2));
        
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
  
  class Bbox {
    Vec2D dims;
    //color[][] wallColors;
    
    Bbox(Vec2D dims) {
      colorMode(HSB, 1.0);
      
      this.dims = dims;
    }
    
    Vec2D getDims() { return dims; }
  }
}
