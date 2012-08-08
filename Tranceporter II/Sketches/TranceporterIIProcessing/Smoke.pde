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
  
  final int startBlockWidth = 10;
  int startPosition;
  
  
  String getName() { return "Smoke"; }
  
  Smoke(Pixels p, Settings s) {
    super(p, s);
  }

  void setup()
  {
    scaledWidth = width * 2 ;
    scaledHeight = height * 2;
    
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
        v[i][u] = new vsquare((int)(i*res),(int)(u*res));
        vbuf[i][u] = new vbuffer((int)(i*res),(int)(u*res));
      }
    }
  }

  float newParticleX()
  {
    return random(startPosition-startBlockWidth,startPosition+startBlockWidth);
  }

  float newParticleY()
  {
    return random(scaledHeight-startBlockWidth/2,scaledHeight);
  }

  
  void draw()
  {
    pg.scale(0.5);
    if (false) {
      pg.translate(-20,32);
      pg.scale(0.5);
      pg.rotate(PI * 1.65);
    }
    int axvel = mouseX-pmouseX;
    int ayvel = mouseY-pmouseY;
    
    mouseXvel = (axvel != mouseXvel) ? axvel : 0;
    mouseYvel = (ayvel != mouseYvel) ? ayvel : 0;
    
    if(randomGust <= 0) {
      if(settings.isBeat(2) && random(0,10)<1) {
        randomGustMax = (int)random(5,12);
        randomGust = randomGustMax;
        randomGustX = random(0,scaledWidth);
        randomGustY = random(0,scaledHeight-10);
        randomGustSize = random(0,50);
        if(randomGustX > scaledWidth/2) {
          randomGustXvel = random(-8,0);
        } else {
          randomGustXvel = random(0,8);
        }
        randomGustYvel = random(-2,1);
      }
      randomGust--;
    }
    
    for(int i = 0; i < lwidth; i++) {
      for(int u = 0; u < lheight; u++) {
        vbuf[i][u].updatebuf(i,u);
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
    randomGust = 0;
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

    xvel = random(-1,1);
    yvel = random(-1,1);
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

      
      
      x += xvel;
      y += yvel;
    } 
    else {
      reposition();
    }
    if(random(0,400) < 1) {
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

  vbuffer(int xIn,int yIn) {
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

  vsquare(int xIn,int yIn) {
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
//    color c4 = color(aRed,aGreen,aBlue);
//    color c5 = blendColor(c4,c3,OVERLAY);
//    pg.fill(c5);
    
    float percent = (255 - tcol)/255.0;
    color c = 0;
    if (percent > 0.5) {
      c = getColor(int(percent/2.0*(getNumColors()-1)));
    } else {
      c = getColor(0);
    }

    pg.fill(c);
    
    pg.rect(x,y,res,res);
    col = 0;
  }
}
}
