/* OpenProcessing Tweak of *@*http://www.openprocessing.org/sketch/21319*@* */
/* !do not delete the line above, required for linking your tweak if you re-upload */
//Yuriy Flyud. Feb.19.2011.Tunnel Applet

import java.awt.geom.Area;
import java.awt.geom.PathIterator;
import java.awt.geom.GeneralPath;

class Tunnel extends Drawer {

  final float NOISE_FALLOFF = 0.5f;
  final int NUMBER_OF_CIRCLES = 4;
  final int NUMBER_OF_GLOWS = 21;
  final float TRANSPARENCY_COEF = 1.5f;
  final int COLOR_AMPLITUDE = 10;
  final boolean ORIGINAL_COLORS = true;

  float factor;
  int NUMBER_OF_LAYERS;
  int DEPTH;

  Tunnel(Pixels p, Settings s) {
    super(p, s, P3D);
  }

  String getName() { return "Tunnel"; }

  LayerCollection lCol = new LayerCollection(NUMBER_OF_CIRCLES);
  GlowCollection glowCol = new GlowCollection(NUMBER_OF_GLOWS);
  
  int colorIndex = (int)random(1000);
  
  public PImage im;
  
  void setup() {
    pg.strokeWeight(1);
    im = loadImage("light.png");
    pg.smooth();
    factor = width / 600.0;
    NUMBER_OF_LAYERS = int(59 * factor) + 7;
    DEPTH = int (900 * factor) + 100;
  }
  
  void draw() {
    pg.noFill();
    pg.strokeWeight(2);
    noiseDetail(1, NOISE_FALLOFF);
    if (ORIGINAL_COLORS) {
      colorMode(HSB, NUMBER_OF_LAYERS, 1, 1, NUMBER_OF_LAYERS);
      pg.colorMode(HSB, NUMBER_OF_LAYERS, 1, 1, NUMBER_OF_LAYERS);
    }
    else {
      colorMode(RGB,255);
      pg.colorMode(RGB,255);
    }

    lCol.nextStep();
    performCamera();
    //draw Light Glows
    if (lCol.list.size() > NUMBER_OF_LAYERS) {
      pg.hint(DISABLE_DEPTH_TEST);
      glowCol.nextStep(lCol);
      glowCol.drawIt(lCol);
      pg.hint(ENABLE_DEPTH_TEST);
    }
    
    drawTunnel();
    pg.perspective();

    //make delay effect
    pg.camera();
    pg.fill(0, 20 * NUMBER_OF_LAYERS / 65.0);
    pg.rect(0, 0, width, height);
    //"Clean" lCol of layers
    if (lCol.list.size() > NUMBER_OF_LAYERS)
      lCol.list.remove(0);
    colorIndex += 1;
  }
  
  private void performCamera()
  {
    CircleLayer layer0 = lCol.list.get(0);
    CircleLayer layer5 = lCol.list.size() <= 5 ? layer0 : lCol.list.get(5);
    
    
    pg.camera(layer0.getCenter().x, layer0.getCenter().y,
           0, layer5.getCenter().x, layer5.getCenter().y,
           -DEPTH / 2.0, 0, 1, 0);
  }
  
  public void drawTunnel() {
    int enumerator = 0;
    for (CircleLayer layer : lCol.list) {
      enumerator++;
      for (List<PVector> l : layer.getLayer()) {
        pg.stroke(getColorForLayer(NUMBER_OF_LAYERS - enumerator, 1));
        pg.beginShape();
        for (PVector p : l) {
          pg.vertex(p.x, p.y, p.z);
          p.z += DEPTH / NUMBER_OF_LAYERS;
        }
        pg.endShape(CLOSE);
      }
    }
  }
  
  public int getColorForLayer(int layerNumber, int transCoef)
  {
    if (ORIGINAL_COLORS) {
        return color(-(layerNumber - colorIndex) / COLOR_AMPLITUDE % NUMBER_OF_LAYERS, 1, 1,layerNumber / TRANSPARENCY_COEF*transCoef);
    }
    else {
      float layerRange = (getNumColors()/1.0) / NUMBER_OF_LAYERS + 1;
      layerRange = 2;
      color result = getColor(round((layerRange + transCoef) * layerNumber) % getNumColors());
      float alpha;
      alpha = 50 * transCoef;
      assert(alpha >= 0 && alpha <= 255.0) : "invalid alpha: " + alpha + " layerNumber: " + layerNumber;
      result = replaceAlpha(result, alpha);
      return result;
    }
  }
  
  //Just paints Light Glows flying along the tunnel
  public class GlowCollection {
    public List<Glow> list;
    
    public GlowCollection(int numGlows) {
      this.list = new ArrayList<Glow>();
      for (int i = 0; i < numGlows; i++)
        list.add(new Glow((int)random(2), 10, 225));
    }
    
    public void nextStep(LayerCollection col) {
      for (Glow r : list)
        r.update(col);
    }
    
    public void drawIt( LayerCollection col) {
      for (Glow r : list)
        r.drawIt(col);
    }
  }
  
  class Glow {
    int curLayerNum;
    int curCircle;
    
    int speed;
    PVector dev;
    int maxSpeed;
    
