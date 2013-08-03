/* OpenProcessing Tweak of *@*http://www.openprocessing.org/sketch/9037*@* */
/* !do not delete the line above, required for linking your tweak if you re-upload */

class EyeMotion extends Drawer {
  
  
  float mx;
  float my;
  float easing;
  int radius = 10;
  int edge = 200;
  int inner = edge + radius;
  int i = 10;
  float SCALE = 0.14;
  float trippy;
  float lastmx, lastmy;
  int MINX, MINY;
  int MAXX, MAXY;
  int lastLookChange;
  boolean readyToBlink;
  float dX, dY;
  int translateX;
  int translateY;
  
  // Colors
  float factorBlue = 1.5;
  
  final color kIrisColor = color(3, 43, 62*factorBlue);
  final color kPupilColor = color(4, 22, 35*factorBlue);
  
  final color kEyeFillColor = color(8*5, 74*1.5, 119*factorBlue);
  final color kBackgroundColor = color(14, 37, 62);
  final color kLidColor = color(20, 95, 141*factorBlue);
  final color kLidColorDark = color(18, 53, 89*factorBlue);
  final color kLidColor3 = color(11, 41, 66*factorBlue);
  final color kGlare1 = color(144, 187, 204, 95*factorBlue);
  final color kGlare2 = color(144, 187, 204, 50*factorBlue);
  
