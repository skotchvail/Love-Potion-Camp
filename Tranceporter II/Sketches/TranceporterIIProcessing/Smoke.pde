/**
 * Based on Smoke by Glen Murphy.
 * 
 * Drag the mouse across the image to move the particles.
 * Code has not been optimised and will run fairly slowly.
 */
 

class Smoke extends Drawer {
 
  float res = 1;
  int lwidth;
  int lheight;

  int penSize = 30;
  int pnum = 30000;
  vsquare[][] v;
  vbuffer[][] vbuf;
  particle[] p;
  ArrayList<Gust> gusts = new ArrayList<Gust>();
  int pcount = 0;
  int mouseXvel = 0;
  int mouseYvel = 0;
  
  float scaledWidth;
  float scaledHeight;

  int randomGust = 0;
  int randomGustMax;
  float randomGustX;
  float randomGustY;
  float randomGustSize;
  float randomGustXvel;
  float randomGustYvel;
  float speedFactor;
  float SCALE = 0.5;
  
  final int startBlockWidth = 20;
  int startPosition;
  
  
  String getName() { return "Smoke"; }
  
  String getCustom1Label() { return "Dot Brightness";}

  
  Smoke(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.MirrorSides);
  }

  void setup()
  {
    scaledWidth = width / SCALE ;
    scaledHeight = height / SCALE;
    
    lwidth = (int)(scaledWidth/res);
    lheight = (int)(scaledHeight/res);
    
    v = new vsquare[lwidth+1][lheight+1];
    vbuf = new vbuffer[lwidth+1][lheight+1];
    p = new particle[pnum];
    pg.beginDraw();
    pg.noStroke();
    pg.endDraw();
    
    startPosition = (int)(scaledWidth - startBlockWidth);
    for(int i = 0; i < pnum; i++) {
      p[i] = new particle(newParticleX(), newParticleY());
    }
    for(int i = 0; i <= lwidth; i++) {
      for(int u = 0; u <= lheight; u++) {
        v[i][u] = new vsquare((int)(i*res), (int)(u*res));
        vbuf[i][u] = new vbuffer((int)(i*res), (int)(u*res));
      }
    }
    
    settings.setParam(settings.keyBeatLength, 0.05);
    settings.setParam(settings.keyAudioSensitivity1, 0.5);
    settings.setParam(settings.keyAudioSensitivity2, 0.5);
    settings.setParam(settings.keyAudioSensitivity3, 0.5);
    settings.setParam(settings.keyFlash, 0.0);
  }

  float newParticleX()
  {
    return random(startPosition-startBlockWidth, startPosition+startBlockWidth);
  }

  float newParticleY()
  {
    return random(scaledHeight-startBlockWidth/2, scaledHeight) - startBlockWidth * 0.25;
  }

  
  void draw()
  {
    speedFactor = 1.4 * settings.getParam(settings.keySpeed);
    speedFactor *= speedFactor;
    speedFactor += 0.1;
    
    colorMode(RGB, 255);
    pg.colorMode(RGB, 255);
    pg.scale(SCALE);
    pg.background(0);
    int axvel = mouseX-pmouseX;
    int ayvel = mouseY-pmouseY;
    
    mouseXvel = (axvel != mouseXvel) ? axvel : 0;
    mouseYvel = (ayvel != mouseYvel) ? ayvel : 0;
    
    if(randomGust <= 0) {

      boolean beat0 = settings.isBeat(0) && settings.beatPosSimple(0) == 0;
      boolean beat1 = settings.isBeat(1) && settings.beatPosSimple(1) == 0;
      boolean beat2 = settings.isBeat(2) && settings.beatPosSimple(2) == 0;
      
      if(beat0 || beat1 || beat2) {
        randomGustMax = (int)random(5, 12);
        randomGust = randomGustMax;
        
        color theColor;
        randomGustX = random(0, scaledWidth);
        randomGustY = randomYForBottle(randomGustX, SCALE);
        if (beat0) {
          theColor = getColor(1);
        }
        else if (beat1) {
          theColor = getColor((int)(getNumColors() * 0.5));
        }
        else {
          theColor = getColor((int)(getNumColors() * 0.9));
        }
        Gust g = new Gust(new PVector(randomGustX, randomGustY), theColor);
        gusts.add(g);
        
        randomGustSize = 25;
        
        randomGustXvel = -scaledWidth/100.0;
        randomGustYvel = -scaledWidth/100.0;
      }
      randomGust--;
    }
    
    for(int i = 0; i < lwidth; i++) {
      for(int u = 0; u < lheight; u++) {
        vbuf[i][u].updatebuf(i, u);
        v[i][u].col = 0;
      }
    }
    for(int i = 0; i < pnum-1; i++) {
      p[i].updatepos();
    }
    for(int i = 0; i < lwidth; i++) {
      for(int u = 0; u < lheight; u++) {
        v[i][u].addbuffer(i, u);
        v[i][u].updatevels(mouseXvel, mouseYvel);
        v[i][u].display(i, u);
      }
    }

    //draw the gusts
    pg.pushStyle();
    pg.smooth();
    pg.ellipseMode(CENTER);
    
    ArrayList<Gust> newList = new ArrayList<Gust>();
    
    for (Gust g : gusts) {
      g.draw();
      if (g.drawsLeft > 0) {
        newList.add(g);
      }
    }
    gusts = newList;
    pg.popStyle();

    randomGust = 0;
  }