    public Glow(int ccurCircle, int cmaxSpeed, int rad) {
      this.curLayerNum = 0;
      this.curCircle = ccurCircle;
      
      this.dev = new PVector();
      this.maxSpeed = cmaxSpeed;
      this.speed = (int)random(1,maxSpeed);
      
      dev.x = random(-rad,rad);
      dev.y = random(-rad,rad) * sin(map(dev.x, -(float) rad, (float) rad, -PI, 0));
    }
    
    public void update(LayerCollection col) {
      curLayerNum += speed;
      if (curLayerNum > col.list.size() - 1) {
        curLayerNum = 0;
        this.speed = (int)random(1,maxSpeed);
      }
    }
    
    public void drawIt(LayerCollection col) {
      pg.tint(getColorForLayer(NUMBER_OF_LAYERS - curLayerNum, 5));
      pg.pushMatrix();
      
      CircleLayer c = col.list.get(curLayerNum);
      pg.translate(c.getOneCenter(curCircle).x + dev.x,
                c.getOneCenter(curCircle).y + dev.y,
                c.getLayer().get(0).get(0).z);
      
      pg.image(im, 0, 0);
      pg.popMatrix();
    }
  }
  
  public class LayerCollection {
    public final int CIRCLE_DETAIL = 5;
    public final float CIRCLE_OVAL = 0.7f;
    public final float ROT_DEV = PI / 100;
    
    public List<CircleLayer> list = new ArrayList<CircleLayer>();
    
    private  CircleShape[] circles;
    private float[] coords = new float[6];
    private float rotAngle=0;
    
    public LayerCollection(int numCircles) {
      circles = new CircleShape[numCircles];
      for (int i = 0; i < circles.length; i++)
        circles[i] = new CircleShape();
    }
    
    public void nextStep() {
      final float BORDERS_WIDTH = width;
      final float BORDERS_HEIGHT = height;
      
      refreshCircles(BORDERS_WIDTH, BORDERS_WIDTH);
      list.add(getShape());
    }
    
    public void refreshCircles(float w, float h) {
      for (int i = 0; i < circles.length; i++) {
        circles[i].generateCenter(w, h);
      }
      rotAngle += ROT_DEV;
    }
    
    public CircleLayer getShape() {
      final int CIRCLE_RADIUS = int(220 * factor);

      CircleLayer layer = new CircleLayer(circles.length);
      Area area = circles[0].getShape(CIRCLE_RADIUS, CIRCLE_DETAIL, CIRCLE_OVAL, rotAngle);
      layer.initCenter(0, circles[0].center);
      
      for (int i = 1; i < circles.length; i++) {
        area.add(circles[i].getShape(CIRCLE_RADIUS, CIRCLE_DETAIL, CIRCLE_OVAL, rotAngle));
        layer.initCenter(i, circles[i].center);
      }
      
      for (PathIterator i = area.getPathIterator(null); !i.isDone(); i.next()) {
        int type = i.currentSegment(coords);
        switch (type) {
          case PathIterator.SEG_MOVETO:
            layer.addShape();
            layer.addPoint(new PVector(coords[0], coords[1], -DEPTH));
            break;
          case PathIterator.SEG_LINETO:
            layer.addPoint(new PVector(coords[0], coords[1], -DEPTH));
            break;
          case PathIterator.SEG_CLOSE:
            break;
          default:
            // throw new Exception("error in constructing new Shape");
        }
      }
      return layer;
    }
  }
  
  //Represents circle as instance of GeneralPath, and moves it (noise()) in 2D(XY) space
  public class CircleShape {
    
    private PVector center;
    private GeneralPath shape = new GeneralPath();
    
    
    //Noise parameters
    PVector offset;
    PVector increment;
    
    public CircleShape() {
      center = new PVector(0, 0, 0);
      offset = new PVector(0, 0);
      increment = new PVector(random(0.15,0.25),random(0.15,0.25));
    }
    
    public void generateCenter(float w, float h) {
      offset.x += increment.x;
      offset.y += increment.y;
      
      center.x = w / 2 - noise(offset.x * 0.05f) * w;
      center.y = h / 2 - noise(offset.y * 0.05f) * h;
    }
    
    public Area getShape(float rad, float det, float oval, float rot) {
      shape.reset();
      shape.moveTo(center.x + rad * cos(rot), center.y + rad * sin(rot) * 0.3f);
      for (int i = 1; i < det; i++) {
        shape.lineTo(
                     center.x + rad * cos(rot + TWO_PI / det * i),
                     center.y + rad * sin(rot + TWO_PI / det * i) * oval);
      }
      shape.closePath();
      return new Area(shape);
    }
  }
  
  //One layer of a tunnel. Keeps a list of Areas(represented as list of points), and centers of each CirclesShape.
  public class CircleLayer {
    private List<List<PVector>> list = new ArrayList<List<PVector>>();
    private PVector[] centers;
    
    public CircleLayer(int numCenters) {
      centers = new PVector[numCenters];
    }
    
    public void initCenter(int num, PVector center) {
      this.centers[num] = new PVector(center.x, center.y, center.z);
    }
    
    public PVector getCenter() {
      return centers[0];
    }
    
    public PVector getOneCenter(int num) {
      return centers[num];
    }
    
    public void addShape() {
      list.add(new ArrayList<PVector>());
    }
    
    public List<List<PVector>> getLayer() {
      return list;
    }
    
    public void addPoint(PVector p) {
      list.get(list.size() - 1).add(p);
    }
    
    public void finalize() throws Throwable {
      list.clear();
      super.finalize();
    }
  };
  
  
}