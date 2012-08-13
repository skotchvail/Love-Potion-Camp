/**
 Based on  "Multiple Particle Systems" by Daniel Shiffman.
 */


class DroppingParticles extends Drawer {

  ArrayList psystems;
  float scale = 0.5;
  
  DroppingParticles(Pixels p, Settings s) {
    super(p, s, JAVA2D);
  }
  
  
  String getName() { return "Dropping Particles"; }
  String getCustom1Label() { return "# Particles";}
  String getCustom2Label() { return "Colors";}
  
  void setup() {
//    size(640, 360);
    colorMode(RGB, 255, 255, 255, 100);
    pg.colorMode(RGB, 255, 255, 255, 100);

    psystems = new ArrayList();
    settings.setParam(settings.keyBeatLength,0.05);
    settings.setParam(settings.keyAudioSensitivity1,0.03);
    settings.setParam(settings.keyAudioSensitivity2,0.03);
    settings.setParam(settings.keyAudioSensitivity3,0.03);
  }
  
  void draw() {
    
    colorMode(RGB, 255, 255, 255, 100);
    pg.smooth();
    pg.colorMode(RGB, 255, 255, 255, 100);
    pg.background(0);
    
    pg.scale(scale);

    float numParticlesScale = settings.getParam(settings.keyCustom1);
    
    float lower = 2.23 * numParticlesScale; //sqrt 5
    lower *= lower;
    lower += 1;
    float upper = 17.32 * numParticlesScale; //sqrt 300
    upper *= upper;
    upper +=2;
    
    if (settings.isBeat(0)) {
      psystems.add(new ParticleSystem(int(random((int)lower,(int)upper)),new PVector(30,10)));
    }
    if (settings.isBeat(1)) {
      psystems.add(new ParticleSystem(int(random((int)lower,(int)upper)),new PVector(45,20)));
    }
    if (settings.isBeat(2)) {
      psystems.add(new ParticleSystem(int(random((int)lower,(int)upper)),new PVector(90,40)));
    }
  
    // Cycle through all particle systems, run them and delete old ones
    for (int i = psystems.size()-1; i >= 0; i--) {
      ParticleSystem psys = (ParticleSystem) psystems.get(i);
      psys.run();
      if (psys.dead()) {
        psystems.remove(i);
      }
    }
    
  }
  
  void reset() {
    // Cycle through all particle systems, run them and delete old ones
    for (int i = psystems.size()-1; i >= 0; i--) {
      ParticleSystem psys = (ParticleSystem) psystems.get(i);
      psystems.remove(i);
    }
  }
   
  
  // A simple Particle class
  
  class Particle {
    PVector loc;
    PVector vel;
    PVector acc;
    float r;
    float timer;
    color strokeColor;
    
    // One constructor
    Particle(PVector a, PVector v, PVector l, float r_) {
      acc = a.get();
      vel = v.get();
      loc = l.get();
      r = r_;
      timer = 100.0;
      strokeColor = pickColor();
    }
    
    // Another constructor (the one we are using here)
    Particle(PVector l) {
      acc = new PVector(0,0.05,0);
      vel = new PVector(random(-1,1),random(-2,0),0);
      loc = l.get();
      r = 10.0;
      timer = 100.0;
      strokeColor = pickColor();
    }
    
    
    void run() {
      update();
      render();
    }
    
    // Method to update location
    void update() {
      
      float speed = settings.getParam(settings.keySpeed);
      speed += 0.2;
      speed *= 2.5;
      speed *= speed;
      vel.add(PVector.mult(acc,speed));
      loc.add(vel);
      timer -= 1.0;
    }
    
    // Method to display
    void render() {
      pg.ellipseMode(CENTER);
      pg.stroke(replaceAlpha(strokeColor,timer));
      pg.fill(100,timer);
      pg.ellipse(loc.x,loc.y,r,r);
    }
    
    // Is the particle still useful?
    boolean dead() {
      if (timer <= 0.0) {
        return true;
      } else {
        return false;
      }
    }

    color pickColor() {
      float colorSetting = settings.getParam(settings.keyCustom2);
      if (colorSetting == 0) {
        return color(255);
      }
      
      float location = map(loc.x,0,width/scale,0,1);
      float colorRange = colorSetting * getNumColors();
      
      return getColor((int)round(location * colorRange));
    }
    
  }
  
 
  
// A subclass of Particle
  
  class CrazyParticle extends Particle {
    
    // Just adding one new variable to a CrazyParticle
    // It inherits all other fields from "Particle", and we don't have to retype them!
    float theta;
    
    // The CrazyParticle constructor can call the parent class (super class) constructor
    CrazyParticle(PVector l) {
      // "super" means do everything from the constructor in Particle
      super(l);
      // One more line of code to deal with the new variable, theta
      theta = 0.0;
      
    }
    
    // Notice we don't have the method run() here; it is inherited from Particle
    
    // This update() method overrides the parent class update() method
    void update() {
      super.update();
      // Increment rotation based on horizontal velocity
      float theta_vel = (vel.x * vel.mag()) / 10.0f;
      theta += theta_vel;
    }
    
    // Override timer
    void timer() {
      timer -= 0.5;
    }
    
    // Method to display
    void render() {
      // Render the ellipse just like in a regular particle
      super.render();
      
      // Then add a rotating line
      pg.pushMatrix();
      pg.translate(loc.x,loc.y);
      pg.rotate(theta);
      pg.stroke(replaceAlpha(strokeColor,timer));
      pg.line(0,0,25,0);
      pg.popMatrix();
    }
  }
  
  // An ArrayList is used to manage the list of Particles
  
  class ParticleSystem {
    
    ArrayList particles;    // An arraylist for all the particles
    PVector origin;        // An origin point for where particles are birthed
    
    ParticleSystem(int num, PVector v) {
      particles = new ArrayList();              // Initialize the arraylist
      origin = v.get();                        // Store the origin point
      for (int i = 0; i < num; i++) {
        // We have a 50% chance of adding each kind of particle
        if (random(1) < 0.5) {
          particles.add(new CrazyParticle(origin));
        } else {
          particles.add(new Particle(origin));
        }
      }
    }
    
    void run() {
      // Cycle through the ArrayList backwards b/c we are deleting
      for (int i = particles.size()-1; i >= 0; i--) {
        Particle p = (Particle) particles.get(i);
        p.run();
        if (p.dead()) {
          particles.remove(i);
        }
      }
    }
    
    void addParticle() {
      particles.add(new Particle(origin));
    }
    
    void addParticle(Particle p) {
      particles.add(p);
    }
    
    // A method to test if the particle system still has particles
    boolean dead() {
      if (particles.isEmpty()) {
        return true;
      }
      else {
        return false;
      }
    }
    
  }
  
  
}






