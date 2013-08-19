
class BeatBeat extends Drawer
{
  BeatBeat(Pixels p, Settings s) {
    super(p, s, P2D, DrawType.TwoSides);
  }

  Vec2D center;
  float waveDistance;
  PImage images[];
  PImage whichImage;
  int displayMode;
  PFont font;
  int halfWidth;
  boolean showWords;
  float wordAlpha;
  int lastImageSwitchTime;
  int lastWordSwitchTime;
  String words[][];
  
//	"KaushanScript-Regular-16.vlw",
//  "LobsterTwo-BoldItalic-16.vlw", // Wedding
//  "CaviarDreams-BoldItalic-16.vlw",
//	"RomanSD-16.vlw",
//  "Days-16.vlw", // Very legible
//  "SpinCycleOT-16.vlw", // Hippy Space Love
//  "DrawveticaMini-16.vlw",
//  "TamilMN-Bold-16.vlw", // legible
//  "KannadaSangamMN-Bold-16.vlw",
//  "TrajanPro3-Bold-16.vlw", // Classy
  
  String currentFont;
  String displayText = "";
  
  String getName()
  {
    return "Beat Beat";
  }

  String getCustom1Label() { return "Word Duration";}
  String getCustom2Label() { return "Theme";}

  void setup()
  {
    halfWidth = width / 2;
    
    images = new PImage[] {
      loadImageWithScale("Heart.png", 1.0),
      loadImageWithScale("Star.png", 0.6),
      loadImageWithScale("Carrot.png", 0.4),
      loadImageWithScale("Crossbones.png", 0.6)
    };
    
    whichImage = images[0];
    
    center = new Vec2D(halfWidth / 2.0, height / 2.0);
    waveDistance = 0;
    
    lastImageSwitchTime = lastWordSwitchTime = millis();
    String weddingWords[] = loadStrings("words.wedding.txt");
    fixupStrings(weddingWords);
    String positiveWords[] = loadStrings("words.positve.txt");
    fixupStrings(positiveWords);
    String negativeWords[] = loadStrings("words.negative.txt");
    fixupStrings(negativeWords);
    
    String[] combinedWords = new String[positiveWords.length + negativeWords.length];
    System.arraycopy(positiveWords, 0, combinedWords, 0, positiveWords.length);
    System.arraycopy(negativeWords, 0, combinedWords, positiveWords.length, negativeWords.length);
    
    words = new String[][] {
      weddingWords,
      positiveWords,
      combinedWords,
    };
  }

  void fixupStrings(String[] strings) {
    for (int i = 0; i < strings.length; i++) {
      strings[i] = strings[i].replaceAll("\\\\n","\n");
    }
  }
  
  PImage loadImageWithScale(String name, float scale) {
    PImage image = loadImage(name);
    image.resize((int)(image.width * scale), 0);
    return image;
  }
  
  void drawImage(Vec2D location, float scale)
  {
    if (wordAlpha > 0.75) {
      return; // Don't show images when word is almost visible
    }
    
    pg.tint(255, map(wordAlpha, 0, 0.75, 255, 10));
    
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
  
    drawImage(new Vec2D(30 - offset1 * 10, 22 + offset4 * 5), 0.5 + main.beatDetect.beatPos("spectralFlux", 2) * 0.1);
    drawImage(new Vec2D(46 + offset2 * 4, 29 + offset3 * 3), 0.7 + main.beatDetect.beatPos("spectralFlux", 1) * 0.1);
    drawImage(new Vec2D(65 - offset4 * 2, 21 + offset2 * 2), 0.3 + main.beatDetect.beatPos("spectralFlux", 0) * 0.05);
    
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

    if (wordAlpha > 0) {
      assert(font != null);
      pg.textFont(font);
      pg.textSize(font.getSize());
      pg.fill(saturation(backgroundColor) > 240 ? BLACK: WHITE, wordAlpha * 255);
      pg.textAlign(CENTER, CENTER);
      pg.textLeading((font.ascent() + font.descent()) * font.getSize() + 1);
      float xOffset = (offset2 * 3);
      float yOffset = (offset1 * -3);
      pg.text(displayText, 64 + xOffset, 37 + yOffset);
      pg.text(displayText, 150 + xOffset, 37 + yOffset);
    }
    
    // Post drawing activities
    pickWordsOrImages();
    pickBackground();
  }

  void pickWordsOrImages() {
    final float kWordToImageSpeed = 0.04;
    if (showWords && wordAlpha < 1.0) {
      wordAlpha = min(wordAlpha + kWordToImageSpeed, 1.0);
    }
    else if (!showWords && wordAlpha > 0) {
      wordAlpha = max(wordAlpha - kWordToImageSpeed, 0);
    }
    
    float wordDurationPercent = settings.getParam(settings.keyCustom1);
//    wordDurationPercent = 1.0; // TEMP
    int timeWord = int(20 * 1000 * wordDurationPercent);
    int timeImages = int(25 * 1000 * (1.0 - wordDurationPercent));
//    timeWord = 1500; // TEMP

    boolean switchImage = false;
    boolean switchWord = false;
    if (wordDurationPercent < 0.1) {
      showWords = false;
    }
    else if (wordDurationPercent > 0.9) {
      showWords = true;
    }
    else {
      showWords = (millis() % (timeWord + timeImages)) < timeWord;
    }

    if (!showWords) {
      if (wordAlpha == 1.0) {
        switchImage = true;
      }
      else if (wordAlpha == 0.0){
        float imageDuration = timeImages / 2;
        if (imageDuration < 8 * 1000) {
          imageDuration = timeImages;
        }
        if (millis() - lastImageSwitchTime > imageDuration) {
          switchImage = true;
        }
      }
    }
    else {
      if (wordAlpha == 0.0) {
        switchWord = true;
        println("a");
      }
      else if (wordAlpha == 1.0) {
        if (millis() - lastWordSwitchTime > timeWord) {
          switchWord = true;
        }
      }
    }
    
    if (switchImage) {
      whichImage = images[(int)random(0, images.length)];
      lastImageSwitchTime = millis();
    }
    else if (switchWord) {
      int theme = int(settings.getParam(settings.keyCustom2) * (words.length - 1));
      
      String fontSelected = "SpinCycleOT-16.vlw";
      if (theme == 0) {
        fontSelected = "LobsterTwo-BoldItalic-16.vlw";
      }
      if (currentFont != fontSelected) {
        currentFont = fontSelected;
        font = loadFont(currentFont);
      }
      
      String whichWords[] = words[theme];
      displayText = whichWords[(int)random(0, whichWords.length)];
      lastWordSwitchTime = millis();
    }
  }
  
  void pickBackground() {
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