  EyeMotion(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.MirrorSides);
  }

  String getName() { return "Eye Motion"; }
  String getCustom1Label() { return "Trippy";}
  String getCustom2Label() { return "Height";}
  
  void setup() {
    touchX = (int)(0.585 * width);
    touchY = (int)(0.366 * height);
    settings.setParam(settings.keyCustom1, 0.1);
    settings.setParam(settings.keyFlash, 0.0);
    setEyeLimits(0);
    mx = MINX;
    my = MINY;
  }
  
  void setEyeLimits(float scale) {
    
    float percent = 1.0 - scale * 0.2;
    
    MINX = (int)(276 * percent);
    MINY = (int)(210 * percent);
    
    percent = 1.0 + scale * 0.2;
    
    MAXX = (int)(340 * percent);
    MAXY = (int)(235 * percent);
  }
  
  void draw() {
    
    translateX = 60;
    translateY = (int)map(settings.getParam(settings.keyCustom2), 0.0, 1.0, 80, -80);

    trippy = settings.getParam(settings.keyCustom1);
    setEyeLimits(trippy);
    
    float speed = settings.getParam(settings.keySpeed);

    float MAX_SECONDS_TO_FOCUS = 3.0;
    float MIN_SECONDS_TO_FOCUS = 0.05;
    float totalSecondsForMovement = secondsForSpeed(MIN_SECONDS_TO_FOCUS, MAX_SECONDS_TO_FOCUS, 1.0-speed);
    easing = 1.0/(totalSecondsForMovement * FRAME_RATE);
    
    pg.scale(SCALE);
    pg.noStroke();
    pg.smooth();
    pg.translate(translateX, translateY);
    pg.background(kBackgroundColor);
    
    handleTouches(touchX, touchY);
    if (mx != lastmx || my != lastmy) {
      lastLookChange = millis();
      lastmx = mx;
      lastmy = my;
    }

    float MAX_SECONDS_BETWEEN_MOVES = 10.0;
    float MIN_SECONDS_BETWEEN_MOVES = 0.01;
    float timeBeforeMoveEyes = secondsForSpeed(MIN_SECONDS_BETWEEN_MOVES, MAX_SECONDS_BETWEEN_MOVES, 1.0 - (trippy * speed));
    
    int timeSinceLastMove = millis() - lastLookChange;
    if ((timeSinceLastMove/1000 > timeBeforeMoveEyes) && (trippy > 0) && settings.isBeat(2)) {
      lastLookChange = millis();
      touchX = (int)round(random(0, width));
      touchY = (int)round(random(0, height));
//      println("time before move:" + timeBeforeMoveEyes + " timeSinceLastMove:" + timeSinceLastMove);
    }
    
    // Eye fill
    pg.fill(kEyeFillColor);
    pg.ellipse(313, 220, 285, 187);
    
    // Iris
    color targetColor = getColor(getNumColors()/2);
    color irisColor = fadeColor(kIrisColor, targetColor, 0.2, 0.8);
    pg.fill(irisColor);
    
    pg.ellipse(mx, my - 10, 192, 179);
    
    // Pupil
    targetColor = getColor(0);
    color pupilColor = fadeColor(kPupilColor, targetColor, 0.6, 0.95);
    pg.fill(pupilColor);
    pg.ellipse(mx, my - 10, 130, 130);
    
    pg.fill(kBackgroundColor); // Color
    pg.beginShape();
    pg.vertex(93, 258);
    pg.vertex(75, 116);
    pg.vertex(206, 24);
    pg.vertex(572, 37);
    pg.vertex(592, 216);
    pg.vertex(457, 219);
    pg.vertex(434, 174);
    pg.vertex(403, 141);
    pg.vertex(221, 139);
    pg.vertex(165, 214);
    pg.endShape(CLOSE);
    
    pg.fill(kBackgroundColor); // Color
    pg.beginShape();
    pg.vertex(164, 202);
    pg.vertex(173, 240);
    pg.vertex(189, 279);
    pg.vertex(227, 317);
    pg.vertex(287, 327);
    pg.vertex(379, 320);
    pg.vertex(447, 248);
    pg.vertex(463, 218);
    pg.vertex(504, 200);
    pg.vertex(583, 200);
    pg.vertex(573, 359);
    pg.vertex(418, 453);
    pg.vertex(141, 436);
    pg.vertex(52, 267);
    pg.vertex(104, 214);
    pg.endShape(CLOSE);
    
    // Eyelid top light blue
    pg.fill(kLidColor); // Color
    pg.beginShape();
    pg.vertex(163, 228);
    pg.bezierVertex(163, 157, 224, 98, 308, 98);
    pg.bezierVertex(392, 98, 457, 145, 460, 219);
    pg.bezierVertex(427, 183, 378, 122, 308, 122);
    pg.bezierVertex(238, 122, 162, 178, 163, 228);
    pg.endShape();
    
    // Bottom lid light blue
    pg.fill(kLidColor);
    pg.beginShape();
    pg.vertex(166, 226);
    pg.bezierVertex(185, 276, 248, 323, 318, 323);
    pg.bezierVertex(388, 323, 464, 263, 464, 216);
    pg.bezierVertex(464, 287, 402, 346, 318, 346);
    pg.bezierVertex(234, 346, 169, 300, 166, 226);
    pg.endShape();
    
    float secondsBetweenBlinks = 15.0;
    if (!readyToBlink) {
      readyToBlink = (random(0.0, 1.0) < (1.0/(FRAME_RATE * secondsBetweenBlinks)));
    }
    if (settings.isBeat(1) && readyToBlink){
      readyToBlink = false;
      
      pg.fill(kLidColorDark);
      pg.beginShape();
      pg.vertex(174, 235);
      pg.bezierVertex(180, 209, 177, 207, 202, 179);
      pg.bezierVertex(226, 152, 272, 126, 313, 126);
      pg.bezierVertex(392, 126, 453, 151, 458, 238);
      pg.bezierVertex(414, 233, 372, 216, 307, 211);
      pg.bezierVertex(242, 205, 176, 235, 174, 235);
      pg.endShape(CLOSE);
      
    }
    
    // Top eye lid dark blue
    pg.fill(kLidColorDark); // Color
    pg.beginShape();
    pg.vertex(177, 250);
    pg.bezierVertex(163, 238, 159, 225, 159, 210);
    pg.bezierVertex(159, 166, 226, 119, 313, 119);
    pg.bezierVertex(401, 119, 464, 166, 464, 210);
    pg.bezierVertex(464, 225, 460, 238, 446, 250);
    pg.bezierVertex(447, 246, 447, 242, 447, 237);
    pg.bezierVertex(447, 186, 386, 144, 311, 144);
    pg.bezierVertex(237, 144, 176, 186, 176, 237);
    pg.endShape();
    
    // Lower lid
    pg.fill(kLidColorDark); // Color
    pg.beginShape();
    pg.vertex(169, 240);
    pg.bezierVertex(198, 265, 251, 282, 311, 282);
    pg.bezierVertex(372, 282, 424, 265, 454, 240);
    pg.bezierVertex(444, 290, 384, 329, 311, 329);
    pg.bezierVertex(239, 329, 179, 290, 169, 240);
    pg.endShape();
    
    pg.fill(kLidColor3); // Color
    pg. beginShape();
    pg.vertex(169, 243);
    pg.bezierVertex(198, 269, 251, 307, 311, 307);
    pg.bezierVertex(372, 307, 424, 269, 453, 243);
    pg.bezierVertex(444, 294, 384, 333, 311, 333);
    pg.bezierVertex(239, 333, 179, 294, 169, 243);
    pg.endShape();
    
    // Glare 1
    pg.fill(kGlare1); // Color
    pg.ellipse(266, 175, 33, 30);
    
    // Glare 2
    pg.fill(kGlare1); // Color
    pg.ellipse(253, 205, 13, 21);

    pg.fill(kGlare2); // Color
    pg.ellipse(253, 205, 13, 21);
    
//    pg.stroke(0, 255, 0, 255);
//    pg.noFill();
//    pg.rect(MINX, MINY, MAXX - MINX, MAXY-MINY);
//    
//    pg.rect(dX, dY, 10, 10);
  
//    pg.fill(255, 0, 255, 255);
//    pg.rect(mx, my, 50, 50);
//  
//    println("dX:" + dX + " dY:" + dY);
  }
 
  float secondsForSpeed(float min_seconds, float max_seconds, float speed) {
    float time = speed * sqrt(max_seconds - min_seconds);
    time *= time;
    time += min_seconds;
    return time;
  }
  
  void handleTouches(float touchX, float touchY) {
    float targetX = map(touchX, 0, width, (MINX+translateX)*SCALE, (MAXX+translateX)*SCALE);
    float targetY = map(touchY, 0, height, (MINY+translateY)*SCALE, (MAXY+translateY)*SCALE);

    targetX = targetX/SCALE - translateX;
    targetY = targetY/SCALE - translateY;

    dX = targetX;
    dY = targetY;
    
    if (abs(targetX - mx) > 0.1) {
      mx += (targetX - mx) * easing;
    }
    if (abs(targetY - my) > 0.1) {
      my += (targetY - my) * easing;
    }    
  }

  
  color fadeColor(color baseColor, color targetColor, float baseTrippy, float fullTrippy) {
    if (trippy < baseTrippy) {
      return baseColor;
    }
    
    if (trippy >= fullTrippy) {
      return targetColor;
    }
    
    float alpha = map(trippy, baseTrippy, fullTrippy, 255, 0);
    color theColor = replaceAlpha(baseColor, alpha);
    theColor = blendColor(targetColor, theColor, BLEND);
    return theColor;
  }

  
  
}