class Gust
{
  PVector location;
  color fillColor;
  int drawsLeft;
  int MAX_FRAMES = int(FRAME_RATE * 0.5);
  
  Gust(PVector location, color fillColor) {
    this.fillColor = fillColor;
    this.location = location;
    drawsLeft = MAX_FRAMES;
  }
  
  void draw() {
    drawsLeft--;
    color c = this.fillColor;
    float intensity = 1 - settings.getParam(settings.keyCustom1);
    intensity *= intensity;
    intensity = 255 * (1 - intensity);
    intensity *= drawsLeft * 1.5 / MAX_FRAMES;
    intensity = min(intensity, 255);
    c = replaceAlpha(c, intensity);
    pg.fill(c);
    pg.ellipse(location.x, location.y, 20, 20);
  }
}
  
class particle 
{
  float x;
  float y;
  float xvel;
  float yvel;

  particle(float xIn, float yIn) {
    x = xIn;
    y = yIn;
  }

  void reposition() {
    x = newParticleX();
    y = newParticleY();

    xvel = random(-1, 1);
    yvel = random(-1, 1);
  }

  void updatepos() {
    int vi = (int)(x/res);
    int vu = (int)(y/res);

    if(vi > 0 && vi < lwidth && vu > 0 && vu < lheight) {
      v[vi][vu].addcolour(2);

      float ax = (x%res)/res;
      float ay = (y%res)/res;

      xvel += (1-ax)*v[vi][vu].xvel*0.05;
      yvel += (1-ay)*v[vi][vu].yvel*0.05;

      xvel += ax*v[vi+1][vu].xvel*0.05;
      yvel += ax*v[vi+1][vu].yvel*0.05;

      xvel += ay*v[vi][vu+1].xvel*0.05;
      yvel += ay*v[vi][vu+1].yvel*0.05;

      v[vi][vu].yvel -= (1-ay)*0.003;
      v[vi+1][vu].yvel -= ax*0.003;

      if(v[vi][vu].yvel < 0)
        v[vi][vu].yvel *= 1.00025;

      v[vi][vu].xvel -= (1-ax)*0.003;
      v[vi+1][vu].xvel -= ay*0.003;
      //
      //      if(v[vi][vu].yvel < 0)
      //        v[vi][vu].yvel *= 1.00025;

      x += xvel * speedFactor;
      y += yvel * speedFactor;
    } 
    else {
      reposition();
    }
    if(random(0, 400) < 1) {
      reposition();
    }
    xvel *= 0.6;
    yvel *= 0.6;
  }
}

class vbuffer
{
  int x;
  int y;
  float xvel;
  float yvel;
  float pressurex = 0;
  float pressurey = 0;
  float pressure = 0;

  vbuffer(int xIn, int yIn) {
    x = xIn;
    y = yIn;
    pressurex = 0;
    pressurey = 0;
  }

