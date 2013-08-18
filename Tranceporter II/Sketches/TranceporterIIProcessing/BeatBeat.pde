
class BeatBeat extends Drawer
{
  BeatBeat(Pixels p, Settings s) {
    super(p, s, P2D, DrawType.TwoSides);
  }

  Vec2D center;
  float waveDistance;
  PImage images[] = new PImage[4];
  PImage whichImage;
  int displayMode;
  PFont font;
  int halfWidth;
  
  String getName()
  {
    return "Beat Beat";
  }
  
  void setup()
  {
    halfWidth = width / 2;
    
    images[0] = loadImageWithScale("Heart.png", 1.0);
    images[1] = loadImageWithScale("Star.png", 0.6);
    images[2] = loadImageWithScale("Carrot.png", 0.4);
    images[3] = loadImageWithScale("Crossbones.png", 0.6);
    
    whichImage = images[0];
    
    center = new Vec2D(halfWidth / 2.0, height / 2.0);
    waveDistance = 0;
    
    
    // The font must be located in the sketch's
    // "data" directory to load successfully
    font = loadFont("Cochin-BoldItalic-16.vlw");
  }

  PImage loadImageWithScale(String name, float scale) {
    PImage image = loadImage(name);
    image.resize((int)(image.width * scale), 0);
    return image;
  }
  
  void drawImage(Vec2D location, float scale)
  {
    float scaledWidth = whichImage.width * scale;
    float scaledHeight = whichImage.height * scale;
    pg.textureMode(NORMAL);
    pg.beginShape();
    pg.texture(whichImage);
    pg.vertex(location.x, location.y, 0, 0);
    pg.vertex(location.x + scaledWidth, location.y, 1, 0);
    pg.vertex(location.x + scaledWidth, location.y + scaledHeight, 1, 1);
    pg.vertex(location.x, location.y + scaledHeight, 0, 1);
    pg.endShape();
  }
  
  void draw()
  {
    
    if (frameCount % 276 == 0) {
      whichImage = images[(int)random(0, images.length)];
    }
    
    if (displayMode == 0) {
      backgroundDots();
    }
    else {
      backgroundRandomLiquid();
    }
    
    pg.noStroke();
    
    float offset1 = sin((float)frameCount / 100);
    float offset2 = cos((float)frameCount / 200);
    float offset3 = sin((float)frameCount / 30);
    float offset4 = cos((float)frameCount / 70);
  
    if (true) {
      drawImage(new Vec2D(30 - offset1 * 10, 22 + offset4 * 5), 0.5 + main.beatDetect.beatPos("spectralFlux", 2) * 0.1);
      drawImage(new Vec2D(46 + offset2 * 4, 29 + offset3 * 3), 0.7 + main.beatDetect.beatPos("spectralFlux", 1) * 0.1);
      drawImage(new Vec2D(65 - offset4 * 2, 21 + offset2 * 2), 0.3 + main.beatDetect.beatPos("spectralFlux", 0) * 0.05);
    }
    
    // Mirror on the starboard side
    pg.loadPixels();
    color[] pixelData = pg.pixels;
    for (int y = 0; y < ledHeight; y++) {
      final int baseYData = y * ledWidth;
      for (int x = 0; x < halfWidth; x++) {
        color pixel = pixelData[baseYData + x];
        pixelData[baseYData + (ledWidth - x - 1)] = pixel;
      }
    }
    pg.updatePixels();

    if (false) {
      assert(font != null);
      pg.textFont(font);
      pg.textSize(16);
      pg.fill(saturation(backgroundColor) > 240 ? BLACK: WHITE);
      pg.textAlign(CENTER, CENTER);
      String text = "Foo Love";
      pg.text(text, 64, 39);
      pg.text(text, 150, 39);
    }
    
//    println("brightness: " + brightness(backgroundColor) + " hue: " + hue(backgroundColor) + " saturation:  " + saturation(backgroundColor));
    
    // Post drawing activities
    if (waveDistance >= 0) {
      waveDistance += 1.9;
    }
    
    if (waveDistance > halfWidth * 0.8 && settings.isBeat(0)) {
      waveDistance = 0;
      center = new Vec2D(random(0.2, halfWidth * 0.6), random(0.2, height * 0.6));
    }
    
    if (frameCount % 300 == 0) {
      displayMode = (int)random(0, 3);
    }
  }

  float dThing = 50;
  
  void backgroundRandomLiquid() {
    
    pg.loadPixels();

    int fCount = frameCount % 9000;
    
    float power = noise(random(halfWidth), random(height), fCount);
    power = cos(power) * TWO_PI;
    float v = cos(noise(random(halfWidth), random(height), fCount*.01))*TWO_PI;
    float scale = 1.0;
    dThing = constrain(dThing, 80.0 * scale, 100.0 * scale);
    
    float preZoom = 5;
    float scale2 = 0.75 * 4;
    for(int y = 0; y < height; y++)
    {
      for(int x = 0; x < halfWidth; x++)
      {
        float base = noise(cos(x * 0.008 * scale2), sin(y * 0.007 * scale2), fCount *.04)*TWO_PI;
        float total = 0.0;
        for(float i = dThing; i >= 1; i = 1/2.0)
        {
          float n = noise(x, y, fCount*.04) * .1;
          total += noise(cos(x/dThing), sin(y/dThing), fCount * 0.005) * (dThing * 0.0001);
          power = base * n;
        }
        float turbulence = 128.0 * total / dThing;
        float zoom = preZoom * total/(dThing*dThing);
        float offset = base + (power * (turbulence*zoom) / 256.0);
        float intensity = abs(sin(offset)) * 128.0;
        if (displayMode == 1) {
          pg.pixels[y * width + x] = color(255 - norm(intensity, 0.0, 10),
                                           255 - norm(intensity ,0.0, 10)*128,
                                           norm(intensity, 0.0, 1.5));
        }
        else {
          pg.pixels[y * width + x] = color(norm(intensity, 0.0, 1.5),
                                           255 - norm(intensity ,0.0, 10)*128,
                                           255 - norm(intensity, 0.0, 10));
        }
      }
    }
    pg.updatePixels();

    if (displayMode == 1) {
      backgroundColor = color(249, 13, 27);
    }
    else {
      backgroundColor = color(39, 35, 248);
    }
    
  }
  
  color backgroundColor = BLACK;

  void backgroundDots() {
    if (settings.isBeat(1)) {
      backgroundColor = getColor(0);
    }
    
    pg.fill(backgroundColor);
    pg.rect(0, 0, halfWidth, height);
    
    final int kNumRows = 10;
    final int kNumCols = 15;
    
    pg.fill(WHITE);
    pg.noStroke();
    pg.ellipseMode(CENTER);
    
    for (int i = 0; i < kNumCols; i++) {
      for (int j = 0; j < kNumRows; j++) {
        Vec2D location = new Vec2D(1.0 * halfWidth / kNumCols * i, 1.0 * height / kNumRows * j);
        float distance = location.distanceTo(center);
        float radius = 2;
        float diff = distance - waveDistance;
        
        radius += map(abs(diff), 0, 30, 3, 0);
        if (radius > 0) {
          pg.ellipse(location.x, location.y, radius, radius);
        }
      }
    }
  }
  
}
