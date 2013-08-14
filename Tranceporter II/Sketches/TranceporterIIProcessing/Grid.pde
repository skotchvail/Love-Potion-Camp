
class Grid extends Drawer
{
  
  Grid(Pixels p, Settings s) {
    super(p, s, P2D, DrawType.MirrorSides);
  }

  int numRows = 18;  // The number of frames in the animation
  int frame = 0;
  PImage[] images;
  Vec2D center;
  float waveDistance;
  PImage heart;
  int displayMode;
  
  String getName()
  {
    return "Grid";
  }
  
  
  void setup()
  {
    heart = loadImage("Heart.png");
    center = new Vec2D(width / 2.0, height / 2.0);
    waveDistance = 0;

  }
  
  void drawHeart(Vec2D location, float scale)
  {
    float scaledWidth = heart.width * scale;
    float scaledHeight = heart.height * scale;
    pg.textureMode(NORMAL);
    pg.beginShape();
    pg.texture(heart);
    pg.vertex(location.x, location.y, 0, 0);
    pg.vertex(location.x + scaledWidth, location.y, 1, 0);
    pg.vertex(location.x + scaledWidth, location.y + scaledHeight, 1, 1);
    pg.vertex(location.x, location.y + scaledHeight, 0, 1);
    pg.endShape();
  }
  
  color backgroundColor = BLACK;
  void draw()
  {
    if (settings.isBeat(1)) {
      backgroundColor = getColor(0);
    }
    
    pg.background(backgroundColor);

    final int kNumRows = 10;
    final int kNumCols = 15;
    
    pg.fill(WHITE);
    pg.noStroke();
    pg.ellipseMode(CENTER);
    
    for (int i = 0; i < kNumCols; i++) {
      for (int j = 0; j < kNumRows; j++) {
        Vec2D location = new Vec2D(1.0 * width / kNumCols * i, 1.0 * height / kNumRows * j);
        float distance = location.distanceTo(center);
        float radius = 2;
        float diff = distance - waveDistance;
        
        radius += map(abs(diff), 0, 30, 3, 0);
        if (radius > 0) {
          pg.ellipse(location.x, location.y, radius, radius);
        }
      }
    }
    
    float offset1 = sin((float)frameCount / 100) * 10;
    float offset2 = cos((float)frameCount / 200) * 4;
    float offset3 = sin((float)frameCount / 30) * 12;
    float offset4 = cos((float)frameCount / 70) * 7;
    
    drawHeart(new Vec2D(30 - offset1, 2 + offset4), 0.5 + main.beatDetect.beatPos("spectralFlux", 2) * 0.1);
    drawHeart(new Vec2D(56 + offset2, 9 + offset3), 0.7 + main.beatDetect.beatPos("spectralFlux", 1) * 0.1);
    drawHeart(new Vec2D(78 - offset4, 11 + offset2), 0.3 + main.beatDetect.beatPos("spectralFlux", 0) * 0.05);
    
    if (waveDistance >= 0) {
      waveDistance += 1.9;
    }
    
    if (waveDistance > width * 0.8 && settings.isBeat(0)) {
      waveDistance = 0;
      center = new Vec2D(random(0.2, width * 0.6), random(0.2, height * 0.6));
      displayMode = (int)random(0, 3);
    }
    
//    println("waveDistance: " + waveDistance + "\n");
    
  }
  
}