  void updatebuf(int i, int u) {
    if(i>0 && i<lwidth && u>0 && u<lheight) {
      pressurex = (v[i-1][u-1].xvel*0.5 + v[i-1][u].xvel + v[i-1][u+1].xvel*0.5 - v[i+1][u-1].xvel*0.5 - v[i+1][u].xvel - v[i+1][u+1].xvel*0.5);
      pressurey = (v[i-1][u-1].yvel*0.5 + v[i][u-1].yvel + v[i+1][u-1].yvel*0.5 - v[i-1][u+1].yvel*0.5 - v[i][u+1].yvel - v[i+1][u+1].yvel*0.5);
      pressure = (pressurex + pressurey)*0.25;
    }
  }
}

class vsquare {
  int x;
  int y;
  float xvel;
  float yvel;
  float col;

  vsquare(int xIn, int yIn) {
    x = xIn;
    y = yIn;
  }

  void addbuffer(int i, int u) {
    if(i>0 && i<lwidth && u>0 && u<lheight) {
      xvel += (vbuf[i-1][u-1].pressure*0.5
      +vbuf[i-1][u].pressure
      +vbuf[i-1][u+1].pressure*0.5
      -vbuf[i+1][u-1].pressure*0.5
      -vbuf[i+1][u].pressure
      -vbuf[i+1][u+1].pressure*0.5
      )*0.49;
      yvel += (vbuf[i-1][u-1].pressure*0.5
      +vbuf[i][u-1].pressure
      +vbuf[i+1][u-1].pressure*0.5
      -vbuf[i-1][u+1].pressure*0.5
      -vbuf[i][u+1].pressure
      -vbuf[i+1][u+1].pressure*0.5
      )*0.49;
    }
  }

  void updatevels(int mvelX, int mvelY) {
    float adj;
    float opp;
    float dist;
    float mod;

    if(mousePressed) {
      adj = x - mouseX;
      opp = y - mouseY;
      dist = sqrt(opp*opp + adj*adj);
      if(dist < penSize) {
        if(dist < 4) dist = penSize;
        mod = penSize/dist;
        xvel += mvelX*mod;
        yvel += mvelY*mod;
      }
    }
    if(randomGust > 0) {
      adj = x - randomGustX;
      opp = y - randomGustY;
      dist = sqrt(opp*opp + adj*adj);
      if(dist < randomGustSize) {
        if(dist < res*2) dist = randomGustSize;
        mod = randomGustSize/dist;
        xvel += (randomGustMax-randomGust)*randomGustXvel*mod;
        yvel += (randomGustMax-randomGust)*randomGustYvel*mod;
      }
    }
    xvel *= 0.99;
    yvel *= 0.98;
  }

  void addcolour(int amt) {
    col += amt;
    if(col > 196) col = 196;
  }

  void display(int i, int u) {
    float tcol = 0;
    
    if(i>0 && i<lwidth-1 && u>0 && u<lheight-1) {

      tcol = (+ v[i][u+1].col
      + v[i+1][u].col
      + v[i+1][u+1].col*0.5
      )*0.3;
      tcol = (int)(tcol+col*0.5);
    }

////    getColor(settings.beatPosSimple*getNumColors());
//    
//    float a1 = 1.0*i/lwidth;
//    float a2 = 1.0*u/lheight;
//    float a3 = settings.beatPosSimple(1);
//    float a4 = settings.beatPosSimple(2);
//    float a5 = tcol/255;
//    color c1 = #ffb020;
//    color c2 = #312207;
//    
//    color c3 = color(255-tcol);
////    c1= getColor(0);
////    c2 = getColor(getNumColors()/2);
//    float aRed = red(c1) + (red(c2) - red(c1)) * a2 * a3;
//    float aGreen = green(c1) + (green(c2) - green(c1)) * a1 * a2;
//    float aBlue = blue(c1) + (blue(c2) - blue(c1)) * (1-a1) * (1-a4);
//    
//    color c4 = color(aRed, aGreen, aBlue);
//    color c5 = blendColor(c4, c3, OVERLAY);
//    pg.fill(c5);
    
//    float percent = (255 - tcol)/255.0;
//    color c = 0;
//    if (percent > 0.5) {
//      c = getColor(int(percent/2.0*(getNumColors()-1)));
//    } else {
//      c = getColor(0);
//    }
    
    color c = color(tcol * 1.5);
    if (tcol == 0) {
      c = color(0);
    }
    else {
      c = replaceAlpha(#40FF40, tcol * 1.9);
    }

    pg.fill(c);
    
    pg.rect(x, y, res, res);
    col = 0;
  }
}
}
